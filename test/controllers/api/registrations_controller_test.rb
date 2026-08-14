require "test_helper"

class Api::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "POST /api/registrations with no auth returns 201 with token" do
    post api_registrations_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :created
    assert_equal "application/vnd.api+json", response.media_type
    data = response.parsed_body["data"]
    assert_equal "api_tokens", data["type"]
    assert_kind_of String, data["id"]
    token = data.dig("attributes", "token")
    assert token.present?, "token must not be blank"
    assert_match %r{\A/api/tokens/\d+\z}, data.dig("links", "self")
  end

  test "returned token is valid bearer for protected endpoints" do
    post api_registrations_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :created
    token = response.parsed_body.dig("data", "attributes", "token")

    get api_catalog_index_url, headers: { "Authorization" => "Bearer #{token}" }
    assert_response :ok
  end

  test "each POST creates a distinct account" do
    post api_registrations_url, headers: { "Content-Type" => "application/vnd.api+json" }
    token1 = response.parsed_body.dig("data", "attributes", "token")
    post api_registrations_url, headers: { "Content-Type" => "application/vnd.api+json" }
    token2 = response.parsed_body.dig("data", "attributes", "token")
    assert_not_equal token1, token2
    t1 = ApiToken.find_by!(token: token1)
    t2 = ApiToken.find_by!(token: token2)
    assert_not_equal t1.account_id, t2.account_id
  end

  test "token resolves to an account (not ownerless)" do
    post api_registrations_url, headers: { "Content-Type" => "application/vnd.api+json" }
    token_string = response.parsed_body.dig("data", "attributes", "token")
    api_token = ApiToken.find_by!(token: token_string)
    assert api_token.account.present?, "token must resolve to an account"
  end

  test "empty body POST to /api/tokens returns 401 (cannot mint ownerless token)" do
    post api_tokens_url, headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :unauthorized
  end
end
