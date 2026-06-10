class SongsController < ApplicationController
  # Track detail ("Learn More"): artist, genre, preview.
  def show
    @song = Song.find(params[:id])
  end

  # Audio proxy: Deezer preview URLs are signed and expire within minutes, so a
  # URL cached in the DB is almost always dead by the time the browser plays it.
  # Instead, <audio> points here and we mint a fresh URL on every load, caching
  # it back so the detail pages still have something if Deezer is unreachable.
  def preview
    song = Song.find(params[:id])
    url  = (DeezerService.new.fresh_preview_url(song.deezer_id) if song.deezer_id.present?)
    if url.present?
      song.update_columns(preview_url: url, updated_at: Time.current) if url != song.preview_url
    else
      url = song.preview_url
    end

    if url.present?
      # The signed Deezer URL changes (and expires) on every call, so the
      # browser must NOT cache this redirect — otherwise a song replayed in a
      # later session reuses a stale, already-expired URL and stays silent.
      response.headers["Cache-Control"] = "no-store"
      redirect_to url, allow_other_host: true
    else
      head :no_content
    end
  rescue => e
    Rails.logger.warn("songs#preview: #{e.message}")
    head :no_content
  end
end
