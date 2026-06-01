class CreateSongsSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :songs_suggestions do |t|
      t.references :suggestion, null: false, foreign_key: true
      t.references :song, null: false, foreign_key: true

      t.timestamps
    end
  end
end
