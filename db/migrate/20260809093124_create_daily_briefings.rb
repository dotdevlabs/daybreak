class CreateDailyBriefings < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_briefings do |t|
      t.date   :date,                  null: false
      t.jsonb  :calendar_data,         null: false, default: {}
      t.jsonb  :weather_data,          null: false, default: {}
      t.jsonb  :daily_goals_data,      null: false, default: {}
      t.jsonb  :action_items_data,     null: false, default: {}
      t.jsonb  :long_term_goals_data,  null: false, default: []
      t.jsonb  :agent_activity_data,   null: false, default: []
      t.timestamps
    end

    add_index :daily_briefings, :date, unique: true
  end
end
