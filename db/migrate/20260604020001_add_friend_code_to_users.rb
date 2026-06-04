class AddFriendCodeToUsers < ActiveRecord::Migration[8.1]
  # Unambiguous alphabet (no O/0/I/1/L) for human-shareable codes.
  ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789".chars

  def up
    add_column :users, :friend_code, :string

    taken = select_values("SELECT friend_code FROM users WHERE friend_code IS NOT NULL").to_set
    select_values("SELECT id FROM users").each do |id|
      code = loop do
        candidate = Array.new(6) { ALPHABET.sample }.join
        break candidate unless taken.include?(candidate)
      end
      taken << code
      execute("UPDATE users SET friend_code = #{quote(code)} WHERE id = #{id.to_i}")
    end

    change_column_null :users, :friend_code, false
    add_index :users, :friend_code, unique: true
  end

  def down
    remove_column :users, :friend_code
  end
end
