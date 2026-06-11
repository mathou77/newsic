require "open-uri"

# Computes the ambient "dominant" colour of a song's cover and stores it as a hex
# string on the Song. Runs off the request cycle so building suggestions stays
# fast. The colour is averaged from the cover, then nudged into a readable range
# (clamped lightness, slightly desaturated) so the swiper background stays legible.
class ExtractDominantColorJob < ApplicationJob
  queue_as :default

  # Blend target / fallback — the app's midnight background.
  MIDNIGHT = [10, 10, 26].freeze # #0a0a1a

  def perform(song_id)
    song = Song.find_by(id: song_id)
    return unless song
    return if song.image_url.blank?
    return if song.dominant_color.present?

    rgb = average_rgb(song.image_url)
    return unless rgb

    song.update_column(:dominant_color, to_hex(readable(rgb)))
  rescue => e
    Rails.logger.warn("ExtractDominantColorJob(#{song_id}): #{e.message}")
  end

  private

  # Downsize the cover to a single pixel — ImageMagick averages the whole image
  # for us — and read that pixel back as RGB.
  def average_rgb(url)
    blob = URI.open(url, read_timeout: 8, open_timeout: 5, &:read)
    image = MiniMagick::Image.read(blob)
    image.combine_options do |c|
      c.resize "1x1!"
      c.depth 8
    end
    pixel = image.get_pixels.dig(0, 0)
    pixel if pixel.is_a?(Array) && pixel.size >= 3
  end

  # Keep the colour visible but not blinding: pull extreme lightness back toward
  # the middle and shave a bit of saturation. Mixes lightly toward midnight too.
  def readable(rgb)
    h, s, l = rgb_to_hsl(*rgb.first(3))
    s *= 0.82
    l = l.clamp(0.34, 0.56)
    r, g, b = hsl_to_rgb(h, s, l)
    mix([r, g, b], MIDNIGHT, 0.85) # 85% colour / 15% midnight
  end

  def mix(a, b, ratio)
    a.each_with_index.map { |v, i| (v * ratio + b[i] * (1 - ratio)).round.clamp(0, 255) }
  end

  def to_hex(rgb)
    "#" + rgb.first(3).map { |v| format("%02x", v.to_i.clamp(0, 255)) }.join
  end

  def rgb_to_hsl(r, g, b)
    r /= 255.0; g /= 255.0; b /= 255.0
    max = [r, g, b].max; min = [r, g, b].min
    l = (max + min) / 2.0
    return [0.0, 0.0, l] if max == min

    d = max - min
    s = l > 0.5 ? d / (2.0 - max - min) : d / (max + min)
    h = case max
        when r then (g - b) / d + (g < b ? 6 : 0)
        when g then (b - r) / d + 2
        else        (r - g) / d + 4
        end / 6.0
    [h, s, l]
  end

  def hsl_to_rgb(h, s, l)
    return [(l * 255).round] * 3 if s.zero?

    q = l < 0.5 ? l * (1 + s) : l + s - l * s
    p = 2 * l - q
    [h + 1.0 / 3, h, h - 1.0 / 3].map do |t|
      t += 1 if t < 0
      t -= 1 if t > 1
      v = if t < 1.0 / 6 then p + (q - p) * 6 * t
          elsif t < 1.0 / 2 then q
          elsif t < 2.0 / 3 then p + (q - p) * (2.0 / 3 - t) * 6
          else p
          end
      (v * 255).round
    end
  end
end
