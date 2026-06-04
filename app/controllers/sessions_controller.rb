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

    capture_tastes(user, session[:access_token])

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

  # Snapshot the user's top artists/genres so profiles can show tastes even
  # for users who aren't the one currently logged in. Best-effort: never block
  # login if Spotify is slow or errors.
  def capture_tastes(user, token)
    return if token.blank?

    artists = SpotifyService.new(token).top_artists(limit: 20)
    return if artists.blank?

    user.update(
      top_artists: artists.first(8).map { |a| a["name"] }.compact,
      top_genres:  artists.flat_map { |a| a["genres"] || [] }
                          .tally.sort_by { |_g, n| -n }.first(6).map(&:first)
    )
  rescue => e
    Rails.logger.warn("capture_tastes failed: #{e.message}")
  end
end
