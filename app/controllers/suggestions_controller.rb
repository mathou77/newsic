class SuggestionsController < ApplicationController
  def index
  end

  def create
    suggestion = Suggestion.create!(user: current_user)

    spotify = SpotifyService.new(session[:access_token])
    lastfm  = LastfmService.new
    deezer  = DeezerService.new

    top_tracks = spotify.top_tracks(limit: 5)

    raw_tracks = top_tracks.flat_map do |track|
      artist = track.dig("artists", 0, "name")
      title  = track["name"]
      lastfm.similar_tracks(artist: artist, track: title, limit: 10)
    end.uniq { |t| t["name"] }.shuffle

    raw_tracks.each do |track|
      artist = track.dig("artist", "name")
      title  = track["name"]

      result = deezer.search_track(artist: artist, title: title)
      next unless result && result["preview"].present?

      song = Song.find_or_create_by(deezer_id: result["id"]) do |s|
        s.title       = title
        s.artist      = artist
        s.preview_url = result["preview"]
        s.image_url   = result.dig("album", "cover_big")
      end

      suggestion.playlists.create!(song: song, status: :pending)
    end

    redirect_to suggestion_path(suggestion)
  end

  def show
    @suggestion = Suggestion.find(params[:id])
    @current_song = @suggestion.playlists.pending.first
    return unless @current_song

    song = @current_song.song
    fresh = DeezerService.new.fresh_preview_url(song.deezer_id)
    song.update(preview_url: fresh) if fresh && fresh != song.preview_url
  end

  def recap
    @suggestion = Suggestion.find(params[:id])
    @liked_playlists = @suggestion.playlists.liked
  end
end
