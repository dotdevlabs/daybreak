require "test_helper"
require "yaml"

class ApiSpecContractTest < ActionDispatch::IntegrationTest
  VALID_TOKEN = "test_daybreak_token".freeze
  SPEC = YAML.load_file(Rails.root.join("docs/api_spec.yaml")).freeze

  setup do
    ENV["DAYBREAK_API_TOKEN"] = VALID_TOKEN
    DailyBriefing.delete_all
    AgentEndpoint.delete_all
  end

  teardown do
    ENV.delete("DAYBREAK_API_TOKEN")
  end

  def auth_headers
    { "Authorization" => "Bearer #{VALID_TOKEN}", "Content-Type" => "application/vnd.api+json" }
  end

  # --- Coverage Gate ---

  test "spec declares exactly the expected documented operations (coverage gate)" do
    spec_ops = SPEC["paths"].flat_map do |path, item|
      item.keys.reject { |k| k == "parameters" }.map { |m| "#{m.upcase} #{path}" }
    end
    assert_equal 4, spec_ops.size,
      "Expected 4 spec operations; got #{spec_ops.size}: #{spec_ops.inspect}. " \
      "Add compliance tests for any new operations."
  end

  # --- Layer 1: SPEC→CODE Bijection ---

  test "every documented spec path resolves to a Rails route" do
    verified = 0
    SPEC["paths"].each do |spec_path, methods|
      methods.each_key do |verb|
        next if verb == "parameters"
        begin
          Rails.application.routes.recognize_path("/api#{spec_path}", method: verb.upcase)
          verified += 1
        rescue ActionController::RoutingError => e
          flunk "Spec documents #{verb.upcase} /api#{spec_path} but no matching Rails route: #{e.message}"
        end
      end
    end
    assert_operator verified, :>, 0, "Expected at least one spec operation to verify"
  end

  # --- Layer 2: CODE→SPEC Bijection ---

  test "every Api:: controller action is documented in the spec" do
    spec_operations = SPEC["paths"].flat_map do |path, methods|
      methods.keys.reject { |k| k == "parameters" }.map { |verb| "#{verb.upcase} #{path}" }
    end.to_set

    Rails.application.routes.routes.each do |route|
      controller = route.defaults[:controller].to_s
      next unless controller.start_with?("api/")
      next if route.defaults[:action].blank?

      verb = route.verb.to_s.upcase
      raw_path = route.path.spec.to_s.sub(/\(\..*?\)\z/, "")
      spec_path = raw_path.sub(%r{\A/api}, "")
      next if spec_path.blank?

      op = "#{verb} #{spec_path}"
      assert_includes spec_operations, op,
        "Route #{verb} /api#{spec_path} (controller: #{controller}) is not documented in docs/api_spec.yaml"
    end
  end

  # --- Layer 3: Unauthorized Tests (one per spec operation) ---

  SPEC["paths"].each do |spec_path, methods|
    methods.each_key do |verb|
      next if verb == "parameters"

      define_method("test_401_#{verb}_api#{spec_path.gsub('/', '_')}") do
        send(verb.downcase, "/api#{spec_path}",
             headers: { "Content-Type" => "application/vnd.api+json" })
        assert_response :unauthorized,
          "Expected 401 for unauthenticated #{verb.upcase} /api#{spec_path}"
        assert_equal "application/vnd.api+json", response.media_type,
          "Expected JSON:API content type on 401 for #{verb.upcase} /api#{spec_path}"
        errors = response.parsed_body["errors"]
        assert_kind_of Array, errors,
          "Expected errors array on 401 for #{verb.upcase} /api#{spec_path}"
        assert errors.all? { |e| e.key?("detail") },
          "Each error must have a 'detail' key on 401 for #{verb.upcase} /api#{spec_path}"
      end
    end
  end

  # --- Layer 3: Happy-Path Compliance Tests ---

  test "GET /api/catalog returns 200 JSON:API data array of widget_types" do
    get "/api/catalog", headers: auth_headers
    assert_response :ok
    assert_equal "application/vnd.api+json", response.media_type
    data = response.parsed_body["data"]
    assert_kind_of Array, data
    data.each do |resource|
      assert_equal "widget_types", resource["type"]
      assert_kind_of String, resource["id"]
      assert_includes WidgetMessage::WIDGET_TYPES, resource["id"]
      assert_equal %w[description name schema], resource["attributes"].keys.sort,
        "widget_types attributes must be exactly {name, description, schema}, no extras"
    end
  end

  test "POST /api/widgets with valid weather payload returns 201" do
    post "/api/widgets",
         params: {
           data: {
             type: "widget_messages",
             attributes: {
               widget_type: "weather",
               data: { "location" => "SF", "current_temp" => 68, "unit" => "F", "condition" => "Sunny" }
             }
           }
         }.to_json,
         headers: auth_headers
    assert_response :created
    assert_equal "application/vnd.api+json", response.media_type
    data = response.parsed_body["data"]
    assert_equal "widget_messages", data["type"]
    assert_kind_of String, data["id"]
    assert_equal %w[date widget_type], data["attributes"].keys.sort,
      "widget_messages attributes must be exactly {widget_type, date}, no extras"
  end

  test "POST /api/widgets with invalid widget type returns 422" do
    post "/api/widgets",
         params: {
           data: { type: "widget_messages", attributes: { widget_type: "nonexistent" } }
         }.to_json,
         headers: auth_headers
    assert_response :unprocessable_entity
    assert_equal "application/vnd.api+json", response.media_type
    assert response.parsed_body.dig("errors", 0, "detail").present?,
      "422 response must include errors[0].detail"
  end

  test "GET /api/events with auth returns 200 SSE stream" do
    stub_registry = Object.new
    stub_registry.define_singleton_method(:register) { |_sse| raise IOError }
    stub_registry.define_singleton_method(:unregister) { |_sse| }

    with_push_registry(stub_registry) do
      get "/api/events", headers: { "Authorization" => "Bearer #{VALID_TOKEN}" }
    end
    assert_response :ok
    assert_equal "text/event-stream", response.media_type
  end

  test "POST /api/agent/registrations with valid payload returns 201" do
    post "/api/agent/registrations",
         params: {
           data: {
             type: "agent_registrations",
             attributes: { callback_url: "https://agent.example.com/cb" }
           }
         }.to_json,
         headers: auth_headers
    assert_response :created
    assert_equal "application/vnd.api+json", response.media_type
    data = response.parsed_body["data"]
    assert_equal "agent_registrations", data["type"]
    assert_kind_of String, data["id"]
    assert_equal %w[callback_url], data["attributes"].keys.sort,
      "agent_registrations attributes must be exactly {callback_url}, no extras"
  end

  test "POST /api/agent/registrations with missing callback_url returns 422" do
    post "/api/agent/registrations",
         params: {
           data: { type: "agent_registrations", attributes: { callback_url: "" } }
         }.to_json,
         headers: auth_headers
    assert_response :unprocessable_entity
    assert_equal "application/vnd.api+json", response.media_type
    assert response.parsed_body.dig("errors", 0, "detail").present?,
      "422 response must include errors[0].detail"
  end
end
