class SpotifyService
  BASE_URL = "https://api.spotify.com/v1"

  def initialize(access_token)
    @access_token = access_token
  end

  def top_tracks(limit: 20, time_range: "medium_term")
    response = HTTParty.get("#{BASE_URL}/me/top/tracks", {
      headers: { "Authorization" => "Bearer #{@access_token}" },
      query: {
        limit: limit,
        time_range: time_range
      }
    })
    response.dig("items") || []
  end

  def top_artists(limit: 20, time_range: "medium_term")
    response = HTTParty.get("#{BASE_URL}/me/top/artists", {
      headers: { "Authorization" => "Bearer #{@access_token}" },
      query: {
        limit: limit,
        time_range: time_range
      }
    })
    response.dig("items") || []
  end

  def search_track_id(artist:, title:)
    response = HTTParty.get("#{BASE_URL}/search", {
    headers: { "Authorization" => "Bearer #{@access_token}" },
    query: { q: "artist:#{artist} track:#{title}", type: "track", limit: 1 }
  })
  response.dig("tracks", "items", 0, "id")
  end

  def find_or_create_playlist(existing_id: nil, name: "Newsic")
    return existing_id if existing_id.present?
    create_playlist(name: name)
  end

  def follow_playlist(playlist_id)
    HTTParty.put("#{BASE_URL}/playlists/#{playlist_id}/followers",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type"  => "application/json"
      },
      body: { public: false }.to_json
    )
  end

  def create_playlist(name: "Newsic")
    response = HTTParty.post("#{BASE_URL}/me/playlists",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type"  => "application/json"
      },
      body: { name: name, public: false, description: "Générée par Newsic 🎵" }.to_json
    )
    response["id"]
  end

  def add_tracks_to_playlist(playlist_id:, ids:)
    uris = ids.map { |id| "spotify:track:#{id}" }
    HTTParty.post(
      "#{BASE_URL}/playlists/#{playlist_id}/items",
      headers: { "Authorization" => "Bearer #{@access_token}" },
      query:   { uris: uris.join(",") }
    )
  end

  def self.refresh_token(refresh_token)
    response = HTTParty.post("https://accounts.spotify.com/api/token", {
      body: {
        grant_type:    "refresh_token",
        refresh_token: refresh_token,
        client_id:     ENV.fetch("SPOTIFY_CLIENT_ID"),
        client_secret: ENV.fetch("SPOTIFY_CLIENT_SECRET")
      }
    })
    response["access_token"]
  end

  def save_tracks(ids:)
      HTTParty.put("#{BASE_URL}/me/tracks",
    headers: {
      "Authorization" => "Bearer #{@access_token}",
      "Content-Type"  => "application/json"
    },
    body: { ids: ids }.to_json
  )
  end


end
