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
