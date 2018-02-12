class TokenCache
  attr_accessor :db

  def initialize(database)
    @db = database
  end

  def lookup_installation_auth_token(id:)
    results = db[:cached_tokens].where(installation_id: id)
      .where{expires_at >= Time.now.utc}
      .reverse(:expires_at)
    if results.any?
      results.first[:token]
    end
  end

  def store_installation_auth_token(id:, token:, expires_at:)
    db[:cached_tokens].insert(installation_id: id, token: token, expires_at: expires_at)
  end
end
