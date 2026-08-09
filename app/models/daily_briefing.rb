class DailyBriefing < ApplicationRecord
  validates :date, presence: true, uniqueness: true

  def self.for_today
    find_by(date: Date.current) || order(date: :desc).first
  end

  def calendar_events
    calendar_data.fetch("events", [])
  end

  def hourly_forecast
    weather_data.fetch("hourly", [])
  end

  def weather_current
    weather_data.except("hourly")
  end

  def goals
    daily_goals_data
  end

  def action_items_personal
    action_items_data.fetch("personal", [])
  end

  def action_items_work
    action_items_data.fetch("work", [])
  end

  def long_term_goals
    long_term_goals_data.is_a?(Array) ? long_term_goals_data : []
  end

  def agent_activities
    agent_activity_data.is_a?(Array) ? agent_activity_data : []
  end
end
