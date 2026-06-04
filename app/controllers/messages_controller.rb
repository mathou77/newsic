class MessagesController < ApplicationController
  def create
    conversation = Conversation.find(params[:conversation_id])

    unless conversation.includes_user?(current_user)
      head :forbidden
      return
    end

    @message = conversation.messages.build(message_params.merge(user: current_user))

    if @message.save
      # The sender's own append + broadcast to the other party both happen via
      # the model's after_create_commit Turbo broadcast. Just clear the form.
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace("message_form", partial: "messages/form", locals: { conversation: conversation, message: Message.new }) }
        format.html { redirect_to conversation_path(conversation) }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
