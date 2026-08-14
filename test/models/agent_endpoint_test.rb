require "test_helper"

class AgentEndpointTest < ActiveSupport::TestCase
  setup do
    @account = Account.create!
  end

  test "is valid with a callback_url and account" do
    assert AgentEndpoint.new(account: @account, callback_url: "https://example.com/callback").valid?
  end

  test "is invalid without callback_url" do
    endpoint = AgentEndpoint.new(account: @account, callback_url: nil)
    assert_not endpoint.valid?
    assert_includes endpoint.errors[:callback_url], "can't be blank"
  end

  test "is invalid without account" do
    endpoint = AgentEndpoint.new(callback_url: "https://example.com/callback")
    assert_not endpoint.valid?
    assert_includes endpoint.errors[:account], "must exist"
  end

  test "belongs to account" do
    endpoint = @account.agent_endpoints.create!(callback_url: "https://example.com/cb")
    assert_equal @account, endpoint.account
  end

  test "account.agent_endpoints.last returns the last endpoint for that account" do
    AgentEndpoint.delete_all
    @account.agent_endpoints.create!(callback_url: "https://first.example.com/cb")
    second = @account.agent_endpoints.create!(callback_url: "https://second.example.com/cb")
    assert_equal second, @account.agent_endpoints.last
  end
end
