require "application_system_test_case"

class DashboardTest < ApplicationSystemTestCase
  fixtures :daily_briefings

  test "dashboard page shows date widget" do
    visit root_url
    assert_selector ".date-widget"
  end

  test "dashboard page shows weather widget" do
    visit root_url
    assert_selector ".weather-widget"
  end

  test "dashboard page shows daily goals widget with progress bars" do
    visit root_url
    assert_selector ".goals-widget"
    assert_selector ".goal-bar"
  end

  test "dashboard page shows action items section with personal and work columns" do
    visit root_url
    assert_selector ".action-items"
    assert_text "Personal"
    assert_text "Work"
  end

  test "dashboard page shows long term goals section" do
    visit root_url
    assert_selector ".long-term-goals"
  end

  test "dashboard page shows agent activity section" do
    visit root_url
    assert_selector ".agent-activity"
  end

  test "overflow indicator badge appears when agent activities overflow" do
    visit root_url
    # The fixture has 8 agent activities which should overflow the 220px max-height
    assert_selector "[data-overflow-indicator-target='badge']"
  end
end
