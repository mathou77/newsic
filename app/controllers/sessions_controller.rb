class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :destroy, :failure]
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)

    session[:user_id]          = user.id
    session[:display_name]     = user.display_name
    session[:access_token]     = auth['credentials']['token']
    session[:refresh_token]    = auth['credentials']['refresh_token']
    session[:token_expires_at] = auth['credentials']['expires_at']

    sync_spotify_profile(user, session[:access_token])

    redirect_to suggestions_path, notice: "Connecté en tant que #{user.display_name}"
  end

  def destroy
    session.clear
    redirect_to root_path, notice: "Déconnecté"
  end

  def failure
    redirect_to root_path, alert: "Échec de la connexion Spotify"
  end

  private

  # Snapshots top artists, top genres, and top tracks from Spotify so they're
  # available immediately on every page without a live API call. Best-effort:
  # never blocks login if Spotify is slow or errors.
  def sync_spotify_profile(user, token)
    return if token.blank?

    spotify = SpotifyService.new(token)
    artists = spotify.top_artists(limit: 20)
    return if artists.blank?

    top_tracks = spotify.top_tracks(limit: 50) rescue []

    user.update(
      top_artists:               artists.first(8).map { |a|
                                   { "name" => a["name"], "image" => a.dig("images", 1, "url") || a.dig("images", 0, "url") }
                                 }.compact,
      top_genres:                artists.flat_map { |a| a["genres"] || [] }
                                        .tally.sort_by { |_g, n| -n }.first(6).map(&:first),
      top_tracks:                top_tracks,
      spotify_cache_refreshed_at: Time.current
    )
  rescue => e
    Rails.logger.warn("sync_spotify_profile failed: #{e.message}")
  end
end
