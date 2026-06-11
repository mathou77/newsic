class Song < ApplicationRecord
  has_many :playlists
  has_many :suggestions, through: :playlists

  # Whenever a cover lands (either creation path), extract its ambient colour in
  # the background so the swiper can tint itself to the artwork.
  after_save_commit :extract_dominant_color_later,
                    if: -> { saved_change_to_image_url? && image_url.present? && dominant_color.blank? }

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

  private

  def extract_dominant_color_later
    ExtractDominantColorJob.perform_later(id)
  rescue => e
    # The ambient colour is cosmetic — never let it break song/suggestion creation.
    Rails.logger.warn("enqueue ExtractDominantColorJob for Song##{id} failed: #{e.message}")
  end
end
