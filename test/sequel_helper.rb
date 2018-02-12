require_relative "../lib/database"

# http://sequel.jeremyevans.net/rdoc/files/doc/testing_rdoc.html

class SequelTestCase < Minitest::Test
  def run(*args, &block)
    DB.configure("sqlite:/") # Always assume an in-memory database for now

    Sequel::Model.db.transaction(
      rollback: :always,
      auto_savepoint: true
    ){super}
  end
end
