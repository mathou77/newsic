class AddSpotifyCacheToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :top_tracks, :jsonb, default: [], null: false
    add_column :users, :spotify_cache_refreshed_at, :datetime
  end
end
