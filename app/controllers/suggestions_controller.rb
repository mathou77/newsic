class SuggestionsController < ApplicationController
  before_action :ensure_fresh_spotify_token

  def index
  end

  def create
    filters    = filter_params
    suggestion = Suggestion.create!(user: current_user, mood: filters[:mood])
    session[:last_filters] = filters

    RecommendationEngine.new(access_token: session[:access_token], filters: filters).build(suggestion)

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

            song.title          = result["title"].presence || title
            song.artist         = result.dig("artist", "name").presence || artist
            song.preview_url    = result["preview"]
            song.image_url      = result.dig("album", "cover_big")
            song.album_name     = result.dig("album", "title")
            song.duration       = result["duration"]
            song.explicit       = result["explicit_lyrics"]
            song.rank           = result["rank"]
            song.artist_picture = result.dig("artist", "picture_medium")

            song.spotify_id = spotify.search_track_id(artist: artist, title: title) if song.spotify_id.blank?

            if song.release_date.blank?
              details = deezer.track(result["id"])
              song.release_date = details["release_date"]
            end

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
    @filters    = (session[:last_filters] || {}).with_indifferent_access
    count       = (@filters[:count].presence || 10).to_i
    @playlists  = @suggestion.playlists.pending.includes(:song).limit(count)
    @friends    = current_user.friends
  end

  def recap
    @suggestion = Suggestion.find(params[:id])
    @liked_playlists = @suggestion.playlists.liked
  end

  # Live autocomplete for the seed selector (Deezer search, no auth needed).
  def seed_search
    query  = params[:q].to_s.strip
    deezer = DeezerService.new
    if query.length < 2
      render json: { artists: [], tracks: [] }
    else
      render json: {
        artists: deezer.search_artists(query),
        tracks:  deezer.search_tracks(query)
      }
    end
  end

  def save_to_spotify
    suggestion   = Suggestion.find(params[:id])
    spotify_ids  = suggestion.playlists.liked.includes(:song).filter_map { |p| p.song.spotify_id }

    if spotify_ids.any?
      spotify     = SpotifyService.new(session[:access_token])
      existing_id = current_user.spotify_playlist_id.presence || session[:newsic_playlist_id].presence
      playlist_id = spotify.find_or_create_playlist(existing_id: existing_id)
      current_user.update_column(:spotify_playlist_id, playlist_id)
      session[:newsic_playlist_id] = playlist_id

      spotify.follow_playlist(playlist_id)
      spotify_ids.each_slice(100) { |batch| spotify.add_tracks_to_playlist(playlist_id: playlist_id, ids: batch) }
    end

    redirect_to recap_suggestion_path(suggestion), notice: "#{spotify_ids.count} titre(s) ajouté(s) à ta playlist Newsic sur Spotify !"
  end

  private

  TIME_RANGES = %w[short_term medium_term long_term].freeze
  POPULARITY  = %w[mainstream hidden].freeze
  TEMPOS      = %w[slow medium fast].freeze
  MAX_SEEDS   = 5

  def filter_params
    {
      mood:         params[:mood].presence,
      genre:        params[:genre].presence,
      time_range:   TIME_RANGES.include?(params[:time_range]) ? params[:time_range] : "medium_term",
      count:        (params[:count].presence || 10).to_i.clamp(5, 50),
      popularity:   POPULARITY.include?(params[:popularity]) ? params[:popularity] : nil,
      decade:       params[:decade].presence,
      tempo:        TEMPOS.include?(params[:tempo]) ? params[:tempo] : nil,
      clean_only:    params[:clean_only].present?,
      diverse:       params[:diverse].present?,
      discovery:     params[:discovery].present?,
      exclude_liked: params[:exclude_liked].present?,
      seed_artists: clean_seeds(params[:seed_artists]),
      seed_tracks:  clean_seeds(params[:seed_tracks])
    }
  end

  # Accepts an array of strings, drops blanks/dupes, caps the count.
  def clean_seeds(raw)
    Array(raw).map { |s| s.to_s.strip }.reject(&:blank?).uniq.first(MAX_SEEDS)
  end

end
