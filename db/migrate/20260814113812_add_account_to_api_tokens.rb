class AddAccountToApiTokens < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM api_tokens"
    add_reference :api_tokens, :account, null: false, foreign_key: true
  end

  def down
    remove_reference :api_tokens, :account, foreign_key: true
  end
end
