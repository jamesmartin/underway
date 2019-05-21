require "jwt"
require "octokit"

module Underway
  class Api
    # Returns a Sawyer::Resource or PORO from the GitHub REST API
    def self.invoke(route, headers: {}, method: :get)
      debug_octokit! if verbose_logging?

      Octokit.api_endpoint = Underway::Settings.config.raw["github_api_host"]

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

    def self.client_for(installation_id: nil, access_token: nil)
      token = access_token
      if !installation_id.nil?
        token = installation_token(id: installation_id)
      end

      return if token.nil?

      client = Octokit::Client.new(
        api_endpoint: Underway::Settings.config.raw["github_api_host"],
        access_token: token
      )
    end

    def self.generate_jwt
      payload = {
        # Issued at time:
        iat: Time.now.to_i,
        # JWT expiration time (10 minute maximum)
        exp: Time.now.to_i + (10 * 60),
        # GitHub Apps identifier
        iss: Underway::Settings.config.app_issuer
      }

      JWT.encode(payload, Underway::Settings.config.private_key, "RS256")
    end

    # Returns a valid auth token for the installation
    def self.installation_token(id:)
      if token = Underway::Settings.config.token_cache.lookup_installation_auth_token(id: id)
        log("token cache: hit")
        return token
      else
        log("token cache: miss")
        res = invoke(
          "app/installations/#{id}/access_tokens",
          method: :post
        )

        if error = res[:error]
          raise ArgumentError.new(error)
        end

        token = res.token
        expires_at = res.expires_at.to_s
        Underway::Settings.config.token_cache.store_installation_auth_token(id: id, token: token, expires_at: expires_at)
        token
      end
    end

    def self.debug_octokit!
      stack = Faraday::RackBuilder.new do |builder|
        builder.use Octokit::Middleware::FollowRedirects
        builder.use Octokit::Response::RaiseError
        builder.use Octokit::Response::FeedParser
        builder.response :logger
        builder.adapter Faraday.default_adapter
      end
      Octokit.middleware = stack
    end

    def self.verbose_logging?
      !!Underway::Settings.config.verbose_logging
    end

    def self.log(message)
      if verbose_logging?
        ::Underway::Settings.config.logger.info(message)
      end
    end
  end
end
