class SharesController < ApplicationController
  # Shares a song into the conversations of one or more friends.
  def create
    song       = Song.find(params[:song_id])
    friend_ids = Array(params[:friend_ids]).map(&:to_i)
    body       = params[:body].presence

    sent = 0
    friend_ids.each do |fid|
      friend = User.find_by(id: fid)
      next unless friend && current_user.friends?(friend)

      conversation = Conversation.between(current_user, friend)
      conversation.messages.create!(user: current_user, body: body)       if body
      conversation.messages.create!(user: current_user, song: song)
      sent += 1
    end

    render json: { ok: true, sent: sent }
  end
end
