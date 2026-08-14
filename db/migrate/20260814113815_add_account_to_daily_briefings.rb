class AddAccountToDailyBriefings < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM daily_briefings"
    remove_index :daily_briefings, :date
    add_reference :daily_briefings, :account, null: false, foreign_key: true
    add_index :daily_briefings, [ :account_id, :date ], unique: true
  end

  def down
    remove_index :daily_briefings, [ :account_id, :date ]
    remove_reference :daily_briefings, :account, foreign_key: true
    add_index :daily_briefings, :date, unique: true
  end
end
