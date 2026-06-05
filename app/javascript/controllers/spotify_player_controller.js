import { Controller } from "@hotwired/stimulus"

// Spotify Web Playback SDK — full-track playback (requires a Premium account
// and the `streaming user-modify-playback-state user-read-playback-state` scopes).
export default class extends Controller {
  static targets = ["playerBar", "playBtn", "pauseBtn", "progressBar", "currentTime", "duration", "trackTitle", "trackArtist"]
  static values = { token: String }

  connect() {
    this.player = null
    this.deviceId = null
    this.progressInterval = null
    if (this.tokenValue) this.initSDK()
  }

  initSDK() {
    if (!window.Spotify && !document.getElementById("spotify-sdk")) {
      const script = document.createElement("script")
      script.id = "spotify-sdk"
      script.src = "https://sdk.scdn.co/spotify-player.js"
      document.body.appendChild(script)
    }

    const setup = () => {
      this.player = new Spotify.Player({
        name: "NEWSIC Player",
        getOAuthToken: cb => { cb(this.tokenValue) },
        volume: 0.8
      })

      this.player.addListener("ready", ({ device_id }) => {
        this.deviceId = device_id
      })

      this.player.addListener("player_state_changed", state => {
        if (state) this.updatePlayerUI(state)
      })

      this.player.connect()
    }

    if (window.Spotify) setup()
    else window.onSpotifyWebPlaybackSDKReady = setup
  }

  // Pause the 30s Deezer preview, then play the full Spotify track.
  async playFullTrack(event) {
    const trackName = event.currentTarget.dataset.trackName
    const artistName = event.currentTarget.dataset.artistName
    document.querySelectorAll(".card-audio").forEach(a => a.pause())

    const res = await fetch(
      `https://api.spotify.com/v1/search?q=${encodeURIComponent(`${trackName} ${artistName}`)}&type=track&limit=1`,
      { headers: { Authorization: `Bearer ${this.tokenValue}` } }
    )
    const data = await res.json()
    const uri = data.tracks?.items?.[0]?.uri
    if (!uri || !this.deviceId) return

    await fetch(`https://api.spotify.com/v1/me/player/play?device_id=${this.deviceId}`, {
      method: "PUT",
      headers: { Authorization: `Bearer ${this.tokenValue}`, "Content-Type": "application/json" },
      body: JSON.stringify({ uris: [uri] })
    })

    this.showPlayer()
    this.startProgressTracking()
  }

  togglePlay() {
    if (this.player) this.player.togglePlay()
  }

  showPlayer() {
    this.playerBarTarget.classList.remove("hidden")
    this.playerBarTarget.classList.add("player-slide-up")
  }

  hidePlayer() {
    this.playerBarTarget.classList.add("hidden")
    this.player?.pause()
    this.stopProgressTracking()
  }

  startProgressTracking() {
    this.stopProgressTracking()
    this.progressInterval = setInterval(async () => {
      const state = await this.player.getCurrentState()
      if (state) this.updatePlayerUI(state)
    }, 500)
  }

  stopProgressTracking() {
    if (this.progressInterval) clearInterval(this.progressInterval)
  }

  updatePlayerUI(state) {
    const { position, duration } = state
    const track = state.track_window.current_track
    const pct = duration ? (position / duration) * 100 : 0

    this.progressBarTarget.style.width = `${pct}%`
    this.currentTimeTarget.textContent = this.formatTime(position)
    this.durationTarget.textContent = this.formatTime(duration)
    this.trackTitleTarget.textContent = track.name
    this.trackArtistTarget.textContent = track.artists.map(a => a.name).join(", ")

    this.playBtnTarget.classList.toggle("hidden", !state.paused)
    this.pauseBtnTarget.classList.toggle("hidden", state.paused)
  }

  formatTime(ms) {
    const s = Math.floor(ms / 1000)
    return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`
  }

  disconnect() {
    this.stopProgressTracking()
    if (this.player) this.player.disconnect()
  }
}
