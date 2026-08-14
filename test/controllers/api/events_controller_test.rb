require "test_helper"

class Api::EventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!
    @token = @account.api_tokens.create!.token
  end

  def auth_headers
    { "Authorization" => "Bearer #{@token}" }
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
    mock_registry = Object.new
    mock_registry.define_singleton_method(:register) { |_account_id, _sse| raise IOError }
    mock_registry.define_singleton_method(:unregister) { |_account_id, _sse| }
    with_push_registry(mock_registry) do
      get api_events_url, headers: auth_headers
    end
    assert_response :success
    assert_equal "text/event-stream", response.media_type
  end
end
