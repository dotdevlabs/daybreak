require "test_helper"

class ImportmapTest < ActiveSupport::TestCase
  test "webauthn-json vendored file exists" do
    vendor_file = Rails.root.join("vendor/javascript/@github--webauthn-json.js")
    assert File.exist?(vendor_file),
      "vendor/javascript/@github--webauthn-json.js is missing — run: bin/importmap pin @github/webauthn-json --download"
  end

  test "webauthn-json vendored file exports create and get" do
    vendor_file = Rails.root.join("vendor/javascript/@github--webauthn-json.js")
    skip "vendor file missing — see previous test" unless File.exist?(vendor_file)
    content = File.read(vendor_file)
    assert_match(/\bcreate\b/, content, "webauthn-json must export a 'create' function")
    assert_match(/\bget\b/, content, "webauthn-json must export a 'get' function")
  end

  test "importmap pin for webauthn-json uses local vendored file, not remote CDN" do
    importmap_content = File.read(Rails.root.join("config/importmap.rb"))
    assert_no_match(
      /pin\s+"@github\/webauthn-json".*https?:\/\//,
      importmap_content,
      "importmap @github/webauthn-json pin must not depend on a remote CDN URL"
    )
    assert_match(
      /pin\s+"@github\/webauthn-json".*@github--webauthn-json\.js/,
      importmap_content,
      "importmap @github/webauthn-json pin must reference local vendored file @github--webauthn-json.js"
    )
  end
end
