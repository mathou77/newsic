class Conversation < ApplicationRecord
  belongs_to :user1, class_name: "User"
  belongs_to :user2, class_name: "User"
  has_many :messages, -> { order(:created_at) }, dependent: :destroy

  # Finds (or creates) the single conversation between two users.
  # Stores the pair canonically with user1_id < user2_id.
  def self.between(a, b)
    low, high = [a.id, b.id].minmax
    find_or_create_by!(user1_id: low, user2_id: high)
  end

  def participants
    [user1, user2]
  end

  def includes_user?(user)
    user1_id == user.id || user2_id == user.id
  end

  def other_than(user)
    user1_id == user.id ? user2 : user1
  end

  def last_message
    messages.last
  end
end
