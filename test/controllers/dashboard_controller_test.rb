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

  test "shows briefing date in calendar week" do
    get root_url
    assert_select ".calendar-week"
    assert_select ".calendar-week__date--today"
  end

  test "shows goal progress bars" do
    get root_url
    assert_select ".goal-bar__track"
    assert_select ".goal-bar__fill"
  end

  test "shows personal and work action item cards" do
    get root_url
    assert_select ".widget__title", text: I18n.t("dashboard.action_items.personal_title")
    assert_select ".widget__title", text: I18n.t("dashboard.action_items.work_title")
  end

  test "shows agent activity cards" do
    get root_url
    assert_select ".agent-activity-card"
  end

  test "layout head includes PWA manifest link" do
    get root_url
    assert_select "link[rel='manifest']"
  end

  test "layout head includes favicon links" do
    get root_url
    assert_select "link[rel='icon'][href='/favicon.ico']"
    assert_select "link[rel='icon'][href='/icon.svg']"
    assert_select "link[rel='apple-touch-icon'][href='/apple-touch-icon.png']"
  end

  test "layout head includes theme-color meta" do
    get root_url
    assert_select "meta[name='theme-color'][content='#D4916E']"
  end

  test "layout head has application name Daybreak" do
    get root_url
    assert_select "meta[name='application-name'][content='Daybreak']"
  end
end
