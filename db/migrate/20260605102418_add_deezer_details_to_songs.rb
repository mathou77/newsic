class AddDeezerDetailsToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :album_name, :string
    add_column :songs, :release_date, :string
    add_column :songs, :duration, :integer
    add_column :songs, :explicit, :boolean
    add_column :songs, :rank, :integer
    add_column :songs, :artist_picture, :string
  end
end
