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

  # Normalized "artist|title" keys of the user's liked songs, for the
  # "don't replay what I already liked" filter. Requires user-library-read.
  # Paginates /me/tracks (50/page) up to `max_pages` to bound the cost.
  def liked_track_keys(max_pages: 20)
    keys = Set.new

    max_pages.times do |page|
      items = liked_tracks_page(page * 50)
      break if items.empty?

      items.each { |item| add_track_key(keys, item["track"]) }
      break if items.size < 50
    end

    keys
  end

  def playlist_exists?(playlist_id)
    return false if playlist_id.blank?

    # Vérifie que la playlist existe ET que l'utilisateur la suit encore
    response = HTTParty.get("#{BASE_URL}/playlists/#{playlist_id}",
      headers: { "Authorization" => "Bearer #{@access_token}" }
    )
    return false unless response.code == 200

    # Récupère l'ID de l'utilisateur courant
    me = HTTParty.get("#{BASE_URL}/me",
      headers: { "Authorization" => "Bearer #{@access_token}" }
    )
    user_id = me["id"]
    return false unless user_id

    # Vérifie si l'utilisateur suit la playlist
    follow_response = HTTParty.get(
      "#{BASE_URL}/playlists/#{playlist_id}/followers/contains",
      headers: { "Authorization" => "Bearer #{@access_token}" },
      query: { ids: user_id }
    )
    follow_response.code == 200 && follow_response.parsed_response&.first == true
  rescue StandardError
    false
  end

  def find_or_create_playlist(existing_id: nil, name: "Newsic")
  return existing_id if playlist_exists?(existing_id)
  create_playlist(name: name)
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

  def follow_playlist(playlist_id)
    HTTParty.put("#{BASE_URL}/playlists/#{playlist_id}/followers",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type"  => "application/json"
      },
      body: { public: false }.to_json
    )
  end

  def add_tracks_to_playlist(playlist_id:, ids:)
    uris = ids.map { |id| "spotify:track:#{id}" }
    HTTParty.post(
      "#{BASE_URL}/playlists/#{playlist_id}/items",
      headers: {
        "Authorization" => "Bearer #{@access_token}",
        "Content-Type"  => "application/json"
      },
      body: { uris: uris }.to_json
    )
  end

  def search_track_id(artist:, title:)
    response = HTTParty.get("#{BASE_URL}/search", {
      headers: { "Authorization" => "Bearer #{@access_token}" },
      query: { q: "artist:#{artist} track:#{title}", type: "track", limit: 1 }
    })
    response.dig("tracks", "items", 0, "id")
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

  private

  def liked_tracks_page(offset)
    response = HTTParty.get("#{BASE_URL}/me/tracks", {
      headers: { "Authorization" => "Bearer #{@access_token}" },
      query: { limit: 50, offset: offset }
    })
    response["items"] || []
  end

  def add_track_key(keys, track)
    return unless track

    artist = track.dig("artists", 0, "name")
    title  = track["name"]
    keys << "#{artist}|#{title}".downcase if artist.present? && title.present?
  end

end
