class AddSpotifyPlaylistIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :spotify_playlist_id, :string
  end
end
