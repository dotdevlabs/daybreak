require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  fixtures :daily_briefings

  test "GET root returns 200 OK" do
    get root_url
    assert_response :success
  end

  test "renders date widget when briefing exists" do
    get root_url
    assert_select ".date-widget"
  end

  test "renders weather widget when briefing exists" do
    get root_url
    assert_select ".weather-widget"
  end

  test "renders daily goals widget when briefing exists" do
    get root_url
    assert_select ".goals-widget"
  end

  test "renders action items section when briefing exists" do
    get root_url
    assert_select ".action-items"
  end

  test "renders long term goals section when briefing exists" do
    get root_url
    assert_select ".long-term-goals"
  end

  test "renders agent activity section when briefing exists" do
    get root_url
    assert_select ".agent-activity"
  end

  test "renders without error when no briefing record exists" do
    DailyBriefing.delete_all
    get root_url
    assert_response :success
    assert_select ".dashboard__empty"
  end

  test "shows briefing date in date widget" do
    get root_url
    assert_select ".date-widget__weekday"
    assert_select ".date-widget__full"
  end

  test "shows goal progress bars" do
    get root_url
    assert_select ".goal-bar"
    assert_select ".goal-bar__track"
    assert_select ".goal-bar__fill"
  end

  test "shows personal and work action item groups" do
    get root_url
    assert_select ".action-items__group-title", text: "Personal"
    assert_select ".action-items__group-title", text: "Work"
  end

  test "shows agent activity items" do
    get root_url
    assert_select ".agent-activity__item"
  end
end
