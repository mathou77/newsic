class PushSubscriptionsController < ApplicationController
  def create
    sub = params.require(:subscription)
    current_user.push_subscriptions.find_or_create_by!(endpoint: sub[:endpoint]) do |s|
      s.p256dh = sub.dig(:keys, :p256dh)
      s.auth   = sub.dig(:keys, :auth)
    end
    head :created
  end

  def destroy
    current_user.push_subscriptions.find_by(endpoint: params[:endpoint])&.destroy
    head :no_content
  end
end
