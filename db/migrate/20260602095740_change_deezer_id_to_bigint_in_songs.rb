class ChangeDeezerIdToBigintInSongs < ActiveRecord::Migration[8.1]
  def up
    change_column :songs, :deezer_id, :bigint
  end

  def down
    change_column :songs, :deezer_id, :integer
  end
end
