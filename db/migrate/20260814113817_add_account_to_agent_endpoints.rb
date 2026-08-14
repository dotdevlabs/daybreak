class AddAccountToAgentEndpoints < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM agent_endpoints"
    add_reference :agent_endpoints, :account, null: false, foreign_key: true
  end

  def down
    remove_reference :agent_endpoints, :account, foreign_key: true
  end
end
