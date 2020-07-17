require_relative "../test_helper"
require "pry"

class SettingsTest < Minitest::Test

  def setup
    Underway::Settings.reset_configuration!
  end

  def test_can_set_settings_explicitly
    pem = File.read(File.join(File.dirname(__FILE__), "../fixtures/test.pem"))

    Underway::Settings.configure do |config|
      config.app_id = "some-app-id"
      config.client_id = "some-client-id"
      config.client_secret = "some-client-secret"
      config.database_url = "/some/db/url"
      config.github_api_host = "https://test.example.com"
      config.webhook_secret = "some-webhook-secret"
      config.private_key = pem
    end

    config = Underway::Settings.configuration
    assert_equal "some-app-id", config.app_id
    assert_equal "some-client-id", config.client_id
    assert_equal "some-client-secret", config.client_secret
    assert_equal "/some/db/url", config.database_url
    assert_equal "https://test.example.com", config.github_api_host
    assert_equal OpenSSL::PKey::RSA.new(pem).to_pem, config.private_key.to_pem
    assert_equal "some-webhook-secret", config.webhook_secret
  end

  def test_can_set_settings_from_config_file
    fixture_pem_path = File.absolute_path(File.join(File.dirname(__FILE__), "../fixtures/test.pem"))

    fixture_config_file_path = File.join(File.dirname(__FILE__), "../fixtures/fixture-cfg.json")
    fixture_config = JSON.parse(File.read(fixture_config_file_path))
    fixture_config["private_key_filename"] = fixture_pem_path

    # Write the config to a tempfile to update the private_key_filename so it
    # can be read from disk by the settings code.
    test_config = Tempfile.open("config.json") do |f|
      f.write(fixture_config.to_json)
      f
    end

    Underway::Settings.configure do |config|
      config.config_filename = test_config.path
    end

    config = Underway::Settings.configuration

    assert_equal "fixture-app-id", config.app_id
    assert_equal "fixture-client-id", config.client_id
    assert_equal "fixture-client-secret", config.client_secret
    assert_equal "/fixture/db/url", config.database_url
    assert_equal "https://fixture.example.com", config.github_api_host
    fixture_pem = OpenSSL::PKey::RSA.new(File.read(fixture_pem_path))
    assert_equal fixture_pem.to_pem, config.private_key.to_pem
    assert_equal "fixture-webhook-secret", config.webhook_secret
  end
end
