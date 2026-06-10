class ArtistsController < ApplicationController
  def show
    @artist_name = params[:name].to_s.strip
    redirect_to(root_path) and return if @artist_name.blank?

    deezer       = DeezerService.new
    @artist_info = deezer.artist_info(@artist_name)

    @liked_songs = Song.joins(:playlists => :suggestion)
                       .where(playlists: { status: :liked }, suggestions: { user_id: current_user.id })
                       .where("LOWER(songs.artist) = ?", @artist_name.downcase)
                       .distinct

    @recommended = deezer.artist_top_tracks(@artist_name)
  end
end
