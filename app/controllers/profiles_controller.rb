class ProfilesController < ApplicationController
  before_action :ensure_fresh_spotify_token

  def show
    @user = current_user

    # Tastes are stored at login; fall back to a live fetch if empty.
    if @user.top_genres.blank? && session[:access_token].present?
      refresh_tastes(@user)
    end

    @playlist_count = @user.suggestions.count
    @friend_count   = @user.friends.count
    @friends        = @user.friends.order(:display_name)
  end

  private

  def refresh_tastes(user)
    artists = SpotifyService.new(session[:access_token]).top_artists(limit: 20)
    return if artists.blank?

    user.update(
      top_artists: artists.first(8).map { |a|
                     { "name" => a["name"], "image" => a.dig("images", 1, "url") || a.dig("images", 0, "url") }
                   }.compact,
      top_genres:  artists.flat_map { |a| a["genres"] || [] }
                          .tally.sort_by { |_g, n| -n }.first(6).map(&:first)
    )
  end
end
