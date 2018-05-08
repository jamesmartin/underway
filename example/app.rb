require "sinatra"
require "underway"
require "underway/sinatra"

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
    <a href="/info">Underway App Information</a>
  EOS
end

post "/user_authz" do
  debug_route(request)
end

get "/setup" do
  debug_route(request)
end

post "/hook" do
  debug_route(request)
end
