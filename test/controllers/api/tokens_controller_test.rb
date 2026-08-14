require "test_helper"

class Api::TokensControllerTest < ActionDispatch::IntegrationTest
  test "POST /api/tokens without session returns 401" do
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :unauthorized
    assert_equal "application/vnd.api+json", response.media_type
    errors = response.parsed_body["errors"]
    assert_kind_of Array, errors
    assert errors.all? { |e| e.key?("detail") }
  end

  test "POST /api/tokens with valid browser session returns 201 with token" do
    sign_in_as(users(:alice))
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :created
    assert_equal "application/vnd.api+json", response.media_type
    data = response.parsed_body["data"]
    assert_equal "api_tokens", data["type"]
    assert_kind_of String, data["id"]
    token = data.dig("attributes", "token")
    assert token.present?, "token must not be blank"
  end

  test "token returned from browser path belongs to signed-in user account" do
    sign_in_as(users(:alice))
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :created
    token_string = response.parsed_body.dig("data", "attributes", "token")
    api_token = ApiToken.find_by!(token: token_string)
    assert_equal users(:alice).account_id, api_token.account_id
  end

  test "returned token authenticates subsequent requests to protected endpoints" do
    sign_in_as(users(:alice))
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :created
    token = response.parsed_body.dig("data", "attributes", "token")

    get api_catalog_index_url, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :ok
  end

  test "two POSTs by same signed-in user create distinct tokens on same account" do
    sign_in_as(users(:alice))
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    token1 = response.parsed_body.dig("data", "attributes", "token")
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    token2 = response.parsed_body.dig("data", "attributes", "token")
    assert_not_equal token1, token2
    t1 = ApiToken.find_by!(token: token1)
    t2 = ApiToken.find_by!(token: token2)
    assert_equal t1.account_id, t2.account_id
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
