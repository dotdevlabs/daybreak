require "test_helper"

class Dashboard::ActionItemCompletionsControllerTest < ActionDispatch::IntegrationTest
  def post_completion(params = {})
    post dashboard_action_item_completions_url,
         params: { context: "personal", text: "Call dentist", priority: "high" }.merge(params).to_json,
         headers: { "Content-Type" => "application/json" }
  end

  setup do
    AgentPushRegistry.instance.instance_variable_set(:@streams, [])  # reset between tests
    sign_in_as(users(:alice))
  end

  test "POST /dashboard/action_item_completions returns 200" do
    mock_registry = Object.new
    mock_registry.define_singleton_method(:broadcast) { |_| true }
    with_push_registry(mock_registry) { post_completion }
    assert_response :ok
  end

  test "POST /dashboard/action_item_completions delivers outbound message with correct data" do
    captured = nil
    mock_registry = Object.new
    mock_registry.define_singleton_method(:broadcast) do |json|
      captured = JSON.parse(json)
      true
    end
    with_push_registry(mock_registry) do
      post_completion(context: "work", text: "Review PR", priority: "medium")
    end

    assert_equal "action_items", captured["type"]
    assert_equal "item_completed", captured["action"]
    assert_equal "work", captured.dig("data", "context")
    assert_equal "Review PR", captured.dig("data", "item", "text")
    assert_equal "medium", captured.dig("data", "item", "priority")
  end

  test "POST /dashboard/action_item_completions omits nil priority from item data" do
    captured = nil
    mock_registry = Object.new
    mock_registry.define_singleton_method(:broadcast) do |json|
      captured = JSON.parse(json)
      true
    end
    with_push_registry(mock_registry) { post_completion(priority: nil) }

    assert_not captured.dig("data", "item").key?("priority")
  end

  test "POST /dashboard/action_item_completions includes link in outbound message when present" do
    captured = nil
    mock_registry = Object.new
    mock_registry.define_singleton_method(:broadcast) do |json|
      captured = JSON.parse(json)
      true
    end
    with_push_registry(mock_registry) do
      post_completion(link: "https://example.com/pr")
    end
    assert_equal "https://example.com/pr", captured.dig("data", "item", "link")
  end

  test "POST /dashboard/action_item_completions omits link from outbound message when absent" do
    captured = nil
    mock_registry = Object.new
    mock_registry.define_singleton_method(:broadcast) do |json|
      captured = JSON.parse(json)
      true
    end
    with_push_registry(mock_registry) { post_completion }
    assert_not captured.dig("data", "item").key?("link")
  end
end
