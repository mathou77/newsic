class SuggestionsController < ApplicationController
  def index
    @moods = LastfmService::MOOD_TAGS.keys
  end

  def create
    mood = params[:mood] || "chill"
    suggestion = Suggestion.create!(user: current_user, mood: mood)

    lastfm = LastfmService.new
    deezer = DeezerService.new

    raw_tracks = lastfm.tracks_by_mood(mood)

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
  end

  def recap
    @suggestion = Suggestion.find(params[:id])
    @liked_playlists = @suggestion.playlists.liked
  end
end
