class AddWebauthnFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :webauthn_id, :string
    add_column :users, :verified_at, :datetime

    reversible do |dir|
      dir.up do
        require "securerandom"
        require "base64"
        User.find_each do |user|
          user.update_columns(
            webauthn_id: Base64.urlsafe_encode64(SecureRandom.random_bytes(16), padding: false),
            verified_at: user.created_at || Time.current
          )
        end
      end
    end

    change_column_null :users, :webauthn_id, false
    add_index :users, :webauthn_id, unique: true
  end
end
