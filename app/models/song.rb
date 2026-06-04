class Song < ApplicationRecord
  has_many :playlists
  has_many :suggestions, through: :playlists

  # Resolves a track picked from a Deezer search (we only have artist+title)
  # into a persisted Song with cover + preview, reusing the Deezer lookup.
  def self.from_deezer_search(artist:, title:)
    result = DeezerService.new.search_track(artist: artist, title: title)
    return nil unless result

    song = find_or_initialize_by(deezer_id: result["id"])
    song.title       = title
    song.artist      = artist
    song.preview_url = result["preview"]
    song.image_url   = result.dig("album", "cover_big")
    song.save!
    song
  end
end
