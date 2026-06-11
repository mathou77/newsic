class AddDominantColorToSongs < ActiveRecord::Migration[8.1]
  def change
    add_column :songs, :dominant_color, :string
  end
end
