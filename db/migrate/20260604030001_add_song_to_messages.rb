class AddSongToMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :messages, :song, null: true, foreign_key: true
    # A message can now carry a shared track instead of (or with) text.
    change_column_null :messages, :body, true
  end
end
