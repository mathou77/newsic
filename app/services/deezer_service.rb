class DeezerService
  BASE_URL = "https://api.deezer.com"

  def search_track(artist:, title:)
    query = "artist:\"#{artist}\" track:\"#{title}\""
    response = HTTParty.get("#{BASE_URL}/search", query: { q: query })
    results = response["data"] || []
    results.find { |r| r.dig("artist", "name").downcase == artist.downcase } || results.first
  end

  # Autocomplete for the "seed" selector. Returns light hashes for the UI.
  def search_artists(query, limit: 6)
    response = HTTParty.get("#{BASE_URL}/search/artist", query: { q: query, limit: limit })
    (response["data"] || []).map do |a|
      { name: a["name"], image: a["picture_medium"] }
    end
  end

  def search_tracks(query, limit: 6)
    response = HTTParty.get("#{BASE_URL}/search/track", query: { q: query, limit: limit })
    (response["data"] || []).map do |t|
      { title: t["title"], artist: t.dig("artist", "name"), image: t.dig("album", "cover_small") }
    end
  end

  # Deezer preview URLs are signed and expire after a few hours, so they
  # can't be cached long-term. Re-fetch a fresh one by track id at play time.
  def fresh_preview_url(deezer_id)
    response = HTTParty.get("#{BASE_URL}/track/#{deezer_id}")
    response["preview"].presence
  end

  # Full track details (release_date, bpm, ...) which are absent from /search.
  # Only fetched when the decade or tempo filter is active; the engine memoises
  # the result so both filters share a single call per track.
  def track(deezer_id)
    HTTParty.get("#{BASE_URL}/track/#{deezer_id}")
  end
end
