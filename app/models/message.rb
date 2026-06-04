class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user

  validates :body, presence: true

  # Real-time delivery: append the rendered message to every subscriber of
  # this conversation's Turbo stream as soon as it is committed.
  after_create_commit do
    broadcast_append_to(
      conversation,
      target: "messages",
      partial: "messages/message",
      locals: { message: self }
    )
  end

  def sender?(other_user)
    user_id == other_user.id
  end
end
