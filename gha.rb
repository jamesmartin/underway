require "sinatra"
require "openssl"
require "jwt"
require "net/http"
require_relative "lib/token_cache"
require_relative "database"

configure do
  # Reads configuration values for the GitHub App
  config = JSON.parse(File.read("config.json"))
  config.each do |key, value|
    set key.to_sym, value
  end

  DB.configure(config.fetch("database_url"))
end

def db
  DB.instance.database
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

# PEM file for request signing (PKCS#1 RSAPrivateKey format)
# (Download from github.com/settings/apps/<app-name> "Private key")
def private_pem
  @private_pem ||= File.read(settings.private_key_filename)
end

# Private Key for the App, generated based on the PEM file
def private_key
  @private_key ||= OpenSSL::PKey::RSA.new(private_pem)
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

  jwt = JWT.encode(payload, private_key, "RS256")
end

def token_cache
  @token_cache ||= TokenCache.new(db)
end

def debug_route(request)
  logger.info request.inspect
end

def gh_api(route, headers: {}, method: :get)
  uri = URI("http://api.github.#{github_tld}#{route}")

  req =
    case method
    when :post
      Net::HTTP::Post.new(uri)
    else
      Net::HTTP::Get.new(uri)
    end

  default_headers = {
    "Authorization" => "Bearer #{generate_jwt}",
    "Accept" => "application/vnd.github.machine-man-preview+json"
  }.merge(headers).each do |key, value|
    req[key] = value
  end

  http = Net::HTTP.new(uri.hostname, uri.port)
  http.set_debug_output(logger)
  http.request(req)
end

def handle_api_response(res)
  if res.is_a?(Net::HTTPSuccess)
    res.body
  else
    "#{res.code} => #{res.body}"
  end
end

# Returns a valid auth token for the installation
def installation_token(id:)
  if token = token_cache.lookup_installation_auth_token(id: id)
    return token
  else
    res = gh_api(
      "/app/installations/#{params["installation_id"]}/access_tokens",
      method: :post
    )

    if res.is_a?(Net::HTTPSuccess)
      payload = JSON.parse(res.body)
      token = payload.fetch("token")
      expires_at = payload.fetch("expires_at")
      token_cache.store_installation_auth_token(id: id, token: token, expires_at: expires_at)
      token
    else
      # Bail? ¯\(°_o)/¯
      logger.info "Couldn't get installation auth token: #{res.code} => #{res.body}"
    end
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
    <h2>Private PEM</h2>
    <pre>
      #{private_pem}
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
  handle_api_response(gh_api("/app"))
end

get "/info/app/installations" do
  content_type :json
  handle_api_response(gh_api("/app/installations"))
end

get "/info/app/installations/:installation_id" do
  content_type :json
  handle_api_response(gh_api("/app/installations/#{params["installation_id"]}"))
end

get "/info/app/installations/:installation_id/access_token" do
  content_type :json
  handle_api_response(
    gh_api(
      "/app/installations/#{params["installation_id"]}/access_tokens",
      method: :post
    )
  )
end

get "/info/installation/:installation_id/repositories" do
  content_type :json
  handle_api_response(
    gh_api(
      "/installation/repositories",
      headers: { "Authorization" => "token #{installation_token(id: params[:installation_id])}" }
    )
 )
end
