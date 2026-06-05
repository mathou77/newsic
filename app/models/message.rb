class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user
  belongs_to :song, optional: true

  has_many :message_reactions, dependent: :destroy

  validate :body_or_song_present

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

  def shared_track?
    song_id.present?
  end

  # { "🔥" => 2, "❤️" => 1 } for rendering the reaction counter.
  def reaction_summary
    message_reactions.group(:emoji).count
  end

  private

  def body_or_song_present
    errors.add(:base, "Message vide") if body.blank? && song_id.blank?
  end
end
