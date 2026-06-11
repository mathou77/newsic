class UsersController < ApplicationController
  # Directory of people to befriend.
  def index
    @users = User.where.not(id: current_user.id)
                 .where.not(spotify_uid: nil)
                 .order(:display_name)
    if params[:q].present?
      @users = @users.where(
        "display_name ILIKE :name OR friend_code = :code",
        name: "%#{params[:q].strip}%", code: User.normalize_code(params[:q])
      )
    end
  end

  def show
    @user = User.find(params[:id])
    redirect_to(profile_path) and return if @user == current_user

    @friendship     = current_user.friendship_with(@user)
    @playlist_count = @user.suggestions.count
    @friend_count   = @user.friends.count
    @friends        = @user.friends.order(:display_name)

    enrich_artist_images(@user) if @user.artist_cards.any? { |a| a["image"].blank? }
  end

  private

  # Fetches missing artist images from Deezer and saves them to the user record.
  # Only runs once per user (until all images are present).
  def enrich_artist_images(user)
    deezer = DeezerService.new
    enriched = user.artist_cards.map do |a|
      next a if a["image"].present?
      info = deezer.artist_info(a["name"])
      a.merge("image" => info&.dig("image"))
    end
    user.update_columns(top_artists: enriched)
  rescue => e
    Rails.logger.warn("enrich_artist_images failed: #{e.message}")
  end
end
