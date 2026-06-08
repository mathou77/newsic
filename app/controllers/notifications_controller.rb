class NotificationsController < ApplicationController
  before_action :set_notification, only: [:accept, :decline, :reply, :mark_read]

  # Mark one notification as read.
  def mark_read
    @notification.read!
    render turbo_stream: turbo_stream.remove("notification_#{@notification.id}")
  end

  # Accept a friend request directly from the notification panel.
  def accept
    friendship = @notification.notifiable
    unless friendship.is_a?(Friendship) && friendship.addressee == current_user
      head :forbidden and return
    end

    friendship.update!(status: :accepted)
    Conversation.between(friendship.requester, friendship.addressee)
    @notification.read!

    render turbo_stream: [
      turbo_stream.remove("notification_#{@notification.id}"),
      turbo_stream.replace("notification_badge",
        partial: "notifications/badge",
        locals: { count: Notification.badge_count_for(current_user) })
    ]
  end

  # Decline a friend request directly from the notification panel.
  def decline
    friendship = @notification.notifiable
    unless friendship.is_a?(Friendship) && friendship.addressee == current_user
      head :forbidden and return
    end

    friendship.destroy!
    @notification.read!

    render turbo_stream: [
      turbo_stream.remove("notification_#{@notification.id}"),
      turbo_stream.replace("notification_badge",
        partial: "notifications/badge",
        locals: { count: Notification.badge_count_for(current_user) })
    ]
  end

  # Send a quick reply to a message notification without leaving the current page.
  def reply
    body = params[:body].to_s.strip
    head :unprocessable_entity and return if body.blank?

    conversation = Conversation.find(@notification.conversation_id)
    head :forbidden and return unless conversation.includes_user?(current_user)

    conversation.messages.create!(user: current_user, body: body)
    @notification.read!

    render turbo_stream: turbo_stream.replace(
      "notification_#{@notification.id}",
      partial: "notifications/replied",
      locals: { notification: @notification }
    )
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
