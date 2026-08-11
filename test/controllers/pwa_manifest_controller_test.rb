require "test_helper"

class PwaManifestControllerTest < ActionDispatch::IntegrationTest
  test "GET /manifest returns 200 with JSON content" do
    get pwa_manifest_url(format: :json)
    assert_response :success
    assert_equal "application/json", response.content_type.split(";").first
  end

  test "manifest JSON contains Daybreak name" do
    get pwa_manifest_url(format: :json)
    body = JSON.parse(response.body)
    assert_equal "Daybreak", body["name"]
    assert_equal "Daybreak", body["short_name"]
  end

  test "manifest JSON has correct theme and background colors" do
    get pwa_manifest_url(format: :json)
    body = JSON.parse(response.body)
    assert_equal "#D4916E", body["theme_color"]
    assert_equal "#F3EBE2", body["background_color"]
  end

  test "manifest JSON references icon-192 and icon-512" do
    get pwa_manifest_url(format: :json)
    body = JSON.parse(response.body)
    src_paths = body["icons"].map { |i| i["src"] }
    assert_includes src_paths, "/icon-192.png"
    assert_includes src_paths, "/icon-512.png"
  end

  test "manifest JSON display is standalone" do
    get pwa_manifest_url(format: :json)
    body = JSON.parse(response.body)
    assert_equal "standalone", body["display"]
  end
end
