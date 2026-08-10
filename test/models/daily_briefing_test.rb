require "test_helper"

class DailyBriefingTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    briefing = DailyBriefing.new(date: Date.today + 10)
    assert briefing.valid?
  end

  test "invalid without date" do
    briefing = DailyBriefing.new(date: nil)
    assert_not briefing.valid?
    assert_includes briefing.errors[:date], "can't be blank"
  end

  test "invalid with duplicate date" do
    existing = daily_briefings(:today)
    duplicate = DailyBriefing.new(date: existing.date)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:date], "has already been taken"
  end

  test "for_today returns today record when it exists" do
    result = DailyBriefing.for_today
    assert_equal Date.today, result.date
  end

  test "for_today falls back to most recent record when no today record" do
    daily_briefings(:today).destroy
    result = DailyBriefing.for_today
    assert_equal daily_briefings(:yesterday).date, result.date
  end

  test "for_today returns nil when no records exist" do
    DailyBriefing.delete_all
    assert_nil DailyBriefing.for_today
  end

  test "calendar_events returns empty array for blank calendar_data" do
    briefing = daily_briefings(:yesterday)
    assert_equal [], briefing.calendar_events
  end

  test "calendar_events returns events from calendar_data" do
    briefing = daily_briefings(:today)
    assert briefing.calendar_events.length >= 1
    assert_equal "Team standup", briefing.calendar_events.first["title"]
  end

  test "hourly_forecast returns empty array for blank weather_data" do
    briefing = daily_briefings(:yesterday)
    assert_equal [], briefing.hourly_forecast
  end

  test "hourly_forecast returns hourly data from weather_data" do
    briefing = daily_briefings(:today)
    assert briefing.hourly_forecast.any?
    assert_equal "9am", briefing.hourly_forecast.first["hour"]
  end

  test "weather_current excludes hourly key" do
    briefing = daily_briefings(:today)
    assert_not_includes briefing.weather_current.keys, "hourly"
    assert_equal "San Francisco, CA", briefing.weather_current["location"]
  end

  test "action_items_personal returns personal items" do
    briefing = daily_briefings(:today)
    personal = briefing.action_items_personal
    assert_equal 1, personal.length
    assert_equal "Call dentist", personal.first["text"]
  end

  test "action_items_work returns work items" do
    briefing = daily_briefings(:today)
    work = briefing.action_items_work
    assert_equal 1, work.length
    assert_equal "Review PR #247", work.first["text"]
  end

  test "action_items_personal returns empty array for blank action_items_data" do
    briefing = daily_briefings(:yesterday)
    assert_equal [], briefing.action_items_personal
  end

  test "long_term_goals returns array from long_term_goals_data" do
    briefing = daily_briefings(:today)
    goals = briefing.long_term_goals
    assert goals.length >= 1
    assert_equal "Read 24 books", goals.first["text"]
  end

  test "long_term_goals returns empty array for blank data" do
    briefing = daily_briefings(:yesterday)
    assert_equal [], briefing.long_term_goals
  end

  test "agent_activities returns array from agent_activity_data" do
    briefing = daily_briefings(:today)
    activities = briefing.agent_activities
    assert_equal 8, activities.length
    assert_equal "Summarized 3 emails", activities.first["text"]
  end

  test "agent_activities returns empty array for blank data" do
    briefing = daily_briefings(:yesterday)
    assert_equal [], briefing.agent_activities
  end
end
