require "sinatra"
require "openssl"
require "jwt"
require "net/http"
require "octokit"
require_relative "lib/settings"
require_relative "lib/token_cache"
require_relative "lib/sawyer_to_json"

configure do
  # Reads configuration values for the GitHub App
  Settings.instance.config.each do |key, value|
    set key.to_sym, value
  end
end

# The Integration ID
# From "About -> ID" at github.com/settings/apps/<app-name>
def app_issuer
  @app_issuer ||= settings.app_id
end

# Integration webhook secret (for validating that webhooks come from GitHub)
def webhook_secret
  @webhook_secret ||= settings.webhook_secret
end

# Are you testing against .localhost or .com, or something else?
def github_tld
  @github_tld ||= settings.github_tld
end

# Private Key for the App, generated based on the PEM file
def private_key
  Settings.instance.private_key
end

def generate_jwt
  payload = {
    # Issued at time:
    iat: Time.now.to_i,
    # JWT expiration time (10 minute maximum)
    exp: Time.now.to_i + (10 * 60),
    # GitHub Apps identifier
    iss: app_issuer
  }

  jwt = JWT.encode(payload, Settings.instance.private_key, "RS256")
end

def token_cache
  @token_cache ||= TokenCache.new(Settings.instance.db)
end

def debug_route(request)
  log(request.inspect)
end

def verbose_logging?
  !!Settings.instance.verbose_logging
end

def log(message)
  if verbose_logging?
    logger.info(message)
  end
end

def debug_octokit!
  stack = Faraday::RackBuilder.new do |builder|
    builder.use Octokit::Middleware::FollowRedirects
    builder.use Octokit::Response::RaiseError
    builder.use Octokit::Response::FeedParser
    builder.response :logger
    builder.adapter Faraday.default_adapter
  end
  Octokit.middleware = stack
end

# Returns a Sawyer::Resource or PORO
def gh_api(route, headers: {}, method: :get)
  debug_octokit! if verbose_logging?

  Octokit.api_endpoint = Settings.instance.config["github_api_host"]

  if !headers[:authorization] && !headers["Authorization"]
    Octokit.bearer_token = generate_jwt
  end

  final_headers = {
    accept: "application/vnd.github.machine-man-preview+json",
    headers: headers
  }

  begin
    case method
    when :post then Octokit.post(route, final_headers)
    else Octokit.get(route, final_headers)
    end
  rescue Octokit::Error => e
    { error: e.to_s }
  end
end

# Returns a valid auth token for the installation
def installation_token(id:)
  if token = token_cache.lookup_installation_auth_token(id: id)
    log("token cache: hit")
    return token
  else
    log("token cache: miss")
    res = gh_api(
      "/app/installations/#{params["installation_id"]}/access_tokens",
      method: :post
    )

    token = res.token
    expires_at = res.expires_at.to_s
    token_cache.store_installation_auth_token(id: id, token: token, expires_at: expires_at)
    token
  end
end

get "/" do
  erb <<~EOS
    <h2>Interesting routes:</h2>
    <pre>
      <li>/             => This homepage</li>
      <li>/user_authz   => User authorization callback URL</li>
      <li>/setup        => (Optional) setup URL</li>
      <li>/hook         => Receives incoming installation and modification Webhooks</li>
      <li>/jwt          => Generates a JWT for authentication as the App</li>
    </pre>
    <h2>Private PEM file</h2>
    <pre>
      #{Settings.instance.private_key_filename}
    </pre>
  EOS
end

post "/user_authz" do
  debug_route(request)
end

get "/setup" do
  debug_route(request)
  erb "Setting up installation: #{params["installation_id"]}"
end

post "/hook" do
  debug_route(request)
end

get "/jwt" do
  content_type :json
  generate_jwt
end

get "/info/app" do
  content_type :json
  SawyerToJson.convert(gh_api("/app"))
end

get "/info/app/installations" do
  content_type :json
  SawyerToJson.convert(gh_api("/app/installations"))
end

get "/info/app/installations/:installation_id" do
  content_type :json
  SawyerToJson.convert(gh_api("/app/installations/#{params["installation_id"]}"))
end

get "/info/app/installation/:installation_id/access_token" do
  content_type :json
  SawyerToJson.convert(
    gh_api(
      "/app/installations/#{params["installation_id"]}/access_tokens",
      method: :post
    )
  )
end

get "/info/app/installation/:installation_id/repositories" do
  content_type :json
  SawyerToJson.convert(
    gh_api(
      "/installation/repositories",
      headers: { authorization: "token #{installation_token(id: params[:installation_id])}" }
    )
 )
end
