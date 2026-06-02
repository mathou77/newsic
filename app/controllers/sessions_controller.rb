class SessionsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:create, :destroy, :failure]
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    auth = request.env['omniauth.auth']

    session[:user_id]      = auth['uid']
    session[:display_name] = auth['info']['name']
    session[:access_token] = auth['credentials']['token']

    redirect_to suggestions_path, notice: "Connecté en tant que #{auth['info']['name']}"
  end

  def destroy
    session.clear
    redirect_to root_path, notice: "Déconnecté"
  end

  def failure
    redirect_to root_path, alert: "Échec de la connexion Spotify"
  end
end
