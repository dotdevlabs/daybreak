require "test_helper"

class ProductionMailerConfigurationTest < ActiveSupport::TestCase
  PRODUCTION_ENV_PATH = Rails.root.join("config/environments/production.rb").freeze

  setup do
    @config_source = File.read(PRODUCTION_ENV_PATH)
  end

  test "production delivery method is postmark" do
    assert_match(/delivery_method\s*=\s*:postmark/, @config_source,
      "production.rb must set action_mailer.delivery_method = :postmark")
  end

  test "Postmark API token is sourced from ENV POSTMARK_API_TOKEN" do
    assert_match(/POSTMARK_API_TOKEN/, @config_source,
      "production.rb must read POSTMARK_API_TOKEN from ENV")
  end

  test "production mailer host is daybreak.cool" do
    assert_match(/daybreak\.cool/, @config_source,
      "production.rb must set default_url_options host to daybreak.cool")
  end

  test "raise_delivery_errors is set to true" do
    assert_match(/raise_delivery_errors\s*=\s*true/, @config_source,
      "production.rb must set raise_delivery_errors = true")
  end

  test "perform_deliveries is set to true" do
    assert_match(/perform_deliveries\s*=\s*true/, @config_source,
      "production.rb must set perform_deliveries = true")
  end
end
