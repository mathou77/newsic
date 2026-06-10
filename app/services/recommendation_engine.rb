require "set"

# Builds the pool of song suggestions for a swipe session.
#
# Two candidate sources:
#   - "seed"  : artists/tracks the user explicitly picked (the base they want).
#   - "taste" : the user's Spotify top tracks + chosen mood/genre tags.
#
# When seeds are present, ~70% of the cards are drawn from the seed source and
# the rest from the taste source (which fills more if the seed pool runs dry).
# With no seeds, 100% comes from the taste source (original behaviour).
class RecommendationEngine
  # Deezer "rank" is a popularity score (~0 to 1M). Above this we consider a
  # track mainstream, below it a hidden gem.
  MAINSTREAM_RANK = 500_000

  # Share of cards drawn from the user's explicit seed selection.
  SEED_SHARE = 0.7

  # How long before we re-fetch top tracks from Spotify.
  TRACKS_TTL = 6.hours

  def initialize(access_token:, filters:, user: nil)
    @spotify = SpotifyService.new(access_token)
    @lastfm  = LastfmService.new
    @deezer  = DeezerService.new
    @filters = filters
    @user    = user
  end

  def build(suggestion)
    @suggestion      = suggestion
    @count           = 0
    @seen_deezer_ids = Set.new
    @artist_counts   = Hash.new(0)
    @known_artists   = discovery? ? known_artists : Set.new
    @liked_keys      = @filters[:exclude_liked] ? liked_keys : Set.new
    @disliked_ids    = @filters[:exclude_disliked] ? disliked_deezer_ids : Set.new
    @mutex           = Mutex.new

    total = @filters[:count]

    if seeds?
      fill(seed_candidates, (total * SEED_SHARE).round)  # ~70% from the selection
    end
    fill(taste_candidates, total)                         # rest (or all) from taste + mood/genre
  end

  private

  def seeds?
    @filters[:seed_artists].present? || @filters[:seed_tracks].present?
  end

  def discovery?
    @filters[:discovery].present?
  end

  # Returns the user's Spotify top tracks, using the DB cache when fresh.
  def cached_top_tracks(limit: 50, time_range: "medium_term")
    if @user&.top_tracks.present? && @user.spotify_cache_refreshed_at&.>(TRACKS_TTL.ago)
      @user.top_tracks.first(limit)
    else
      @spotify.top_tracks(limit: limit, time_range: time_range)
    end
  end

  # Artists already in the user's Spotify listening, to exclude in discovery mode.
  def known_artists
    names = Set.new
    cached_top_tracks(limit: 50, time_range: @filters[:time_range]).each do |t|
      names << t.dig("artists", 0, "name").to_s.downcase
    end
    @spotify.top_artists(limit: 50).each { |a| names << a["name"].to_s.downcase }
    names
  rescue StandardError
    Set.new
  end

  # "artist|title" keys of the user's liked songs, to exclude when asked.
  # Cached per user in Solid Cache for 6 hours to avoid re-fetching 1000 songs.
  def liked_keys
    cache_key = @user ? "liked_keys:user:#{@user.id}" : nil
    if cache_key
      Rails.cache.fetch(cache_key, expires_in: 6.hours) { @spotify.liked_track_keys }
    else
      @spotify.liked_track_keys
    end
  rescue StandardError
    Set.new
  end

  # Deezer ids of tracks the user already disliked in past sessions, so the
  # "exclude disliked" filter never shows them again.
  def disliked_deezer_ids
    return Set.new unless @user

    Song.joins(:playlists)
        .where(playlists: { status: Playlist.statuses[:disliked], suggestion_id: @user.suggestions.select(:id) })
        .where.not(deezer_id: nil)
        .distinct
        .pluck(:deezer_id)
        .to_set
  rescue StandardError
    Set.new
  end

  # ── Candidate sources ─────────────────────────────────────────────

  # Tracks derived from the user's explicit picks.
  def seed_candidates
    raw   = []
    mutex = Mutex.new

    threads = []

    Array(@filters[:seed_tracks]).each do |entry|
      artist, title = entry.split("|", 2).map(&:to_s)
      next if artist.blank? || title.blank?

      raw << { artist: artist, title: title } # the seed itself
      threads << Thread.new do
        similar = @lastfm.similar_tracks(artist: artist, track: title, limit: 15)
        mutex.synchronize { raw.concat(normalize(similar)) }
      end
    end

    Array(@filters[:seed_artists]).each do |name|
      next if name.blank?

      threads << Thread.new do
        tracks = @lastfm.artist_top_tracks(name, limit: 20)
        mutex.synchronize { raw.concat(normalize(tracks)) }
      end
    end

    threads.each(&:join)
    dedupe(raw)
  end

  # The user's own taste: Spotify top tracks -> similar, plus mood/genre tags.
  def taste_candidates
    raw   = []
    mutex = Mutex.new

    threads = personal_seed_threads(raw, mutex) + tag_threads(raw, mutex)
    threads.each(&:join)
    dedupe(raw)
  end

  def personal_seed_threads(raw, mutex)
    top_tracks = cached_top_tracks(limit: 50, time_range: @filters[:time_range])

    top_tracks.map do |track|
      Thread.new do
        similar = @lastfm.similar_tracks(
          artist: track.dig("artists", 0, "name"),
          track:  track["name"],
          limit:  10
        )
        mutex.synchronize { raw.concat(normalize(similar)) }
      end
    end
  end

  # Mood and genre both resolve to Last.fm tags whose top tracks we pull in.
  def tag_threads(raw, mutex)
    tags = []
    tags.concat(LastfmService::MOOD_TAGS[@filters[:mood]] || []) if @filters[:mood]
    tags << @filters[:genre] if @filters[:genre]

    tags.uniq.map do |tag|
      Thread.new do
        tracks = @lastfm.top_tracks_by_tag(tag, limit: 30)
        mutex.synchronize { raw.concat(normalize(tracks)) }
      end
    end
  end

  # Last.fm's getSimilar / getTopTracks all share the same shape.
  def normalize(lastfm_tracks)
    lastfm_tracks.map { |t| { artist: t.dig("artist", "name"), title: t["name"] } }
  end

  def dedupe(raw)
    raw.compact
       .reject { |t| t[:artist].blank? || t[:title].blank? }
       .uniq   { |t| "#{t[:artist]}|#{t[:title]}".downcase }
       .shuffle
  end

  # ── Deezer enrichment + filters + persistence ─────────────────────

  # Look up candidates on Deezer (batched threads), keep those passing the
  # popularity/decade filters, and persist them until @count reaches `target`.
  def fill(candidates, target)
    candidates.each_slice(10) do |batch|
      break if @count >= target

      slice_threads = batch.map do |candidate|
        Thread.new do
          next if @count >= target

          artist_key = candidate[:artist].to_s.downcase
          next if discovery? && @known_artists.include?(artist_key)

          track_key = "#{candidate[:artist]}|#{candidate[:title]}".downcase
          next if @filters[:exclude_liked] && @liked_keys.include?(track_key)

          result = @deezer.search_track(artist: candidate[:artist], title: candidate[:title])
          next unless result && result["preview"].present?
          next if @disliked_ids.include?(result["id"])
          next unless passes_popularity?(result)
          next unless passes_explicit?(result)

          # Decade + tempo both need /track details: fetch once, share it.
          detail = track_detail(result["id"])
          next unless passes_decade?(detail)
          next unless passes_tempo?(detail)

          @mutex.synchronize do
            next if @count >= target
            next if @seen_deezer_ids.include?(result["id"])
            next if @filters[:diverse] && @artist_counts[artist_key] >= 1

            @seen_deezer_ids << result["id"]
            @artist_counts[artist_key] += 1
            @suggestion.playlists.create!(song: upsert_song(result, candidate), status: :pending)
            @count += 1
          end
        end
      end
      slice_threads.each(&:join)
    end
  end

  # Fetches /track details only when a filter needs them (decade or tempo).
  def track_detail(deezer_id)
    return nil unless @filters[:decade].present? || @filters[:tempo].present?

    @deezer.track(deezer_id)
  end

  def passes_popularity?(result)
    case @filters[:popularity]
    when "mainstream" then result["rank"].to_i >= MAINSTREAM_RANK
    when "hidden"     then result["rank"].to_i <  MAINSTREAM_RANK
    else true
    end
  end

  def passes_explicit?(result)
    return true unless @filters[:clean_only]

    !result["explicit_lyrics"]
  end

  def passes_decade?(detail)
    return true if @filters[:decade].blank?
    return false if detail.nil?

    date = detail["release_date"].presence
    return false if date.blank?

    year   = date[0, 4].to_i
    decade = @filters[:decade].to_i
    year >= decade && year < decade + 10
  end

  # Tempo buckets by BPM. Deezer often reports 0 (unknown); we exclude those
  # so the filter stays honest about what it can actually confirm.
  def passes_tempo?(detail)
    return true if @filters[:tempo].blank?
    return false if detail.nil?

    bpm = detail["bpm"].to_i
    return false if bpm <= 0

    case @filters[:tempo]
    when "slow"   then bpm < 90
    when "medium" then bpm.between?(90, 130)
    when "fast"   then bpm > 130
    else true
    end
  end

  # find_or_initialize so the (expiring) preview URL is always refreshed.
  def upsert_song(result, candidate)
    song = Song.find_or_initialize_by(deezer_id: result["id"])
    song.title       = candidate[:title]
    song.artist      = candidate[:artist]
    song.preview_url = result["preview"]
    song.image_url   = result.dig("album", "cover_big")
    song.save!
    song
  end
end
