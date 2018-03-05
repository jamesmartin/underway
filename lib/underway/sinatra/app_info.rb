require "sinatra/base"

# Include this module in your Sinatra app to get access to these helpful
# routes:
#
# /info/app => information about this App
# /info/app/installations => a list of all installations of this App
# /info/app/installations/:id => information about the installation
# /info/app/installations/:id/repositories => the repositories this
# installation has access to
# /info/app/installations/:id/access_token => a valid access token for the
# installation

module Sinatra
  module Underway
    module AppInfo
      def self.registered(app)
        app.get "/info/app" do
          content_type :json
          ::Underway::SawyerToJson.convert(gh_api("/app"))
        end

        app.get "/info/app/installations" do
          content_type :json
          ::Underway::SawyerToJson.convert(gh_api("/app/installations"))
        end

        app.get "/info/app/installations/:installation_id" do
          content_type :json
          ::Underway::SawyerToJson.convert(gh_api("/app/installations/#{params["installation_id"]}"))
        end

        app.get "/info/app/installations/:installation_id/access_token" do
          content_type :json
          ::Underway::SawyerToJson.convert(
            gh_api(
              "/app/installations/#{params["installation_id"]}/access_tokens",
              method: :post
            )
          )
        end

        app.get "/info/app/installations/:installation_id/repositories" do
          content_type :json
          ::Underway::SawyerToJson.convert(
            gh_api(
              "/installation/repositories",
              headers: { authorization: "token #{::Underway::Api.installation_token(id: params[:installation_id])}" }
            )
          )
        end
      end
    end
  end
  register Underway::AppInfo
end
