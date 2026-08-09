require "test_helper"

class AgentEndpointTest < ActiveSupport::TestCase
  test "is valid with a callback_url" do
    assert AgentEndpoint.new(callback_url: "https://example.com/callback").valid?
  end

  test "is invalid without callback_url" do
    endpoint = AgentEndpoint.new(callback_url: nil)
    assert_not endpoint.valid?
    assert_includes endpoint.errors[:callback_url], "can't be blank"
  end

  test "current returns the last record by insertion order" do
    AgentEndpoint.delete_all
    AgentEndpoint.create!(callback_url: "https://first.example.com/cb")
    second = AgentEndpoint.create!(callback_url: "https://second.example.com/cb")
    assert_equal second, AgentEndpoint.current
  end

  test "current returns nil when table is empty" do
    AgentEndpoint.delete_all
    assert_nil AgentEndpoint.current
  end
end
