class MessagesController < ApplicationController
  def create
    conversation = Conversation.find(params[:conversation_id])

    unless conversation.includes_user?(current_user)
      head :forbidden
      return
    end

    @message = conversation.messages.build(user: current_user, body: message_params[:body])
    attach_song(@message)

    if @message.save
      # The bubble append + broadcast to the other party both happen via the
      # model's after_create_commit Turbo broadcast. Just reset the form here.
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "messages/form",
            locals: { conversation: conversation, message: Message.new }
          )
        end
        format.html { redirect_to conversation_path(conversation) }
      end
    else
      head :unprocessable_entity
    end
  end

  private

  # A message can carry: an existing song (song_id), or a track picked from a
  # Deezer search in the chat (track[artist] + track[title]).
  def attach_song(message)
    if params[:song_id].present?
      message.song = Song.find_by(id: params[:song_id])
    elsif params.dig(:track, :title).present?
      message.song = Song.from_deezer_search(
        artist: params.dig(:track, :artist),
        title:  params.dig(:track, :title)
      )
    end
  end

  def message_params
    params.fetch(:message, {}).permit(:body)
  end
end
