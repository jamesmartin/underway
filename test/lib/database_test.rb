require_relative "../test_helper"
require_relative "../../lib/database"

describe DB do
  it "can fail" do
    assert_equal 1, 2
  end
end
