class AddStatusToPlaylists < ActiveRecord::Migration[8.1]
  def change
    add_column :playlists, :status, :integer
  end
end
