require_relative "../test_helper"

class SettingsTest < Minitest::Test
  def setup
    Underway::Settings.reset!
    @root = Pathname.new(__FILE__).dirname.join("../fixtures")
  end

  def test_configure
    Underway::Settings.configure do |config|
      # FIXME seems weird this calls dirname on the argument?
      config.app_root = @root.join("app.rb")
      config.config_filename = "config.json"
    end

    assert_equal "1", Underway::Settings.configuration.app_issuer

    private_pem = @root.join("./test.2019-11-13.private-key.pem")
    private_key = OpenSSL::PKey::RSA.new(private_pem.read.to_s)
    assert_equal private_pem.expand_path, Underway::Settings.configuration.private_key_filename.expand_path
    assert_equal private_pem.read, Underway::Settings.configuration.private_pem
    assert_kind_of OpenSSL::PKey::RSA, Underway::Settings.configuration.private_key
    # FIXME how to check this is actually loaded?
    # assert_equal private_key, Underway::Settings.configuration.private_key

    assert_equal false, Underway::Settings.configuration.verbose_logging
    assert_equal "http://github.localhost/login/oauth/authorize?client_id=2", Underway::Settings.configuration.oauth_authorize_url
  end

  def test_configure_without_config_file
    Underway::Settings.configure do |config|
      config.app_root = @root.join("app.rb")
      config.private_key_filename = "./test.2019-11-13.private-key.pem"

      config.webhook_secret = "trololol"
      config.app_issuer = "4"
      config.client_id = "5"
      config.database_url = "sqlite://github-app.db"
      config.verbose_logging = true
      config.github_api_host = "http://api.github.localhost"
    end


    assert_equal "4", Underway::Settings.configuration.app_issuer

    private_pem = @root.join("./test.2019-11-13.private-key.pem")
    assert_equal private_pem.expand_path, Underway::Settings.configuration.private_key_filename.expand_path
    assert_equal private_pem.read, Underway::Settings.configuration.private_pem

    private_key = OpenSSL::PKey::RSA.new(private_pem.read.to_s)
    assert_kind_of OpenSSL::PKey::RSA, Underway::Settings.configuration.private_key
    # FIXME how to check this is actually loaded?
    # assert_equal private_key, Underway::Settings.configuration.private_key

    assert_equal true, Underway::Settings.configuration.verbose_logging
    assert_equal "http://github.localhost/login/oauth/authorize?client_id=5", Underway::Settings.configuration.oauth_authorize_url

  end

  def test_configure_without_config_file_or_pem_file
    private_pem = "-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAxntmMdM+CmhJbzbqLTGIs9z9CT7hVCm3CtePVwhgkeHTS52s
ukBiRXyu5Fe/LEgwfYfPUadhfK99Whs8NMGcOpY8j/A8sZBFLwdmKuxMDpSEITTp
IVU72xezyMG10Feh7QVY73G73kv66Vfh0hTBA38DFKBL+kh5HJ3n0N4BT0sASIZX
CCZWQsWjgq79fJhsXlK0qKg0hd/4iowRTG1CF8VEKfyJ9iYHiv+0K8l7p4D1JF0R
eS0jscrGFHso7YeqpgmaqPH83e1AIsr2WopUoST7+M/QVBqmCttXGWvo68vLTapB
sypsuNQkaiNWLGa3+Epr/ln18pGau2YnNPVrawIDAQABAoIBAQCqn1XgqymAJNpL
4rc4loZfqC9VjVqC0UFq7pdoR+lMPwc2z5q2mbZg6agm30+WL5CPuPn9xZfGac2m
chc1euJkctYpHmnucokmvoOTjoJrXjyfly552x2TYDLK98rmCQ9IA/rKC8lmdYaC
pWuY/wJVkRAC4TGvPDHw6cVoBhC2Kc1agsmiCnSVpzj9Aj3PJIcVNuYzyP6QNb5G
AmgXP2LT1/bpF3SyTD1+8toXTRs6CMstJjM9qa89WJB/e0Et8Lw7EbS/jB9Kuyqo
IkYyiAHLzhA36ZWqNjBY6vbBrjykDw4R/alKGlivoBrLkO/QC+p+QV3QllQD/FoD
KX8HY3NhAoGBAOx+eFgGKjhcEL+EIeSH0eAMra0EE+GS/8cshuH9IHMTWhbBR88F
kLi/BzRNbK1w+NZH7eHQUBKpjPSkUX6VhNJNLK/99iTGWSPEXaiJLxllMjVxwyto
fj1nnUfaUu6jmNtsGVkC9JRBJnXD6T+ksqbW2jq00mTYNxR5bAFWgP6jAoGBANba
T/4YXkFcsnFpZv8xyCWGksGr1dQqZJpVuEXG4eNQdFNYvJeiTdKO7yAB9G1pV7iv
VVjiKMGkz32OPsPGk3+DRJNFnw1AyA+Fh0anHUk7BaIMY7WPuQrheu63szDIDOc0
1zU6g2PStZrkvER01oIMXSJ5V0U5y+NifLbkLZSZAoGBAIqWLmW+7xzp7rKcdtQa
N4YpR9l86z2kTBlm4YArOsnUzFVLXI5Xv5BT+Z/Pw2D8NAY2TpOm5FWbYEu4wzz/
1775lLdphsXUKkaIey4Zfi1OnRaunOWiLWBEiOmjajgITLpA5bXAwpzidOxMKzKt
jDey7l26uxR3lAd+hClgjOUrAoGACFpsicCAyaHE/kvOyVUyJuNYiVcY9SrAxo9W
nr/gwGm8XBEzI+IXjHwqJ+BrlGVoF7IZa18/nme9+W+yWQI7cdW0sNUgHe/K12+l
lsWgidxVl7tLlR+FXjruAKH7wYXFmqefRl6EBTmH/gGuoCq6vEumw1RcZECfALQv
jRzJ+OECgYAWR4+7uvACb3JoDdo+tmOXc8uLvFkyl1vZr+jO32QbeJBuCbjVKpPs
xAxKBANxM0cd83rDiiIUVr7tyJLa0apRXfNJ20oC8I2tMu+b8KOuJvfe/w9xw0g9
aolQi45t8IC9IJHmfz0wKX6vhs4PracmNbyzDu5Kt+rvCPg/uykhXQ==
-----END RSA PRIVATE KEY-----"

    Underway::Settings.configure do |config|
      config.webhook_secret = "trololol"
      config.app_issuer = "4"
      config.client_id = "5"
      config.private_pem = private_pem
      config.database_url = "sqlite://github-app.db"
      config.verbose_logging = true
      config.github_api_host = "http://api.github.localhost"
    end


    assert_equal "4", Underway::Settings.configuration.app_issuer

    assert_equal private_pem, Underway::Settings.configuration.private_pem
    assert_kind_of OpenSSL::PKey::RSA, Underway::Settings.configuration.private_key
    # FIXME how to check this is actually loaded?
    # assert_equal private_key, Underway::Settings.configuration.private_key

    assert_equal true, Underway::Settings.configuration.verbose_logging
    assert_equal "http://github.localhost/login/oauth/authorize?client_id=5", Underway::Settings.configuration.oauth_authorize_url

  end
end
