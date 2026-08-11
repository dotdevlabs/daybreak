require "test_helper"

class SentryInitializerTest < ActiveSupport::TestCase
  INITIALIZER_PATH = Rails.root.join("config/initializers/sentry.rb").freeze

  teardown do
    Sentry.close if Sentry.initialized?
  end

  test "Sentry stays inert when SENTRY_DSN is absent" do
    with_env("SENTRY_DSN" => nil) do
      load INITIALIZER_PATH
      refute Sentry.initialized?, "Sentry must not be initialized without SENTRY_DSN"
    end
  end

  test "Sentry initializes when SENTRY_DSN is present" do
    with_env("SENTRY_DSN" => "https://fake@o0.ingest.sentry.io/0", "APP_SHA" => "deadbeef") do
      load INITIALIZER_PATH
      assert Sentry.initialized?
    end
  end

  test "DSN is read from SENTRY_DSN env var" do
    with_env("SENTRY_DSN" => "https://fake@o0.ingest.sentry.io/0") do
      load INITIALIZER_PATH
      assert_equal "https://fake@o0.ingest.sentry.io/0", Sentry.configuration.dsn.to_s
    end
  end

  test "release is read from APP_SHA env var" do
    with_env("SENTRY_DSN" => "https://fake@o0.ingest.sentry.io/0", "APP_SHA" => "abc1234") do
      load INITIALIZER_PATH
      assert_equal "abc1234", Sentry.configuration.release
    end
  end

  test "environment is set from Rails.env" do
    with_env("SENTRY_DSN" => "https://fake@o0.ingest.sentry.io/0") do
      load INITIALIZER_PATH
      assert_equal Rails.env.to_s, Sentry.configuration.environment
    end
  end

  test "send_default_pii is false" do
    with_env("SENTRY_DSN" => "https://fake@o0.ingest.sentry.io/0") do
      load INITIALIZER_PATH
      refute Sentry.configuration.send_default_pii
    end
  end

  test "traces_sample_rate is 0.1" do
    with_env("SENTRY_DSN" => "https://fake@o0.ingest.sentry.io/0") do
      load INITIALIZER_PATH
      assert_in_delta 0.1, Sentry.configuration.traces_sample_rate
    end
  end

  private

  def with_env(vars)
    saved = vars.keys.to_h { |k| [ k, ENV[k] ] }
    vars.each { |k, v| v.nil? ? ENV.delete(k) : ENV.store(k, v) }
    yield
  ensure
    saved.each { |k, v| v.nil? ? ENV.delete(k) : ENV.store(k, v) }
  end
end
