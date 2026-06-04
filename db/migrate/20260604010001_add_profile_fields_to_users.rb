class AddProfileFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :avatar_url, :string
    add_column :users, :top_artists, :jsonb, default: [], null: false
    add_column :users, :top_genres, :jsonb, default: [], null: false
  end
end
