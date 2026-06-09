class ConversationsController < ApplicationController
  before_action :set_conversation, only: :show

  def index
    ids = Conversation.where("user1_id = :id OR user2_id = :id", id: current_user.id)
    @conversations = ids.includes(:messages).sort_by { |c| c.updated_at }.reverse
    @friends = current_user.friends
    @pending = current_user.pending_received.includes(:requester)
  end

  def show
    @messages = @conversation.messages.includes(:user)
    @other    = @conversation.other_than(current_user)
    @message  = Message.new

    # Mark all message/reaction notifications for this conversation as read.
    current_user.notifications.unread
                .where(conversation_id: @conversation.id)
                .find_each(&:read!)
  end

  # Start (or reopen) a conversation with a friend.
  def create
    other = User.find(params[:user_id])

    unless current_user.friends?(other)
      redirect_to user_path(other), alert: "Vous devez être amis pour discuter."
      return
    end

    conversation = Conversation.between(current_user, other)
    redirect_to conversation_path(conversation)
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:id])
    redirect_to(conversations_path, alert: "Accès refusé.") unless @conversation.includes_user?(current_user)
  end
end
