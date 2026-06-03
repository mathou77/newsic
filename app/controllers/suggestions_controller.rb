class SuggestionsController < ApplicationController
  def index
  end

  def create
    filters    = filter_params
    suggestion = Suggestion.create!(user: current_user, mood: filters[:mood])
    session[:last_filters] = filters

    RecommendationEngine.new(access_token: session[:access_token], filters: filters).build(suggestion)

    redirect_to suggestion_path(suggestion)
  end

  def show
    @suggestion = Suggestion.find(params[:id])
    @filters    = (session[:last_filters] || {}).with_indifferent_access
    @playlists  = @suggestion.playlists.pending.includes(:song)
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
      count:        (params[:count].presence || 50).to_i.clamp(5, 50),
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
