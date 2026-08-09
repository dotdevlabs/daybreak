# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

DailyBriefing.find_or_create_by!(date: Date.today) do |b|
  b.calendar_data = {
    "events" => [
      { "title" => "Team standup", "time" => "09:00", "duration_minutes" => 30 },
      { "title" => "Lunch with Sarah", "time" => "12:30", "duration_minutes" => 60 },
      { "title" => "Code review session", "time" => "15:00", "duration_minutes" => 45 }
    ]
  }

  b.weather_data = {
    "location" => "San Francisco, CA",
    "current_temp" => 65,
    "unit" => "F",
    "condition" => "Partly Cloudy",
    "hourly" => [
      { "hour" => "7am", "temp" => 60, "condition" => "Clear" },
      { "hour" => "8am", "temp" => 62, "condition" => "Clear" },
      { "hour" => "9am", "temp" => 64, "condition" => "Sunny" },
      { "hour" => "10am", "temp" => 65, "condition" => "Partly Cloudy" },
      { "hour" => "11am", "temp" => 66, "condition" => "Partly Cloudy" },
      { "hour" => "12pm", "temp" => 68, "condition" => "Cloudy" },
      { "hour" => "1pm", "temp" => 67, "condition" => "Cloudy" },
      { "hour" => "2pm", "temp" => 66, "condition" => "Partly Cloudy" },
      { "hour" => "3pm", "temp" => 65, "condition" => "Sunny" }
    ]
  }

  b.daily_goals_data = {
    "exercise" => { "label" => "Exercise", "current" => 25, "target" => 60, "unit" => "min" },
    "protein"  => { "label" => "Protein",  "current" => 45, "target" => 150, "unit" => "g" },
    "calories" => { "label" => "Calories", "current" => 800, "target" => 2000, "unit" => "kcal" }
  }

  b.action_items_data = {
    "personal" => [
      { "text" => "Call dentist to reschedule appointment", "priority" => "high" },
      { "text" => "Buy groceries for dinner", "priority" => "medium" },
      { "text" => "Reply to mom's birthday message", "priority" => "high" }
    ],
    "work" => [
      { "text" => "Review PR #247 before noon", "priority" => "high" },
      { "text" => "Draft quarterly OKR update", "priority" => "high" },
      { "text" => "Schedule 1:1 with Alex", "priority" => "medium" },
      { "text" => "Send invoice to Acme Corp", "priority" => "high" }
    ]
  }

  b.long_term_goals_data = [
    { "text" => "Learn conversational Spanish", "progress" => 35, "target" => 100, "unit" => "%" },
    { "text" => "Save $10,000 emergency fund", "progress" => 6500, "target" => 10000, "unit" => "$" },
    { "text" => "Run a half marathon", "progress" => 8, "target" => 13, "unit" => "miles" }
  ]

  b.agent_activity_data = [
    { "text" => "Summarized 3 newsletter emails from inbox", "timestamp" => "7:15am", "icon" => "mail" },
    { "text" => "Updated grocery list with 5 items", "timestamp" => "7:18am", "icon" => "list" },
    { "text" => "Booked restaurant for Friday dinner", "timestamp" => "7:22am", "icon" => "calendar" },
    { "text" => "Flagged unusual Amazon charge for review", "timestamp" => "7:26am", "icon" => "alert-circle" },
    { "text" => "Weather brief ready for today's commute", "timestamp" => "7:30am", "icon" => "cloud-sun" },
    { "text" => "Prepped meeting agenda for 2pm standup", "timestamp" => "7:35am", "icon" => "clipboard-list" },
    { "text" => "Drafted reply to client email", "timestamp" => "7:40am", "icon" => "send" },
    { "text" => "Reminded about dentist call at 10am", "timestamp" => "7:45am", "icon" => "bell" }
  ]
end
