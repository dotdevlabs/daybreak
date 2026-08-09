require "test_helper"

class Api::WidgetsControllerTest < ActionDispatch::IntegrationTest
  VALID_TOKEN = "test_daybreak_token".freeze

  setup do
    ENV["DAYBREAK_API_TOKEN"] = VALID_TOKEN
    DailyBriefing.delete_all
  end

  teardown do
    ENV.delete("DAYBREAK_API_TOKEN")
  end

  def post_widget(type:, data:, token: VALID_TOKEN)
    post api_widgets_url,
         params: { type: type, data: data }.to_json,
         headers: {
           "Content-Type" => "application/json",
           "Authorization" => "Bearer #{token}"
         }
  end

  # --- valid widget messages ---

  test "valid weather message returns 200" do
    post_widget(
      type: "weather",
      data: { "location" => "NYC", "current_temp" => 72, "unit" => "F", "condition" => "Sunny" }
    )
    assert_response :success
    assert_equal "ok", response.parsed_body["status"]
    assert_equal "weather", response.parsed_body["widget"]
  end

  test "valid date_calendar message creates briefing and returns 200" do
    assert_difference "DailyBriefing.count", 1 do
      post_widget(
        type: "date_calendar",
        data: { "events" => [{ "title" => "Standup", "time" => "09:00" }] }
      )
    end
    assert_response :success
  end

  test "valid long_term_goals message with array data returns 200" do
    post_widget(
      type: "long_term_goals",
      data: [{ "text" => "Read 24 books", "progress" => 9, "target" => 24, "unit" => "books" }]
    )
    assert_response :success
  end

  test "valid agent_activity message with array data returns 200" do
    post_widget(
      type: "agent_activity",
      data: [{ "text" => "Fetched weather", "timestamp" => "2026-08-09T09:00:00Z", "icon" => "cloud" }]
    )
    assert_response :success
  end

  test "valid daily_goals message returns 200" do
    post_widget(
      type: "daily_goals",
      data: { "steps" => { "label" => "Steps", "current" => 5000, "target" => 10000, "unit" => "steps" } }
    )
    assert_response :success
  end

  test "valid action_items message returns 200" do
    post_widget(
      type: "action_items",
      data: {
        "personal" => [{ "text" => "Call dentist", "priority" => "high" }],
        "work" => [{ "text" => "Review PR", "priority" => "medium" }]
      }
    )
    assert_response :success
  end

  # --- authentication ---

  test "missing Authorization header returns 401" do
    post api_widgets_url,
         params: { type: "weather", data: {} }.to_json,
         headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
    assert_equal "Unauthorized", response.parsed_body["error"]
  end

  test "wrong token returns 401" do
    post_widget(type: "weather", data: {}, token: "wrong_token")
    assert_response :unauthorized
    assert_equal "Unauthorized", response.parsed_body["error"]
  end

  test "empty token returns 401" do
    post_widget(type: "weather", data: {}, token: "")
    assert_response :unauthorized
  end

  # --- validation errors ---

  test "unknown widget type returns 422 with clear error" do
    post_widget(type: "unknown_type", data: {})
    assert_response :unprocessable_entity
    error = response.parsed_body["errors"].first
    assert_includes error, "unknown_type"
    assert_includes error, "not a recognized widget type"
  end

  test "missing required field returns 422 with field error" do
    post_widget(type: "date_calendar", data: { "events" => [{ "time" => "09:00" }] })
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"].join, "title is required"
  end

  test "wrong data shape for array type returns 422" do
    post_widget(type: "long_term_goals", data: { "not" => "an array" })
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"].join, "must be an array"
  end

  test "wrong data shape for object type returns 422" do
    post_widget(type: "weather", data: [])
    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"].join, "must be an object"
  end

  # --- upsert behavior ---

  test "widget update creates briefing when none exists" do
    assert_difference "DailyBriefing.count", 1 do
      post_widget(
        type: "weather",
        data: { "location" => "NYC", "current_temp" => 72, "unit" => "F", "condition" => "Sunny" }
      )
    end
    assert_response :success
    assert_equal "NYC", DailyBriefing.for_today.weather_current["location"]
  end

  test "widget update modifies existing briefing without creating a duplicate" do
    DailyBriefing.create!(date: Date.current)
    assert_no_difference "DailyBriefing.count" do
      post_widget(
        type: "weather",
        data: { "location" => "LA", "current_temp" => 80, "unit" => "F", "condition" => "Clear" }
      )
    end
    assert_response :success
    assert_equal "LA", DailyBriefing.for_today.weather_current["location"]
  end

  test "response includes date in iso8601 format" do
    post_widget(type: "weather", data: { "location" => "Boston" })
    assert_response :success
    assert_equal Date.current.iso8601, response.parsed_body["date"]
  end

  test "successive widget messages update independently" do
    post_widget(
      type: "weather",
      data: { "location" => "NYC", "current_temp" => 72, "unit" => "F", "condition" => "Sunny" }
    )
    post_widget(
      type: "daily_goals",
      data: { "steps" => { "label" => "Steps", "current" => 3000, "target" => 10000, "unit" => "steps" } }
    )
    briefing = DailyBriefing.for_today
    assert_equal "NYC", briefing.weather_current["location"]
    assert_equal 3000, briefing.goals.dig("steps", "current")
  end
end
