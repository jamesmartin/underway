require "sinatra"
require "openssl"
require "net/http"
require "underway"

configure do
  Underway::Settings.configure do |config|
    config.app_root = __FILE__
    config.config_filename = "config.json"
  end
end

def token_cache
  @token_cache ||= Underway::TokenCache.new(Underway::Settings.config.db)
end

def debug_route(request)
  log(request.inspect)
end

def verbose_logging?
  !!Underway::Settings.config.verbose_logging
end

def log(message)
  if verbose_logging?
    logger.info(message)
  end
end

# Returns a Sawyer::Resource or PORO
def gh_api(*args)
  Underway::Api.invoke(*args)
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
      #{Underway::Settings.config.private_key_filename}
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
  Underway::Api.generate_jwt
end

get "/info/app" do
  content_type :json
  Underway::SawyerToJson.convert(gh_api("/app"))
end

get "/info/app/installations" do
  content_type :json
  Underway::SawyerToJson.convert(gh_api("/app/installations"))
end

get "/info/app/installations/:installation_id" do
  content_type :json
  Underway::SawyerToJson.convert(gh_api("/app/installations/#{params["installation_id"]}"))
end

get "/info/app/installation/:installation_id/access_token" do
  content_type :json
  Underway::SawyerToJson.convert(
    gh_api(
      "/app/installations/#{params["installation_id"]}/access_tokens",
      method: :post
    )
  )
end

get "/info/app/installation/:installation_id/repositories" do
  content_type :json
  Underway::SawyerToJson.convert(
    gh_api(
      "/installation/repositories",
      headers: { authorization: "token #{installation_token(id: params[:installation_id])}" }
    )
  )
end
