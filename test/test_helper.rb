ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Register JSON:API MIME type encoder so response.parsed_body works for
# application/vnd.api+json responses in integration tests.
ActionDispatch::IntegrationTest.register_encoder :jsonapi,
  param_encoder: -> params { params.to_json },
  response_parser: -> body { JSON.parse(body) }

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
