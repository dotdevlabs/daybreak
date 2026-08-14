class AddAccountToUsers < ActiveRecord::Migration[8.1]
  def up
    add_reference :users, :account, null: true, foreign_key: true
    execute <<~SQL
      INSERT INTO accounts (created_at, updated_at)
      SELECT created_at, created_at FROM users;

      UPDATE users u
      SET account_id = a.id
      FROM (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM accounts
      ) a
      JOIN (
        SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn FROM users
      ) u2 ON a.rn = u2.rn
      WHERE u.id = u2.id;
    SQL
    change_column_null :users, :account_id, false
  end

  def down
    remove_reference :users, :account, foreign_key: true
  end
end
