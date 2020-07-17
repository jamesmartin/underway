require_relative "../test_helper"

class SettingsTest < Minitest::Test

  def test_can_set_settings_explicitly
    pem = File.readlines(File.join(File.dirname(__FILE__), "../fixtures/test.pem"))

    Underway::Settings.configure do |config|
      config.app_id = "some-app-id"
      config.app_root = __FILE__
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
    assert_equal "some-webhook-secret", config.webhook_secret
    assert_equal pem, config.private_key
  end

end
