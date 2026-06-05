class MessageReactionsController < ApplicationController
  # Toggles an emoji reaction on a message and broadcasts the updated counter.
  def create
    message = Message.find(params[:message_id])

    unless message.conversation.includes_user?(current_user)
      head :forbidden
      return
    end

    emoji    = params[:emoji]
    reaction = message.message_reactions.find_by(user: current_user, emoji: emoji)

    if reaction
      reaction.destroy
    else
      message.message_reactions.create(user: current_user, emoji: emoji)
    end

    # Update the counter for everyone in the conversation (incl. the actor).
    Turbo::StreamsChannel.broadcast_replace_to(
      message.conversation,
      target:  "reactions_#{message.id}",
      partial: "messages/reactions",
      locals:  { message: message }
    )

    head :ok
  end
end
