require "test_helper"

class Api::EventsControllerTest < ActionDispatch::IntegrationTest
  VALID_TOKEN = "test_daybreak_token".freeze

  setup do
    ENV["DAYBREAK_API_TOKEN"] = VALID_TOKEN
  end

  teardown do
    ENV.delete("DAYBREAK_API_TOKEN")
  end

  def auth_headers
    { "Authorization" => "Bearer #{VALID_TOKEN}" }
  end

  test "GET /api/events without token returns 401" do
    get api_events_url
    assert_response :unauthorized
  end

  test "GET /api/events with invalid token returns 401" do
    get api_events_url, headers: { "Authorization" => "Bearer wrong_token" }
    assert_response :unauthorized
  end

  test "GET /api/events with valid token begins SSE stream" do
    # Replace the singleton with a mock that disconnects immediately.
    # Minitest 6 has no built-in stub, so we swap @_instance directly.
    mock_registry = Object.new
    mock_registry.define_singleton_method(:register) { |_| raise IOError }
    mock_registry.define_singleton_method(:unregister) { |_| }
    with_push_registry(mock_registry) do
      get api_events_url, headers: auth_headers
    end
    assert_response :success
    assert_equal "text/event-stream", response.media_type
  end
end
