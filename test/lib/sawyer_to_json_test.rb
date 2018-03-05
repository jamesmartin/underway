require_relative "../test_helper"

class SawyerToJsonTest < SequelTestCase

  def setup
  end

  def test_can_convert_an_empty_array
    assert_equal "[]", Underway::SawyerToJson.convert([])
  end

  def test_can_convert_an_array_with_nested_hash
    obj = [ { foo: "bar" } ]
    expected = "[{\"foo\":\"bar\"}]"
    actual = Underway::SawyerToJson.convert(obj)

    assert_equal expected, actual
  end

  def test_can_convert_a_nested_sawyer_object
    agent = Sawyer::Agent.new("/irrelevant")
    data = "{\"foo\":\"bar\"}"
    resource = Sawyer::Resource.new(agent, agent.decode_body(data))
    obj = [ resource ]
    expected = "[{\"foo\":\"bar\"}]"
    actual = Underway::SawyerToJson.convert(obj)

    assert_equal expected, actual
  end
end
