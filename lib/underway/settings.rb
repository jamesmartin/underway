require "pathname"
require "json"

module Underway
  class Settings
    class Configuration
      attr_reader :config, :logger

      def initialize
        @logger = Underway::Logger.new
      end

      def load!
        @config = JSON.parse(
          @app_root.join(@config_filename).read
        )
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

      def db
        @db ||=
          begin
            Underway::DB.configure(config["database_url"])
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
        @verbose ||= config["verbose_logging"]
      end

      def token_cache
        @token_cache ||= Underway::TokenCache.new(db)
      end
    end

    @configuration = Configuration.new

    class << self
      attr_reader :configuration

      def configure
        if block_given?
          yield configuration
        else
          raise ArgumentError.new("Please set configuration by passing a block")
        end

        configuration.load!
      end

      # TODO: remove me
      def config
        configuration
      end
    end

  end
end
