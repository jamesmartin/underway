require_relative "../test_helper"
require_relative "../../lib/token_cache"

class TokenCacheTest < SequelTestCase

  def setup
    @cache = TokenCache.new(DB.instance.database)
  end

  def test_can_store_and_retrieve_a_token
    Timecop.freeze(DateTime.parse("2018-02-12T09:00:00+00:00")) do
      @cache.store_installation_auth_token(
        id: 1,
        token: "some-token",
        expires_at: "2018-02-12T10:00:00Z"
      )

      assert_equal "some-token", @cache.lookup_installation_auth_token(id: 1)
    end
  end

  def test_retrieves_the_newest_token
    Timecop.freeze(DateTime.parse("2018-02-12T09:00:00+00:00")) do
      @cache.store_installation_auth_token(
        id: 1,
        token: "first-token",
        expires_at: "2018-02-12T10:00:00Z"
      )

      @cache.store_installation_auth_token(
        id: 1,
        token: "second-token",
        expires_at: "2018-02-12T11:00:00Z"
      )

      assert_equal "second-token", @cache.lookup_installation_auth_token(id: 1)
    end
  end

  def test_returns_nil_when_looking_up_a_token_that_does_not_exist
    assert_nil @cache.lookup_installation_auth_token(id: "non-existent")
  end

  def test_returns_nil_for_tokens_that_have_expired
    Timecop.freeze(DateTime.parse("2018-02-12T09:00:00+00:00")) do
      @cache.store_installation_auth_token(
        id: 1,
        token: "some-token",
        expires_at: "2018-02-12T08:00:00Z"
      )

      assert_nil @cache.lookup_installation_auth_token(id: 1)
    end
  end

  def test_retrieves_a_token_when_the_expiry_is_equal_to_now
    Timecop.freeze(DateTime.parse("2018-02-12T09:00:00+00:00")) do
      @cache.store_installation_auth_token(
        id: 1,
        token: "some-token",
        expires_at: "2018-02-12T09:00:00Z"
      )

      assert_equal "some-token", @cache.lookup_installation_auth_token(id: 1)
    end
  end
end
