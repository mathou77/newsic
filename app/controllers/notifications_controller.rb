class NotificationsController < ApplicationController
  before_action :set_notification, only: [:accept, :decline, :reply, :mark_read]

  def mark_read
    @notification.read!
    render turbo_stream: turbo_stream.remove("toast_#{@notification.id}")
  end

  def accept
    friendship = @notification.notifiable
    unless friendship.is_a?(Friendship) && friendship.addressee == current_user
      head :forbidden and return
    end

    friendship.update!(status: :accepted)
    Conversation.between(friendship.requester, friendship.addressee)
    @notification.read!

    render turbo_stream: [
      turbo_stream.remove("toast_#{@notification.id}"),
      turbo_stream.replace("notification_badge",
        partial: "notifications/badge",
        locals: { count: Notification.badge_count_for(current_user) })
    ]
  end

  def decline
    friendship = @notification.notifiable
    unless friendship.is_a?(Friendship) && friendship.addressee == current_user
      head :forbidden and return
    end

    friendship.destroy!
    @notification.read!

    render turbo_stream: [
      turbo_stream.remove("toast_#{@notification.id}"),
      turbo_stream.replace("notification_badge",
        partial: "notifications/badge",
        locals: { count: Notification.badge_count_for(current_user) })
    ]
  end

  def reply
    body = params[:body].to_s.strip
    head :unprocessable_entity and return if body.blank?

    conversation = Conversation.find(@notification.conversation_id)
    head :forbidden and return unless conversation.includes_user?(current_user)

    conversation.messages.create!(user: current_user, body: body)
    @notification.read!

    render turbo_stream: turbo_stream.remove("toast_#{@notification.id}")
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end
end
