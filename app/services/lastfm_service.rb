class LastfmService
  BASE_URL = "http://ws.audioscrobbler.com/2.0/"

  MOOD_TAGS = {
    "late night" => ["electronic", "chillout", "ambient", "soul"],
    "chill" => ["chillout", "acoustic", "folk", "singer-songwriter"],
    "energy" => ["dance", "punk", "hard rock", "House"],
    "focus" => ["ambient", "instrumental", "post-rock", "Classical"],
    "happy" => ["pop", "soul", "dance", "funk"]
  }

  def initialize
    @api_key = ENV.fetch("LASTFM")
  end

  def top_tracks_by_tag(tag, limit: 20)
    response = HTTParty.get(BASE_URL, query:
    {
      method: "tag.getTopTracks",
      tag: tag,
      api_key: @api_key,
      format: "json",
      limit: limit
    })
    response.dig("tracks", "track") || []
  end

  def similar_tracks(artist:, track:, limit: 20)
    response = HTTParty.get(BASE_URL, query:
    {
      method: "track.getSimilar",
      artist: artist,
      track: track,
      api_key: @api_key,
      format: "json",
      limit: limit
    })

    response.dig("similartracks", "track") || []
  end

  def tracks_by_mood(mood, limit: 20)
    tags = MOOD_TAGS[mood.downcase] || ["chill"]
    all_tracks = tags.flat_map do |tag|
      top_tracks_by_tag(tag, limit: limit / tags.size)
    end
    all_tracks.uniq { |t| t["name"] }.shuffle
  end
end
