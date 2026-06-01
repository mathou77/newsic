class CreateSongs < ActiveRecord::Migration[8.1]
  def change
    create_table :songs do |t|
      t.string :title
      t.string :artist
      t.string :genre

      t.timestamps
    end
  end
end
