require_relative "../test_helper"
require_relative "../../lib/token_cache"

class TokenCacheTest < SequelTestCase

  def setup
    @cache = TokenCache.new(DB.instance.database)
  end

  def test_can_store_and_retrieve_a_token
    Time.freeze do |now|
      @cache.store_installation_auth_token(
        id: "some-id",
        token: "some-token",
        expires_at: now + one_hour
      )

      assert_equal "some-token", @cache.lookup_installation_auth_token(id: "some-id")
    end
  end

  def test_retrieves_the_newest_token
    Time.freeze do |now|
      @cache.store_installation_auth_token(
        id: "some-id",
        token: "first-token",
        expires_at: now + one_hour
      )

      @cache.store_installation_auth_token(
        id: "some-id",
        token: "second-token",
        expires_at: now + two_hours
      )

      assert_equal "second-token", @cache.lookup_installation_auth_token(id: "some-id")
    end
  end

  def test_returns_nil_when_looking_up_a_token_that_does_not_exist
    assert_nil @cache.lookup_installation_auth_token(id: "non-existent")
  end

  def test_returns_nil_for_tokens_that_have_expired
    Time.freeze do |now|
      @cache.store_installation_auth_token(
        id: "some-id",
        token: "some-token",
        expires_at: now - one_minute
      )

      assert_nil @cache.lookup_installation_auth_token(id: "some-id")
    end
  end

  def test_retrieves_a_token_when_the_expiry_is_equal_to_now
    Time.freeze do |now|
      @cache.store_installation_auth_token(
        id: "some-id",
        token: "some-token",
        expires_at: now
      )

      assert_equal "some-token", @cache.lookup_installation_auth_token(id: "some-id")
    end
  end

  private

  def one_hour
    (1 * 60 * 60)
  end

  def two_hours
    (2 * 60 * 60)
  end

  def one_minute
    (1 * 60)
  end
end
