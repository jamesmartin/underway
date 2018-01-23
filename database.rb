require "sqlite3"
require "sequel"
require "singleton"

class DB
  include Singleton

  @@db = nil

  def self.configure(database_url)
    @@db = Sequel.connect(database_url)

    # TODO: extract to schema migration
    @@db.create_table?(:cached_tokens) do
      primary_key   :id
      Fixnum        :installation_id, null: false
      String        :token, null: false
      DateTime      :expires_at, null: false

      index [:installation_id, :expires_at]
    end
  end

  def database
    @@db
  end
end
