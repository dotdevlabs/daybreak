class CreateAgentEndpoints < ActiveRecord::Migration[8.1]
  def change
    create_table :agent_endpoints do |t|
      t.string :callback_url, null: false

      t.timestamps
    end
  end
end
