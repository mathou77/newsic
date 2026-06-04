class ReplaceDeviseWithSpotifyOnUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :spotify_uid, :string
    add_column :users, :display_name, :string
    add_index  :users, :spotify_uid, unique: true

    remove_column :users, :encrypted_password
    remove_column :users, :reset_password_token
    remove_column :users, :reset_password_sent_at
    remove_column :users, :remember_created_at

    change_column_default :users, :email, nil
    change_column_null    :users, :email, true
    remove_index :users, :email if index_exists?(:users, :email)
  end

  def down
    add_index :users, :email, unique: true
    change_column_null    :users, :email, false
    change_column_default :users, :email, ""

    add_column :users, :remember_created_at, :datetime
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :reset_password_token, :string
    add_index  :users, :reset_password_token, unique: true
    add_column :users, :encrypted_password, :string, null: false, default: ""

    remove_index  :users, :spotify_uid
    remove_column :users, :display_name
    remove_column :users, :spotify_uid
  end
end
