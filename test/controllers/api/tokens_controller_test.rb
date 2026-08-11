require "test_helper"

class Api::TokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    ApiToken.delete_all
  end

  test "POST /api/tokens without auth returns 201 with a token string" do
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :created
    assert_equal "application/vnd.api+json", response.media_type
    data = response.parsed_body["data"]
    assert_equal "api_tokens", data["type"]
    assert_kind_of String, data["id"]
    token = data.dig("attributes", "token")
    assert_kind_of String, token
    assert token.present?, "token must not be blank"
  end

  test "returned token authenticates subsequent requests to protected endpoints" do
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :created
    token = response.parsed_body.dig("data", "attributes", "token")

    get api_catalog_index_url, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :ok
  end

  test "POST /api/tokens creates a record in the database" do
    assert_difference "ApiToken.count", 1 do
      post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    end
    assert_response :created
  end

  test "each POST /api/tokens mints a distinct token" do
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    token1 = response.parsed_body.dig("data", "attributes", "token")
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    token2 = response.parsed_body.dig("data", "attributes", "token")
    assert_not_equal token1, token2
  end

  test "request without token returns 401 with JSON:API errors body on protected endpoint" do
    get api_catalog_index_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :unauthorized
    assert_equal "application/vnd.api+json", response.media_type
    errors = response.parsed_body["errors"]
    assert_kind_of Array, errors
    assert errors.all? { |e| e.key?("detail") }
  end
end
