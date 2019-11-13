require_relative "../test_helper"

class SettingsTest < Minitest::Test
  def test_configure
    Underway::Settings.reset!

    root = Pathname.new(__FILE__).dirname.join("../fixtures")
    Underway::Settings.configure do |config|
      # FIXME seems weird this calls dirname on the argument?
      config.app_root = root.join("app.rb")
      config.config_filename = "config.json"
    end


    assert_equal "1", Underway::Settings.configuration.app_issuer
    assert_equal root.join("./path-to.private-key.pem").expand_path, Underway::Settings.configuration.private_key_filename.expand_path
    assert_equal false, Underway::Settings.configuration.verbose_logging
    assert_equal "http://github.localhost/login/oauth/authorize?client_id=2", Underway::Settings.configuration.oauth_authorize_url
  end
end
