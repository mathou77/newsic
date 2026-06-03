class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def ensure_fresh_spotify_token
    return unless session[:token_expires_at]
    if Time.now.to_i >= session[:token_expires_at].to_i - 60
      new_token = SpotifyService.refresh_token(session[:refresh_token])
      session[:access_token] = new_token if new_token
    end
  end
end
