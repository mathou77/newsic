class FriendshipsController < ApplicationController
  # Send a friend request.
  def create
    addressee = User.find(params[:addressee_id])

    if current_user.friendship_with(addressee)
      redirect_back fallback_location: user_path(addressee), alert: "Demande déjà existante."
      return
    end

    Friendship.create!(requester: current_user, addressee: addressee, status: :pending)
    redirect_back fallback_location: user_path(addressee), notice: "Demande d'ami envoyée !"
  end

  # Accept a received request.
  def update
    friendship = current_user.received_friendships.pending.find(params[:id])
    friendship.update!(status: :accepted)
    Conversation.between(friendship.requester, friendship.addressee)
    redirect_back fallback_location: conversations_path, notice: "Vous êtes maintenant amis !"
  end

  # Decline a request or remove an existing friend.
  def destroy
    friendship = Friendship.where(
      "requester_id = :me OR addressee_id = :me", me: current_user.id
    ).find(params[:id])
    friendship.destroy!
    redirect_back fallback_location: users_path, notice: "Demande retirée."
  end
end
