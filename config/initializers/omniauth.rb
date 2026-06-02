OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.on_failure = Proc.new { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :spotify,
    Rails.application.credentials.spotify[:client_id],
    Rails.application.credentials.spotify[:client_secret],
    scope: 'user-read-email user-top-read',
    callback_url: ENV.fetch("SPOTIFY_CALLBACK_URL", "http://localhost:3000/auth/spotify/callback")
end
