class AddColumnsToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :preview_url, :string
    add_column :songs, :image_url, :string
    add_column :songs, :deezer_id, :integer
    add_column :songs, :spotify_uri, :string
  end
end
