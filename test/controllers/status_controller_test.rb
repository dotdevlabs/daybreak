require "test_helper"

class StatusControllerTest < ActionDispatch::IntegrationTest
  test "GET /status returns 200" do
    get "/status"
    assert_response :ok
  end

  test "GET /status returns application/vnd.api+json content type" do
    get "/status"
    assert_equal "application/vnd.api+json", response.media_type
  end

  test "GET /status returns JSON:API envelope with type=status and id=current" do
    get "/status"
    data = response.parsed_body["data"]
    assert_equal "status", data["type"]
    assert_equal "current", data["id"]
  end

  test "GET /status attributes contain exactly version, sha, and db_version" do
    get "/status"
    data = response.parsed_body["data"]
    assert_equal %w[db_version sha version], data["attributes"].keys.sort
  end

  test "GET /status db_version is the current applied migration version as a string" do
    get "/status"
    data = response.parsed_body["data"]
    expected = ApplicationRecord.connection.select_value("SELECT MAX(version) FROM schema_migrations")
    assert_equal expected.to_s, data["attributes"]["db_version"]
  end

  test "GET /status returns null version and sha when ENV vars not set" do
    ENV.delete("APP_VERSION")
    ENV.delete("APP_SHA")
    get "/status"
    data = response.parsed_body["data"]
    assert_nil data["attributes"]["version"]
    assert_nil data["attributes"]["sha"]
  end

  test "GET /status returns injected version and sha from ENV" do
    ENV["APP_VERSION"] = "1.2.3"
    ENV["APP_SHA"] = "abc1234"
    get "/status"
    data = response.parsed_body["data"]
    assert_equal "1.2.3", data["attributes"]["version"]
    assert_equal "abc1234", data["attributes"]["sha"]
  ensure
    ENV.delete("APP_VERSION")
    ENV.delete("APP_SHA")
  end

  test "GET /status requires no Authorization header" do
    get "/status"
    assert_response :ok
  end
end
