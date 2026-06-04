class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  helper_method :current_user, :user_signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    redirect_to root_path, alert: "Connecte-toi avec Spotify pour continuer." unless user_signed_in?
  end

  def ensure_fresh_spotify_token
    return unless session[:token_expires_at]
    if Time.now.to_i >= session[:token_expires_at].to_i - 60
      new_token = SpotifyService.refresh_token(session[:refresh_token])
      session[:access_token] = new_token if new_token
    end
  end
end
