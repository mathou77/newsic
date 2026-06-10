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
  end
end
