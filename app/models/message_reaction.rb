class MessageReaction < ApplicationRecord
  belongs_to :message
  belongs_to :user

  EMOJIS = %w[❤️ 🔥 🤯].freeze

  validates :emoji, presence: true, inclusion: { in: EMOJIS }
  validates :user_id, uniqueness: { scope: [:message_id, :emoji] }
end
