require "addressable/uri"
require "pathname"
require "json"

module Underway
  class Settings
    class Configuration
      attr_reader :logger
      attr_writer :webhook_secret, :app_issuer, :client_id, :private_pem, :database_url, :verbose_logging, :github_api_host

      def initialize
        @logger = Underway::Logger.new
      end

      def config
        if @config_filename
          @config ||= JSON.parse(
            @app_root.join(@config_filename).read
          )
        else
          raise ArgumentError, "No config_filename given"
        end

      end

      # TODO: deprecate
      def raw
        @config
      end

      def app_root=(directory)
        @app_root = Pathname.new(directory).dirname
      end

      def config_filename=(filename)
        @config_filename = filename
      end

      def logger=(logger)
        @logger = logger
      end

      def database_url
        @database_url ||= config["database_url"]
      end

      def db
        @db ||=
          begin
            Underway::DB.configure(database_url)
            Underway::DB.instance.database
          end
      end

      # The Integration ID
      # From "About -> ID" at github.com/settings/apps/<app-name>
      def app_issuer
        @app_issuer ||= config["app_id"]
      end

      # Integration webhook secret (for validating that webhooks come from GitHub)
      def webhook_secret
        @webhook_secret ||= config["webhook_secret"]
      end

      def private_key_filename
        @app_root.join(config["private_key_filename"])
      end

      # PEM file for request signing (PKCS#1 RSAPrivateKey format)
      # (Download from github.com/settings/apps/<app-name> "Private key")
      def private_pem
        @private_pem ||= File.read(private_key_filename)
      end

      # Private Key for the App, generated based on the PEM file
      def private_key
        @private_key ||= OpenSSL::PKey::RSA.new(private_pem)
      end

      def verbose_logging
        return @verbose_logging if defined?(@verbose_logging)
        @verbose_logging = config["verbose_logging"]
      end

      def token_cache
        @token_cache ||= Underway::TokenCache.new(db)
      end

      def github_api_host
        @github_api_host ||= config["github_api_host"]
      end

      def client_id
        @client_id ||= config["client_id"]
      end

      def oauth_authorize_url
        uri = Addressable::URI.parse(github_api_host)

        "#{uri.scheme}://#{uri.domain}/login/oauth/authorize?client_id=#{client_id}"
      end

      def oauth_access_token_url(code)
        api_host = Addressable::URI.parse(github_api_host)
        template = Addressable::Template.new(
          "{scheme}://{host}/login/oauth/access_token{?code,client_id,client_secret}"
        )
        template.expand(
          "scheme" => api_host.scheme,
          "host" => api_host.domain,
          "code" => code,
          "client_id" => config["client_id"],
          "client_secret" => config["client_secret"]
        )
      end
    end


    class << self
      attr_accessor :configuration

      def reset!
        self.configuration = Configuration.new
      end


      def configure
        if block_given?
          yield configuration
        else
          raise ArgumentError.new("Please set configuration by passing a block")
        end
      end

      # TODO: remove me
      def config
        configuration
      end
    end

    reset!
  end
end
