require "sinatra"
require "underway"

configure do
  Underway::Settings.configure do |config|
    config.app_root = __FILE__
    config.config_filename = "config.json"
  end
end

include Sinatra::Underway
include Sinatra::Underway::AppInfo

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
