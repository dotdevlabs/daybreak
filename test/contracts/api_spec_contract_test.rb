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
    assert_equal 6, spec_ops.size,
      "Expected 6 spec operations; got #{spec_ops.size}: #{spec_ops.inspect}. " \
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
      next if methods.dig(verb, "security") == []

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

  test "GET /api/status returns 200 JSON:API status resource with deploy attributes" do
    get "/api/status", headers: auth_headers
    assert_response :ok
    assert_equal "application/vnd.api+json", response.media_type
    data = response.parsed_body["data"]
    assert_equal "status", data["type"]
    assert_equal "current", data["id"]
    assert_equal %w[db_version sha version], data["attributes"].keys.sort,
      "status attributes must be exactly {version, sha, db_version}, no extras"
    # version and sha are nil when ENV vars not set (acceptable per spec)
    assert(data["attributes"]["db_version"].nil? || data["attributes"]["db_version"].is_a?(String),
           "db_version must be a String or nil")
    assert_equal "/api/status", data.dig("links", "self"),
      "status resource must carry links.self = /api/status"
  end

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
    # Collection-level links
    body  = response.parsed_body
    links = body["links"]
    assert_kind_of Hash, links, "catalog response must have top-level links object"
    assert_equal "/api/catalog", links["self"]
    assert_equal "/api/catalog", links["first"]
    assert_equal "/api/catalog", links["last"]
    assert_nil links["prev"], "prev must be nil for single-page catalog"
    assert_nil links["next"], "next must be nil for single-page catalog"
    # Meta counts
    meta = body["meta"]
    assert_kind_of Hash, meta, "catalog response must have meta"
    assert_equal 6, meta["total_count"]
    # Per-resource self links
    data.each do |resource|
      assert_match %r{\A/api/catalog/\w}, resource.dig("links", "self"),
        "widget_type resource must carry links.self"
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
    assert_match %r{\A/api/widgets/\d{4}-\d{2}-\d{2}\z}, data.dig("links", "self"),
      "widget_messages resource must carry links.self pointing to its canonical URL"
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
    assert_match %r{\A/api/agent/registrations/\d+\z}, data.dig("links", "self"),
      "agent_registrations resource must carry links.self pointing to its canonical URL"
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

  test "POST /api/tokens without auth returns 201 JSON:API data with token" do
    post "/api/tokens", headers: { "Content-Type" => "application/vnd.api+json" }
    assert_response :created
    assert_equal "application/vnd.api+json", response.media_type
    data = response.parsed_body["data"]
    assert_equal "api_tokens", data["type"]
    assert_kind_of String, data["id"]
    assert_equal %w[token], data["attributes"].keys.sort,
      "api_tokens attributes must be exactly {token}, no extras"
    assert data.dig("attributes", "token").present?, "token must not be blank"
    assert_match %r{\A/api/tokens/\d+\z}, data.dig("links", "self"),
      "api_tokens resource must carry links.self pointing to its canonical URL"
  end
end
