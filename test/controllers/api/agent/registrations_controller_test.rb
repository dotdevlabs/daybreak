require "test_helper"

class Api::Agent::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  VALID_TOKEN = "test_daybreak_token".freeze

  setup do
    ENV["DAYBREAK_API_TOKEN"] = VALID_TOKEN
    AgentEndpoint.delete_all
  end

  teardown do
    ENV.delete("DAYBREAK_API_TOKEN")
  end

  def auth_headers
    { "Authorization" => "Bearer #{VALID_TOKEN}", "Content-Type" => "application/vnd.api+json" }
  end

  def post_registration(callback_url:, token: VALID_TOKEN)
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

  test "POST /api/agent/registrations without callback_url returns 422" do
    post_registration(callback_url: "")
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
    assert response.parsed_body.dig("errors", 0, "detail").present?
  end

  test "multiple POSTs create multiple records and current returns the last" do
    post_registration(callback_url: "https://first.example.com/cb")
    post_registration(callback_url: "https://second.example.com/cb")
    assert_equal 2, AgentEndpoint.count
    assert_equal "https://second.example.com/cb", AgentEndpoint.current.callback_url
  end
end
