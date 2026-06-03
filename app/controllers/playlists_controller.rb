class PlaylistsController < ApplicationController
  skip_before_action :authenticate_user!

  def vote
    playlist = Playlist.find(params[:id])
    playlist.update!(status: params[:status])
    render json: { ok: true }
  end
end
