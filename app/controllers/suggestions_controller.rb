class SuggestionsController < ApplicationController
  before_action :ensure_fresh_spotify_token

  def index
  end

  def create
    filters    = filter_params
    suggestion = Suggestion.create!(user: current_user, mood: filters[:mood])
    session[:last_filters] = filters

    RecommendationEngine.new(
      access_token: session[:access_token],
      filters:      filters,
      user:         current_user
    ).build(suggestion)

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
    suggestion = Suggestion.find(params[:id])
    spotify    = SpotifyService.new(session[:access_token])
    playlists  = suggestion.playlists.liked.includes(:song)

    spotify_ids = playlists.filter_map do |p|
      song = p.song
      # Utilise l'ID déjà connu, sinon cherche sur Spotify par artiste + titre
      id = song.spotify_id.presence || spotify.search_track_id(artist: song.artist, title: song.title)
      # Met en cache pour ne pas re-chercher la prochaine fois
      song.update_column(:spotify_id, id) if id && song.spotify_id.blank?
      id
    end

    if spotify_ids.any?
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
      time_range:   TIME_RANGES.include?(params[:time_range]) ? params[:time_range] : "long_term",
      count:        (params[:count].presence || 10).to_i.clamp(5, 50),
      decade:       params[:decade].presence,
      tempo:        TEMPOS.include?(params[:tempo]) ? params[:tempo] : nil,
      diverse:       params[:diverse].present?,
      discovery:     params[:discovery].present?,
      exclude_liked: true,
      seed_artists: clean_seeds(params[:seed_artists]),
      seed_tracks:  clean_seeds(params[:seed_tracks])
    }
  end

  # Accepts an array of strings, drops blanks/dupes, caps the count.
  def clean_seeds(raw)
    Array(raw).map { |s| s.to_s.strip }.reject(&:blank?).uniq.first(MAX_SEEDS)
  end
end
