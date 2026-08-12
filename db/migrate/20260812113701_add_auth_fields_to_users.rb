class AddAuthFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :email_address, :string
    add_column :users, :password_digest, :string

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE users
          SET email_address = 'admin@daybreak.local'
          WHERE email_address IS NULL
        SQL
        execute <<~SQL
          UPDATE users
          SET password_digest = 'PLACEHOLDER_RESET_REQUIRED'
          WHERE password_digest IS NULL
        SQL
      end
    end

    change_column_null :users, :email_address, false
    change_column_null :users, :password_digest, false
    add_index :users, :email_address, unique: true
  end
end
