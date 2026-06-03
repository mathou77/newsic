class SuggestionsController < ApplicationController
  before_action :ensure_fresh_spotify_token

  def index
  end

  def create
    suggestion = Suggestion.create!(user: current_user)

    spotify = SpotifyService.new(session[:access_token])
    Rails.logger.info "=== SPOTIFY TOKEN: #{session[:access_token].present? ? 'présent' : 'MANQUANT'} ==="
    lastfm  = LastfmService.new
    deezer  = DeezerService.new

    top_tracks = spotify.top_tracks(limit: 50)

    # Appels Last.fm en parallèle (x10 plus rapide)
    mutex      = Mutex.new
    raw_tracks = []

    threads = top_tracks.map do |track|
      Thread.new do
        artist  = track.dig("artists", 0, "name")
        title   = track["name"]
        similar = lastfm.similar_tracks(artist: artist, track: title, limit: 10)
        mutex.synchronize { raw_tracks.concat(similar) }
      end
    end
    threads.each(&:join)

    raw_tracks = raw_tracks.uniq { |t| t["name"] }.shuffle

    # Appels Deezer en parallèle par batch de 10
    playlist_mutex = Mutex.new
    count          = 0

    raw_tracks.each_slice(10) do |batch|
      break if count >= 50

      slice_threads = batch.map do |track|
        Thread.new do
          next if count >= 50

          artist = track.dig("artist", "name")
          title  = track["name"]
          result = deezer.search_track(artist: artist, title: title)
          next unless result && result["preview"].present?

          playlist_mutex.synchronize do
            next if count >= 50

            # find_or_initialize + save pour toujours mettre à jour l'URL (qui expire)
            song = Song.find_or_initialize_by(deezer_id: result["id"])
            song.title       = title
            song.artist      = artist
            song.preview_url = result["preview"]
            song.image_url   = result.dig("album", "cover_big")
            song.spotify_id = spotify.search_track_id(artist: artist, title: title) if song.spotify_id.blank?
            song.save!

            suggestion.playlists.create!(song: song, status: :pending)
            count += 1
          end
        end
      end
      slice_threads.each(&:join)
    end

    redirect_to suggestion_path(suggestion)
  end

  def show
    @suggestion = Suggestion.find(params[:id])
    @playlists  = @suggestion.playlists.pending.includes(:song).limit(10)
  end

  def recap
    @suggestion = Suggestion.find(params[:id])
    @liked_playlists = @suggestion.playlists.liked
  end

  def save_to_spotify
    suggestion   = Suggestion.find(params[:id])
    spotify_ids  = suggestion.playlists.liked.includes(:song).filter_map { |p| p.song.spotify_id }

    if spotify_ids.any?
      spotify     = SpotifyService.new(session[:access_token])
      playlist_id = spotify.find_or_create_playlist(existing_id: session[:newsic_playlist_id])
      session[:newsic_playlist_id] = playlist_id

      spotify.follow_playlist(playlist_id)
      spotify_ids.each_slice(100) { |batch| spotify.add_tracks_to_playlist(playlist_id: playlist_id, ids: batch) }
    end

    redirect_to recap_suggestion_path(suggestion), notice: "#{spotify_ids.count} titre(s) ajouté(s) à ta playlist Newsic sur Spotify !"
  end

end
