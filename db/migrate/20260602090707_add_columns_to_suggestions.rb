class AddColumnsToSuggestions < ActiveRecord::Migration[8.1]
  def change
    add_reference :suggestions, :user, null: false, foreign_key: true
    add_column :suggestions, :mood, :string
  end
end
