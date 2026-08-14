class WidgetMessage
  include ActiveModel::Validations

  WIDGET_TYPES = %w[date_calendar weather daily_goals action_items long_term_goals agent_activity].freeze

  BRIEFING_COLUMN = {
    "date_calendar"   => :calendar_data,
    "weather"         => :weather_data,
    "daily_goals"     => :daily_goals_data,
    "action_items"    => :action_items_data,
    "long_term_goals" => :long_term_goals_data,
    "agent_activity"  => :agent_activity_data
  }.freeze

  attr_reader :type, :data

  def initialize(type:, data:)
    @type = type
    @data = data
  end

  validates :type, presence: true,
                   inclusion: { in: WIDGET_TYPES,
                                message: "'%{value}' is not a recognized widget type. Valid types: #{WIDGET_TYPES.join(', ')}" }
  validate :data_conforms_to_type, if: -> { WIDGET_TYPES.include?(type) }

  def apply_to(briefing)
    briefing.public_send(:"#{BRIEFING_COLUMN[type]}=", data)
  end

  private

  def data_conforms_to_type
    send(:"validate_#{type}")
  end

  def validate_date_calendar
    return errors.add(:data, "must be an object") unless data.is_a?(Hash)
    events = data["events"]
    return unless events.present?
    return errors.add(:data, "events must be an array") unless events.is_a?(Array)
    events.each_with_index do |e, i|
      errors.add(:data, "events[#{i}].title is required") if e["title"].blank?
    end
  end

  def validate_weather
    return errors.add(:data, "must be an object") unless data.is_a?(Hash)
    hourly = data["hourly"]
    return unless hourly.present?
    return errors.add(:data, "hourly must be an array") unless hourly.is_a?(Array)
    hourly.each_with_index do |slot, i|
      errors.add(:data, "hourly[#{i}].hour is required")  if slot["hour"].blank?
      errors.add(:data, "hourly[#{i}].temp is required")  if slot["temp"].nil?
    end
  end

  def validate_daily_goals
    return errors.add(:data, "must be an object") unless data.is_a?(Hash)
    data.each do |key, goal|
      next unless goal.is_a?(Hash)
      %w[label current target unit].each do |field|
        errors.add(:data, "#{key}.#{field} is required") if goal[field].nil?
      end
      errors.add(:data, "#{key}.current must be a number") unless goal["current"].is_a?(Numeric)
      errors.add(:data, "#{key}.target must be a number") unless goal["target"].is_a?(Numeric)
    end
  end

  def validate_action_items
    return errors.add(:data, "must be an object") unless data.is_a?(Hash)
    %w[personal work].each do |context|
      items = data[context]
      next unless items.present?
      return errors.add(:data, "#{context} must be an array") unless items.is_a?(Array)
      items.each_with_index do |item, i|
        errors.add(:data, "#{context}[#{i}].text is required") if item["text"].blank?
        if item.key?("done") && ![ true, false ].include?(item["done"])
          errors.add(:data, "#{context}[#{i}].done must be a boolean")
        end
        if item.key?("link") && !item["link"].is_a?(String)
          errors.add(:data, "#{context}[#{i}].link must be a string")
        end
      end
    end
  end

  def validate_long_term_goals
    return errors.add(:data, "must be an array") unless data.is_a?(Array)
    data.each_with_index do |goal, i|
      errors.add(:data, "goals[#{i}].text is required")     if goal["text"].blank?
      errors.add(:data, "goals[#{i}].progress is required") if goal["progress"].nil?
      errors.add(:data, "goals[#{i}].target is required")   if goal["target"].nil?
      errors.add(:data, "goals[#{i}].unit is required")     if goal["unit"].blank?
    end
  end

  def validate_agent_activity
    return errors.add(:data, "must be an array") unless data.is_a?(Array)
    data.each_with_index do |activity, i|
      errors.add(:data, "activities[#{i}].text is required")      if activity["text"].blank?
      errors.add(:data, "activities[#{i}].timestamp is required") if activity["timestamp"].blank?
    end
  end
end
