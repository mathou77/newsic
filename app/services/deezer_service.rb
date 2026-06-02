class DeezerService
  BASE_URL = "https://api.deezer.com"

  def search_track(artist:, title:)
    query = "artist:\"#{artist}\" track:\"#{title}\""
    response = HTTParty.get("#{BASE_URL}/search", query: { q: query })
    results = response["data"] || []
    results.find { |r| r.dig("artist", "name").downcase == artist.downcase } || results.first
  end

  # Deezer preview URLs are signed and expire after a few hours, so they
  # can't be cached long-term. Re-fetch a fresh one by track id at play time.
  def fresh_preview_url(deezer_id)
    response = HTTParty.get("#{BASE_URL}/track/#{deezer_id}")
    response["preview"].presence
  end
end
