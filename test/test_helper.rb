ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webauthn/fake_client"

# Register JSON:API MIME type encoder so response.parsed_body works for
# application/vnd.api+json responses in integration tests.
ActionDispatch::IntegrationTest.register_encoder :jsonapi,
  param_encoder: ->(params) { params.to_json },
  response_parser: ->(body) { JSON.parse(body) }

module AuthHelpers
  def sign_in_as(user)
    session_record = user.sessions.create!(
      ip_address: "127.0.0.1",
      user_agent: "Rails Test"
    )
    # Use ActionDispatch's own cookie jar to produce a properly signed value
    env = {
      "action_dispatch.key_generator"           => Rails.application.key_generator,
      "action_dispatch.signed_cookie_salt"      => Rails.application.config.action_dispatch.signed_cookie_salt,
      "action_dispatch.cookies_serializer"      => Rails.application.config.action_dispatch.cookies_serializer,
      "action_dispatch.cookies_digest"          => Rails.application.config.action_dispatch.cookies_digest,
      "action_dispatch.use_cookies_with_metadata" => Rails.application.config.action_dispatch.use_cookies_with_metadata,
      "action_dispatch.cookies_rotations"       => Rails.application.config.action_dispatch.cookies_rotations,
      "HTTP_HOST"  => "www.example.com",
      "rack.input" => StringIO.new("")
    }
    fake_request = ActionDispatch::Request.new(env)
    fake_request.cookie_jar.signed[:session_id] = {
      value:     session_record.id,
      httponly:  true,
      path:      "/"
    }
    cookies[:session_id] = fake_request.cookie_jar[:session_id]
  end
end

class ActionDispatch::IntegrationTest
  include AuthHelpers
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Temporarily replace the AgentPushRegistry singleton instance.
    # Minitest 6 has no built-in stub; we swap @singleton__instance__ directly
    # (Ruby 3.4's Singleton uses that ivar name, not @_instance).
    def with_push_registry(mock_registry)
      ivar = :@singleton__instance__
      original = AgentPushRegistry.instance_variable_get(ivar)
      AgentPushRegistry.instance_variable_set(ivar, mock_registry)
      yield
    ensure
      AgentPushRegistry.instance_variable_set(ivar, original)
    end
  end
end
