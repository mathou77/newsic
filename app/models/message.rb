class Message < ApplicationRecord
  belongs_to :conversation, touch: true
  belongs_to :user
  belongs_to :song, optional: true

  has_many :message_reactions, dependent: :destroy

  validate :body_or_song_present

  # Real-time delivery: append the rendered message to every subscriber of
  # this conversation's Turbo stream as soon as it is committed.
  after_create_commit do
    recipient = conversation.other_than(user)
    if recipient
      broadcast_append_to(
        "user_#{recipient.id}_messages",
        target: "messages",
        partial: "messages/message",
        locals: { message: self }
      )
    end
    notify_recipient
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

  def notify_recipient
    recipient = conversation.other_than(user)
    return unless recipient

    Notification.create!(
      user:            recipient,
      actor:           user,
      notifiable:      self,
      kind:            :message,
      conversation_id: conversation_id
    )
  rescue => e
    Rails.logger.warn("Message notification failed: #{e.message}")
  end
end
