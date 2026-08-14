require "test_helper"

class WidgetMessageTest < ActiveSupport::TestCase
  # --- valid cases for all 6 widget types ---

  test "valid date_calendar message passes" do
    msg = WidgetMessage.new(
      type: "date_calendar",
      data: { "events" => [ { "title" => "Standup", "time" => "09:00" } ] }
    )
    assert msg.valid?
  end

  test "valid weather message passes" do
    msg = WidgetMessage.new(
      type: "weather",
      data: {
        "location" => "NYC", "current_temp" => 72, "unit" => "F", "condition" => "Sunny",
        "hourly" => [ { "hour" => "9AM", "temp" => 70, "condition" => "Clear" } ]
      }
    )
    assert msg.valid?
  end

  test "valid daily_goals message passes" do
    msg = WidgetMessage.new(
      type: "daily_goals",
      data: { "steps" => { "label" => "Steps", "current" => 5000, "target" => 10000, "unit" => "steps" } }
    )
    assert msg.valid?
  end

  test "valid action_items message passes" do
    msg = WidgetMessage.new(
      type: "action_items",
      data: {
        "personal" => [ { "text" => "Call dentist", "priority" => "high" } ],
        "work" => [ { "text" => "Review PR", "priority" => "medium" } ]
      }
    )
    assert msg.valid?
  end

  test "valid long_term_goals message with array data passes" do
    msg = WidgetMessage.new(
      type: "long_term_goals",
      data: [ { "text" => "Read 24 books", "progress" => 9, "target" => 24, "unit" => "books" } ]
    )
    assert msg.valid?
  end

  test "valid agent_activity message with array data passes" do
    msg = WidgetMessage.new(
      type: "agent_activity",
      data: [ { "text" => "Fetched weather", "timestamp" => "2026-08-09T09:00:00Z", "icon" => "cloud" } ]
    )
    assert msg.valid?
  end

  # --- type validation ---

  test "unknown type produces error naming the invalid type" do
    msg = WidgetMessage.new(type: "unknown_widget", data: {})
    assert msg.invalid?
    error = msg.errors.full_messages.join
    assert_includes error, "unknown_widget"
    assert_includes error, "not a recognized widget type"
  end

  test "nil type produces presence error" do
    msg = WidgetMessage.new(type: nil, data: {})
    assert msg.invalid?
    assert_includes msg.errors[:type], "can't be blank"
  end

  test "blank type produces presence error" do
    msg = WidgetMessage.new(type: "", data: {})
    assert msg.invalid?
    assert_includes msg.errors[:type], "can't be blank"
  end

  # --- date_calendar field validation ---

  test "date_calendar with non-hash data fails" do
    msg = WidgetMessage.new(type: "date_calendar", data: "not a hash")
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "must be an object"
  end

  test "date_calendar with events not an array fails" do
    msg = WidgetMessage.new(type: "date_calendar", data: { "events" => "not an array" })
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "events must be an array"
  end

  test "date_calendar event missing title fails" do
    msg = WidgetMessage.new(type: "date_calendar", data: { "events" => [ { "time" => "09:00" } ] })
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "events[0].title is required"
  end

  test "date_calendar with no events is valid" do
    msg = WidgetMessage.new(type: "date_calendar", data: {})
    assert msg.valid?
  end

  # --- weather field validation ---

  test "weather with non-hash data fails" do
    msg = WidgetMessage.new(type: "weather", data: [])
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "must be an object"
  end

  test "weather hourly missing hour fails" do
    msg = WidgetMessage.new(type: "weather", data: { "hourly" => [ { "temp" => 70 } ] })
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "hourly[0].hour is required"
  end

  test "weather hourly missing temp fails" do
    msg = WidgetMessage.new(type: "weather", data: { "hourly" => [ { "hour" => "9AM" } ] })
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "hourly[0].temp is required"
  end

  test "weather with no hourly is valid" do
    msg = WidgetMessage.new(type: "weather", data: { "location" => "NYC", "current_temp" => 72 })
    assert msg.valid?
  end

  # --- daily_goals field validation ---

  test "daily_goals with non-hash data fails" do
    msg = WidgetMessage.new(type: "daily_goals", data: "not a hash")
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "must be an object"
  end

  test "daily_goals goal missing label fails" do
    msg = WidgetMessage.new(
      type: "daily_goals",
      data: { "steps" => { "current" => 5000, "target" => 10000, "unit" => "steps" } }
    )
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "steps.label is required"
  end

  test "daily_goals goal with non-numeric current fails" do
    msg = WidgetMessage.new(
      type: "daily_goals",
      data: { "steps" => { "label" => "Steps", "current" => "not a number", "target" => 10000, "unit" => "steps" } }
    )
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "steps.current must be a number"
  end

  # --- action_items field validation ---

  test "action_items with non-hash data fails" do
    msg = WidgetMessage.new(type: "action_items", data: [])
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "must be an object"
  end

  test "action_items personal item missing text fails" do
    msg = WidgetMessage.new(type: "action_items", data: { "personal" => [ { "priority" => "high" } ] })
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "personal[0].text is required"
  end

  test "action_items with done=true is valid" do
    msg = WidgetMessage.new(
      type: "action_items",
      data: { "personal" => [ { "text" => "Call dentist", "done" => true } ] }
    )
    assert msg.valid?
  end

  test "action_items with done=false is valid" do
    msg = WidgetMessage.new(
      type: "action_items",
      data: { "work" => [ { "text" => "Review PR", "done" => false } ] }
    )
    assert msg.valid?
  end

  test "action_items with non-boolean done fails" do
    msg = WidgetMessage.new(
      type: "action_items",
      data: { "personal" => [ { "text" => "Call dentist", "done" => "yes" } ] }
    )
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "personal[0].done must be a boolean"
  end

  test "action_items with link as string is valid" do
    msg = WidgetMessage.new(
      type: "action_items",
      data: { "work" => [ { "text" => "Review PR", "link" => "https://example.com" } ] }
    )
    assert msg.valid?
  end

  test "action_items with non-string link fails" do
    msg = WidgetMessage.new(
      type: "action_items",
      data: { "work" => [ { "text" => "Review PR", "link" => 42 } ] }
    )
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "work[0].link must be a string"
  end

  test "action_items with done and link absent is valid" do
    msg = WidgetMessage.new(
      type: "action_items",
      data: { "personal" => [ { "text" => "Call dentist" } ] }
    )
    assert msg.valid?
  end

  # --- long_term_goals field validation ---

  test "long_term_goals with non-array data fails" do
    msg = WidgetMessage.new(type: "long_term_goals", data: { "not" => "an array" })
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "must be an array"
  end

  test "long_term_goals goal missing text fails" do
    msg = WidgetMessage.new(
      type: "long_term_goals",
      data: [ { "progress" => 5, "target" => 10, "unit" => "books" } ]
    )
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "goals[0].text is required"
  end

  test "long_term_goals goal missing progress fails" do
    msg = WidgetMessage.new(
      type: "long_term_goals",
      data: [ { "text" => "Read books", "target" => 10, "unit" => "books" } ]
    )
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "goals[0].progress is required"
  end

  # --- agent_activity field validation ---

  test "agent_activity with non-array data fails" do
    msg = WidgetMessage.new(type: "agent_activity", data: {})
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "must be an array"
  end

  test "agent_activity entry missing text fails" do
    msg = WidgetMessage.new(
      type: "agent_activity",
      data: [ { "timestamp" => "2026-08-09T09:00:00Z" } ]
    )
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "activities[0].text is required"
  end

  test "agent_activity entry missing timestamp fails" do
    msg = WidgetMessage.new(
      type: "agent_activity",
      data: [ { "text" => "Did something" } ]
    )
    assert msg.invalid?
    assert_includes msg.errors.full_messages.join, "activities[0].timestamp is required"
  end

  # --- apply_to ---

  test "apply_to sets the correct column on a DailyBriefing" do
    briefing = DailyBriefing.new(date: Date.current)
    data = { "location" => "NYC", "current_temp" => 72, "unit" => "F", "condition" => "Sunny" }
    msg = WidgetMessage.new(type: "weather", data: data)
    msg.apply_to(briefing)
    assert_equal data, briefing.weather_data
  end

  test "apply_to sets array column for long_term_goals" do
    briefing = DailyBriefing.new(date: Date.current)
    data = [ { "text" => "Run a marathon", "progress" => 5, "target" => 26.2, "unit" => "miles" } ]
    msg = WidgetMessage.new(type: "long_term_goals", data: data)
    msg.apply_to(briefing)
    assert_equal data, briefing.long_term_goals_data
  end

  test "apply_to sets array column for agent_activity" do
    briefing = DailyBriefing.new(date: Date.current)
    data = [ { "text" => "Fetched weather", "timestamp" => "2026-08-09T09:00:00Z" } ]
    msg = WidgetMessage.new(type: "agent_activity", data: data)
    msg.apply_to(briefing)
    assert_equal data, briefing.agent_activity_data
  end
end
