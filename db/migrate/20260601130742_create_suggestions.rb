class CreateSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :suggestions do |t|
      t.timestamps
    end
  end
end
