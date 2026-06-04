class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :user1, null: false, foreign_key: { to_table: :users }
      t.references :user2, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    # Canonical pair (user1_id < user2_id) → one conversation per pair.
    add_index :conversations, [:user1_id, :user2_id], unique: true
  end
end
