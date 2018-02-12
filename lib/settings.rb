require "singleton"
require "pathname"
require "json"
require_relative "./database"

class Settings
  include Singleton
  attr_reader :config

  def initialize
    @app_root = Pathname.new(__FILE__).dirname.dirname
    @config =  JSON.parse(
      @app_root.join("config.json").read
    )
  end

  def db
    @db ||= begin
      DB.configure(config["database_url"])
      DB.instance.database
    end
  end

  # The Integration ID
  # From "About -> ID" at github.com/settings/apps/<app-name>
  def app_issuer
    @app_issuer ||= config['app_id']
  end

  # Integration webhook secret (for validating that webhooks come from GitHub)
  def webhook_secret
    @webhook_secret ||= config['webhook_secret']
  end

  # PEM file for request signing (PKCS#1 RSAPrivateKey format)
  # (Download from github.com/settings/apps/<app-name> "Private key")
  def private_pem
    @private_pem ||= File.read(@app_root.join(config['private_key_filename']))
  end

  # Private Key for the App, generated based on the PEM file
  def private_key
    @private_key ||= OpenSSL::PKey::RSA.new(private_pem)
  end

end
