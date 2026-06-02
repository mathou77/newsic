class DeezerService
  BASE_URL = "https://api.deezer.com"

  def search_track(artist:, title:)
    query = "artist:\"#{artist}\" track:\"#{title}\""
    response = HTTParty.get("#{BASE_URL}/search", query: { q: query })
    results = response["data"] || []
    results.find { |r| r.dig("artist", "name").downcase == artist.downcase } || results.first
  end
end
