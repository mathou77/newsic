class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :kind, { message: 0, friend_request: 1, reaction: 2 }

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(30) }

  after_create_commit :deliver_notification

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

  def deliver_notification
    broadcast_toast
    broadcast_badge_update
    send_web_push
  end

  def broadcast_toast
    Turbo::StreamsChannel.broadcast_prepend_to(
      "notifications:#{user_id}",
      target:  "toast_container",
      partial: "notifications/toast",
      locals:  { notification: self }
    )
  end

  def broadcast_badge_update
    Turbo::StreamsChannel.broadcast_replace_to(
      "notifications:#{user_id}",
      target:  "notification_badge",
      partial: "notifications/badge",
      locals:  { count: Notification.badge_count_for(user) }
    )
  end

  def push_title
    case kind
    when "message"        then "Nouveau message de #{actor.display_name}"
    when "friend_request" then "#{actor.display_name} veut être ton ami"
    when "reaction"       then "#{actor.display_name} a réagi à ton message"
    end
  end

  def push_body
    case kind
    when "message"  then notifiable&.body.to_s.truncate(80)
    when "reaction" then notifiable&.emoji.to_s
    else ""
    end
  end

  def push_url
    case kind
    when "message", "reaction" then conversation_id ? "/conversations/#{conversation_id}" : "/conversations"
    when "friend_request"      then "/users"
    end
  end

  def send_web_push
    WebPushService.notify(user: user, title: push_title, body: push_body, url: push_url, tag: "newsic-#{kind}")
  end
end
