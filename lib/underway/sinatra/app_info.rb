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
        app.get "/info" do
          erb <<~EOS
            <h1>Underway</h1>
            <h2>Interesting routes:</h2>
            <pre>
              <li>/info                                                                                           => This page</li>
              <li><a href="/info/app">/info/app</a>                                                               => Information about the configured GitHub App</li>
              <li><a href="/info/app/jwt">/info/app/jwt</a>                                                       => Generates a JWT for authentication as this App</li>
              <li><a href="/info/app/installations">/info/app/installations</a>                                   => A list of installations associated with this App</li>
              <li><a href="/info/app/installations/1">/info/app/installations/:id</a>                             => Information about the given installation of this App</li>
              <li><a href="/info/app/installations/1/access_token">/info/app/installations/:id/access_token</a>   => A valid access token for accessing the given installation as this App</li>
              <li><a href="/info/app/installations/1/repositories">/info/app/installations/:id/repositories</a>   => A list of all repositories accessible to the installation of this App</li>
            </pre>
            <h2>Private PEM file</h2>
            <pre>
              #{::Underway::Settings.configuration.private_key_filename}
            </pre>
          EOS
        end

        app.get "/info/app/jwt" do
          content_type :json
          ::Underway::Api.generate_jwt
        end

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
