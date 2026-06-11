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
      # Render the sender's own bubble straight back in the HTTP response so it
      # appears instantly — no waiting on the WebSocket round-trip. The form is
      # cleared client-side (chat#resetForm) to keep the input focused.
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "messages",
            partial: "messages/message",
            locals: { message: @message }
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
