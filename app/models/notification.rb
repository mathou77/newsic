class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :kind, { message: 0, friend_request: 1, reaction: 2 }

  scope :unread,  -> { where(read_at: nil) }
  scope :recent,  -> { order(created_at: :desc).limit(30) }

  after_create_commit :broadcast_to_recipient

  # Badge = unread conversations (messages) + unread friend requests + unread reaction convos.
  def self.badge_count_for(user)
    base = where(user: user, read_at: nil)
    msg  = base.where(kind: :message).select(:conversation_id).distinct.count
    fr   = base.where(kind: :friend_request).count
    rx   = base.where(kind: :reaction).select(:conversation_id).distinct.count
    msg + fr + rx
  end

  def read!
    return if read_at?
    update_columns(read_at: Time.current)
    broadcast_badge_update
  end

  def unread?
    read_at.nil?
  end

  private

  def broadcast_to_recipient
    stream = "notifications:#{user_id}"

    Turbo::StreamsChannel.broadcast_prepend_to(
      stream,
      target:  "notifications_list",
      partial: "notifications/notification",
      locals:  { notification: self }
    )
    broadcast_badge_update
  end

  def broadcast_badge_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications:#{user_id}",
      target:  "notification_badge",
      partial: "notifications/badge",
      locals:  { count: Notification.badge_count_for(user) }
    )
  end
end
