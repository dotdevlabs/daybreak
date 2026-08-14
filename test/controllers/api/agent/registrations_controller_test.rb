require "test_helper"

class Api::Agent::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!
    @token = @account.api_tokens.create!.token
    @account.agent_endpoints.delete_all
  end

  def auth_headers
    { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/vnd.api+json" }
  end

  def post_registration(callback_url:, token: @token)
    post api_agent_registrations_url,
         params: { data: { type: "agent_registrations", attributes: { callback_url: callback_url } } }.to_json,
         headers: { "Authorization" => "Bearer #{token}", "Content-Type" => "application/vnd.api+json" }
  end

  test "POST /api/agent/registrations without token returns 401" do
    post api_agent_registrations_url,
         params: { data: { type: "agent_registrations", attributes: { callback_url: "https://example.com/cb" } } }.to_json,
         headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :unauthorized
    assert_equal "application/vnd.api+json", response.media_type
    assert_equal "Unauthorized", response.parsed_body.dig("errors", 0, "detail")
  end

  test "POST /api/agent/registrations with valid token creates AgentEndpoint and returns 201" do
    assert_difference "AgentEndpoint.count", 1 do
      post_registration(callback_url: "https://example.com/cb")
    end
    assert_response :created
    assert_equal "application/vnd.api+json", response.media_type
    assert_equal "agent_registrations", response.parsed_body.dig("data", "type")
    assert_equal "https://example.com/cb", response.parsed_body.dig("data", "attributes", "callback_url")
  end

  test "POST /api/agent/registrations endpoint is scoped to the authenticated account" do
    post_registration(callback_url: "https://example.com/cb")
    assert_response :created
    endpoint = AgentEndpoint.last
    assert_equal @account.id, endpoint.account_id
  end

  test "POST /api/agent/registrations without callback_url returns 422" do
    post_registration(callback_url: "")
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
    assert response.parsed_body.dig("errors", 0, "detail").present?
  end

  test "multiple POSTs create multiple records under the same account" do
    post_registration(callback_url: "https://first.example.com/cb")
    post_registration(callback_url: "https://second.example.com/cb")
    endpoints = @account.agent_endpoints.reload
    assert_equal 2, endpoints.count
    assert_equal "https://second.example.com/cb", endpoints.last.callback_url
  end
end
