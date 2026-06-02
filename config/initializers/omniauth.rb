OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
OmniAuth.config.on_failure = Proc.new { |env| OmniAuth::FailureEndpoint.new(env).redirect_to_failure }

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :spotify,
    ENV.fetch("SPOTIFY_CLIENT_ID"),
    ENV.fetch("SPOTIFY_CLIENT_SECRET"),
    scope: 'user-read-email user-top-read',
    callback_path: '/auth/spotify/callback'
end
