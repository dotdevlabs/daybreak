require "test_helper"

class Api::CatalogControllerTest < ActionDispatch::IntegrationTest
  setup do
    @account = Account.create!
    @token = @account.api_tokens.create!.token
  end

  def auth_headers
    { "Authorization" => "Bearer #{@token}" }
  end

  test "GET /api/catalog returns 200 with JSON:API content type" do
    get api_catalog_index_url, headers: auth_headers
    assert_response :ok
    assert_equal "application/vnd.api+json", response.media_type
  end

  test "GET /api/catalog returns all 6 widget types" do
    get api_catalog_index_url, headers: auth_headers
    data = response.parsed_body["data"]
    assert_equal 6, data.size
    ids = data.map { |r| r["id"] }
    assert_equal WidgetMessage::WIDGET_TYPES.sort, ids.sort
  end

  test "GET /api/catalog returns widget_types resources with correct structure" do
    get api_catalog_index_url, headers: auth_headers
    data = response.parsed_body["data"]
    data.each do |resource|
      assert_equal "widget_types", resource["type"]
      assert_kind_of String, resource["id"]
      assert resource["attributes"].key?("name"), "missing name attribute"
      assert resource["attributes"].key?("description"), "missing description attribute"
      assert resource["attributes"].key?("schema"), "missing schema attribute"
      assert_equal %w[description name schema], resource["attributes"].keys.sort
    end
  end

  test "GET /api/catalog returns weather widget with correct name" do
    get api_catalog_index_url, headers: auth_headers
    data = response.parsed_body["data"]
    weather = data.find { |r| r["id"] == "weather" }
    assert_not_nil weather
    assert_equal "Weather Widget", weather.dig("attributes", "name")
  end

  test "GET /api/catalog without token returns 401" do
    get api_catalog_index_url
    assert_response :unauthorized
    assert_equal "application/vnd.api+json", response.media_type
    assert_equal "Unauthorized", response.parsed_body.dig("errors", 0, "detail")
  end
end
