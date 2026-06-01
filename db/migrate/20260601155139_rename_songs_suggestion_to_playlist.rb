class RenameSongsSuggestionToPlaylist < ActiveRecord::Migration[8.1]
  def change
    rename_table :songs_suggestions, :playlists
  end
end
