class UsersController < ApplicationController
  # Directory of people to befriend.
  def index
    @users = User.where.not(id: current_user.id).order(:display_name)
    @users = @users.where("display_name ILIKE ?", "%#{params[:q]}%") if params[:q].present?
  end

  def show
    @user = User.find(params[:id])
    redirect_to(profile_path) and return if @user == current_user

    @friendship = current_user.friendship_with(@user)
  end
end
