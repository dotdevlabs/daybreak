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
    assert_selector ".goal-bar__track"
  end

  test "dashboard page shows action items section with personal and work cards" do
    visit root_url
    assert_selector ".action-items"
    assert_selector ".action-items-card", count: 2
    assert_selector ".widget__title", text: "Action Items – Personal"
    assert_selector ".widget__title", text: "Action Items – Work"
  end

  test "dashboard page shows long term goals section" do
    visit root_url
    assert_selector ".long-term-goals"
  end

  test "dashboard page shows agent activity section" do
    visit root_url
    assert_selector ".agent-activity"
  end

  test "logo is rendered in the header" do
    visit root_url
    assert_selector ".logo"
    assert_selector ".logo__wordmark"
  end

  test "header shows live clock elements" do
    visit root_url
    assert_selector "[data-clock-target='time']"
    assert_selector "[data-clock-target='ampm']"
    assert_selector "[data-clock-target='greeting']"
  end

  test "calendar widget shows mini week calendar" do
    visit root_url
    assert_selector ".calendar-week"
    assert_selector ".calendar-week__date", count: 7
    assert_selector ".calendar-week__date--today"
  end

  test "weather widget shows current temperature and hourly tiles" do
    visit root_url
    assert_selector ".weather-widget__temp"
    assert_selector ".forecast-slot"
    assert_selector ".forecast-slot--current"
  end

  test "daily goals widget shows complete and in-progress items" do
    visit root_url
    assert_selector ".goal-item--complete"
    assert_selector ".goal-item--in-progress"
    assert_selector ".goal-item__bar-track"
  end

  test "long term goals shows card grid with insights" do
    visit root_url
    assert_selector ".long-term-goal-card", minimum: 1
    assert_selector ".goal-card__insight"
    assert_selector ".goal-card__percent"
  end

  test "agent activity card shows overflow fade when content overflows" do
    visit root_url
    assert_selector ".agent-activity-card"
    assert_selector "[data-card-overflow-target='fade']:not([hidden])", minimum: 1
  end

  test "agent activity card without overflow does not show fade" do
    visit root_url
    # Wait for JS to run (evidenced by overflow fades becoming visible on long cards)
    assert_selector "[data-card-overflow-target='fade']:not([hidden])", minimum: 1
    # Cards without body text should still have their fade hidden
    # visible: :all is required because [hidden] elements are display:none (invisible to Capybara's default filter)
    assert_selector "[data-card-overflow-target='fade'][hidden]", minimum: 1, visible: :all
  end

  test "footer is rendered" do
    visit root_url
    assert_selector ".dashboard__footer"
  end
end
