require_relative "../test_helper"

class SettingsTest < Minitest::Test

  def test_can_set_settings_explicitly
    Underway::Settings.configure do |config|
      config.app_root = __FILE__
      config.database_url = "/some/db/url"
      config.webhook_secret = "some-webhook-secret"
      config.app_id = "some-app-id"
      config.client_id = "some-client-id"
      config.client_secret = "some-client-secret"
      config.private_key = File.readlines(File.join(File.dirname(__FILE__), "../fixtures/test.pem"))
    end

    config = Underway::Settings.configuration
    assert_equal "some-app-id", config.app_id
    assert_equal "some-webhook-secret", config.webhook_secret
  end

end
