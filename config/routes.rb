Rails.application.routes.draw do
  root to: "pages#home"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  resources :suggestions, only: [:index, :show, :create] do
    collection { get :seed_search }
    member do
      get  :recap
      post :save_to_spotify
    end
    resources :playlists, only: [] do
      member { patch :vote }
    end
  end
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check


  get '/auth/spotify/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  delete '/logout', to: 'sessions#destroy'

  # Social: profile, friends, real-time DMs
  get "profile", to: "profiles#show", as: :profile
  resources :users, only: [:index, :show]
  resources :friendships, only: [:create, :update, :destroy]
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]
  end


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
