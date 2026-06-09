class MessageReaction < ApplicationRecord
  belongs_to :message
  belongs_to :user

  EMOJIS = %w[❤️ 🔥 🤯].freeze

  validates :emoji, presence: true, inclusion: { in: EMOJIS }
  validates :user_id, uniqueness: { scope: [:message_id, :emoji] }

  after_create_commit :notify_message_author

  private

  def notify_message_author
    recipient = message.user
    return if recipient == user  # don't notify yourself

    Notification.create!(
      user:            recipient,
      actor:           user,
      notifiable:      self,
      kind:            :reaction,
      conversation_id: message.conversation_id
    )
  rescue => e
    Rails.logger.warn("Reaction notification failed: #{e.message}")
  end
end
