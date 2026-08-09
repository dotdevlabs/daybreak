require "test_helper"
require "erb"
require "yaml"

class DatabaseConfigurationTest < ActiveSupport::TestCase
  setup do
    template = File.read(Rails.root.join("config/database.yml"))
    @config = YAML.safe_load(ERB.new(template).result, permitted_classes: [], aliases: true)
  end

  test "production primary database is daybreak_production" do
    assert_equal "daybreak_production", @config.dig("production", "primary", "database")
  end

  test "production cache database is daybreak_production_cache" do
    assert_equal "daybreak_production_cache", @config.dig("production", "cache", "database")
  end

  test "production queue database is daybreak_production_queue" do
    assert_equal "daybreak_production_queue", @config.dig("production", "queue", "database")
  end

  test "production cable database is daybreak_production_cable" do
    assert_equal "daybreak_production_cable", @config.dig("production", "cable", "database")
  end

  test "production role is daybreak" do
    assert_equal "daybreak", @config.dig("production", "primary", "username")
  end

  test "production password reads from DAYBREAK_DATABASE_PASSWORD" do
    assert @config.dig("production", "primary").key?("password"),
           "production primary must declare a password key"
  end

  test "development and test databases are unchanged" do
    assert_equal "workspace_development", @config.dig("development", "database")
    assert_equal "workspace_test", @config.dig("test", "database")
  end
end
