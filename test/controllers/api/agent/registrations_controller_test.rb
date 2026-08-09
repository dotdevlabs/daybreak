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
    { "Authorization" => "Bearer #{VALID_TOKEN}", "Content-Type" => "application/json" }
  end

  test "POST /api/agent/registrations without token returns 401" do
    post api_agent_registrations_url,
         params: { callback_url: "https://example.com/cb" }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end

  test "POST /api/agent/registrations with valid token creates AgentEndpoint and returns ok" do
    assert_difference "AgentEndpoint.count", 1 do
      post api_agent_registrations_url,
           params: { callback_url: "https://example.com/cb" }.to_json,
           headers: auth_headers
    end
    assert_response :success
    assert_equal "ok", response.parsed_body["status"]
    assert_equal "https://example.com/cb", response.parsed_body["callback_url"]
  end

  test "POST /api/agent/registrations without callback_url returns 422" do
    post api_agent_registrations_url,
         params: { callback_url: "" }.to_json,
         headers: auth_headers
    assert_response :unprocessable_entity
    assert response.parsed_body["errors"].any?
  end

  test "multiple POSTs create multiple records and current returns the last" do
    post api_agent_registrations_url,
         params: { callback_url: "https://first.example.com/cb" }.to_json,
         headers: auth_headers
    post api_agent_registrations_url,
         params: { callback_url: "https://second.example.com/cb" }.to_json,
         headers: auth_headers
    assert_equal 2, AgentEndpoint.count
    assert_equal "https://second.example.com/cb", AgentEndpoint.current.callback_url
  end
end
