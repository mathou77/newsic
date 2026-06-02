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
end
