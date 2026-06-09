class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :user,       null: false, foreign_key: true
      t.references :actor,      null: false, foreign_key: { to_table: :users }
      t.references :notifiable, polymorphic: true
      t.integer    :kind,       null: false, default: 0
      t.bigint     :conversation_id  # groups message/reaction notifs by conversation
      t.datetime   :read_at
      t.timestamps
    end

    add_index :notifications, [:user_id, :read_at]
    add_index :notifications, :conversation_id
  end
end
