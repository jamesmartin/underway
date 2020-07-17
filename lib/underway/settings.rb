require "addressable/uri"
require "pathname"
require "json"

module Underway
  class Settings
    class Configuration
      SUPPORTED_SETTINGS = [
        :app_id,
        :client_id,
        :client_secret,
        :database_url,
        :github_api_host,
        :logger,
        :private_key,
        :private_key_filename,
        :verbose_logging,
        :webhook_secret,
      ].freeze

      attr_reader :app_id, :client_id, :client_secret, :database_url,
        :github_api_host, :private_key_filename, :logger, :verbose_logging, :webhook_secret, :config_filename


      def initialize
        @logger = Underway::Logger.new
      end

      def load!
        if config_filename
          config = JSON.parse(
            Pathname.new(config_filename).read
          )

          SUPPORTED_SETTINGS.map(&:to_s).each do |setting|
            if config[setting]
              send("#{setting}=", config[setting])
            end
          end
        end
      end

      def config_filename=(filename)
        @config_filename = filename
      end

      def logger=(logger)
        @logger = logger
      end

      def database_url=(url)
        @database_url = url
      end

      def db
        @db ||=
          begin
            Underway::DB.configure(database_url)
            Underway::DB.instance.database
          end
      end

      def github_api_host=(host)
        @github_api_host = host
      end

      # The Integration ID
      # From "About -> ID" at github.com/settings/apps/<app-name>
      def app_id=(id)
        @app_id = id
      end

      def client_id=(id)
        @client_id = id
      end

      def client_secret=(secret)
        @client_secret = secret
      end

      # Integration webhook secret (for validating that webhooks come from GitHub)
      def webhook_secret=(secret)
        @webhook_secret = secret
      end

      def private_key_filename=(filename)
        @private_key_filename = filename
      end

      # PEM file for request signing (PKCS#1 RSAPrivateKey format)
      # (Download from github.com/settings/apps/<app-name> "Private key")
      def private_pem
        @private_pem ||= Pathname.new(private_key_filename).read
      end

      # Private Key for the App.
      # Either the explicitly configured private_key value or the contents of
      # the configured private_key_filename.
      def private_key
        @private_key ||=
          unless private_key_filename.nil?
            OpenSSL::PKey::RSA.new(private_pem)
          end
      end

      def private_key=(key)
        @private_key = OpenSSL::PKey::RSA.new(key)
      end

      def verbose_logging=(verbose)
        @verbose_logging = !!verbose
      end

      def token_cache
        @token_cache ||= Underway::TokenCache.new(db)
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
          "client_id" => client_id,
          "client_secret" => client_secret
        )
      end
    end

    @configuration = Configuration.new

    class << self
      attr_reader :configuration

      def configure
        reset_configuration!

        if block_given?
          yield configuration
        else
          raise ArgumentError.new("Please set configuration by passing a block")
        end

        configuration.load!
      end

      def reset_configuration!
        @configuration = Configuration.new
      end
    end

  end
end
