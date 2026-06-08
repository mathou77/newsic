OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.on_failure = Proc.new { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }

Rails.application.config.middleware.use OmniAuth::Builder do
  # SPOTIFY_CALLBACK_URL must be set to the base URL of the app so Spotify
  # knows where to redirect after auth. Required locally (ngrok or localhost)
  # since localhost is not always registered. On Heroku this should be the
  # app's HTTPS URL (e.g. https://my-app.herokuapp.com).
  base_url     = ENV["SPOTIFY_CALLBACK_URL"].presence
  redirect_uri = base_url && "#{base_url.delete_suffix('/')}/auth/spotify/callback"

  provider :spotify,
    ENV.fetch("SPOTIFY_CLIENT_ID"),
    ENV.fetch("SPOTIFY_CLIENT_SECRET"),
    scope: 'user-read-email user-top-read playlist-modify-private playlist-modify-public',
    callback_path: '/auth/spotify/callback',
    redirect_uri:  redirect_uri,
    show_dialog: true
end
