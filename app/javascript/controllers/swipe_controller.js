import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "back"]
  static values  = { recapUrl: String }

  connect() {
    this.paused        = false  // start in "playing" state — autoplay if the browser allows it
    this.audioUnlocked = false
    this.isSeeking     = false
    this.startX        = 0
    this.history       = []     // voted cards we can bring back

    this._seekMouseDown  = (e) => { if (e.target.closest(".player-bar__progress")) { this.isSeeking = true;  this.seekFromClientX(e.clientX) } }
    this._seekMouseMove  = (e) => { if (this.isSeeking) this.seekFromClientX(e.clientX) }
    this._seekMouseUp    = ()  => { this.isSeeking = false }
    this._seekTouchStart = (e) => { if (e.target.closest(".player-bar__progress")) { this.isSeeking = true;  this.seekFromClientX(e.touches[0].clientX) } }
    this._seekTouchMove  = (e) => { if (this.isSeeking) this.seekFromClientX(e.touches[0].clientX) }
    this._seekTouchEnd   = ()  => { this.isSeeking = false }

    document.addEventListener("mousedown",  this._seekMouseDown)
    document.addEventListener("mousemove",  this._seekMouseMove)
    document.addEventListener("mouseup",    this._seekMouseUp)
    document.addEventListener("touchstart", this._seekTouchStart, { passive: true })
    document.addEventListener("touchmove",  this._seekTouchMove,  { passive: true })
    document.addEventListener("touchend",   this._seekTouchEnd)

    this.applyCardColor(this.activeCard)
    this.updatePlayerIcon()
    this.armUpcoming()

    // Try to autoplay the first card right away. Browsers block sound until the
    // user has interacted with the page (especially in private mode), so if it's
    // refused we kick it off on the very first tap/click anywhere — no need to
    // press play. Once unlocked, every following card plays on its own.
    this.playCurrentAudio()
    this._unlockAudio = (e) => {
      if (this.audioUnlocked) return
      if (e.target.closest(".player-bar__toggle")) return  // the play/pause button handles itself
      this.audioUnlocked = true
      document.removeEventListener("pointerdown", this._unlockAudio)
      const audio = this.activeCard?.querySelector(".card-audio")
      if (audio && audio.paused) this.playCurrentAudio()
    }
    document.addEventListener("pointerdown", this._unlockAudio)
  }

  disconnect() {
    document.removeEventListener("mousedown",  this._seekMouseDown)
    document.removeEventListener("mousemove",  this._seekMouseMove)
    document.removeEventListener("mouseup",    this._seekMouseUp)
    document.removeEventListener("touchstart", this._seekTouchStart)
    document.removeEventListener("touchmove",  this._seekTouchMove)
    document.removeEventListener("touchend",   this._seekTouchEnd)
    document.removeEventListener("pointerdown", this._unlockAudio)

    this.stopAllAudio()
  }

  // ── Cards ─────────────────────────────────────────────────────────────────────

  get activeCard() {
    return this.cardTargets.find(c => c.classList.contains("active")) ?? null
  }

  // ── Flip ──────────────────────────────────────────────────────────────────────

  flip(event) {
    if (event.target.closest(".card-player-bar"))  return
    if (event.target.closest(".card-share"))        return
    if (event.target.closest(".card-artist-link"))  return
    event.currentTarget.classList.toggle("is-flipped")
  }

  // ── Vote ──────────────────────────────────────────────────────────────────────

  like()    { this.vote("liked") }
  dislike() { this.vote("disliked") }

  vote(status) {
    const card = this.activeCard
    if (!card) return

    this.sendVote(card, status)
    card.classList.add(status === "liked" ? "fly-right" : "fly-left")

    setTimeout(() => {
      card.remove()
      // Only now that it's detached do we offer it for "back" — avoids this
      // pending removal racing with a restore.
      this.history.push(card)
      this.updateBackButton()

      const remaining = this.cardTargets
      if (remaining.length === 0) {
        window.location.href = this.recapUrlValue
      } else {
        remaining[0].classList.add("active")
        this.playCurrentAudio()
      }
    }, 400)
  }

  // Bring the last voted card back, undo its vote on the server, and make it the
  // active card again.
  back() {
    const card = this.history.pop()
    if (!card) return

    this.sendVote(card, "pending")

    card.classList.remove("fly-left", "fly-right")
    this.activeCard?.classList.remove("active")

    const stack = this.element.querySelector(".cards-stack")
    stack?.prepend(card)
    card.classList.add("active")

    this.playCurrentAudio()
    this.updateBackButton()
  }

  sendVote(card, status) {
    fetch(card.dataset.voteUrl, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ status })
    })
  }

  updateBackButton() {
    if (!this.hasBackTarget) return
    this.backTarget.hidden = this.history.length === 0
  }

  // ── Touch Swipe ───────────────────────────────────────────────────────────────

  touchStart(event) {
    this.startX = event.touches[0].clientX
  }

  touchEnd(event) {
    if (this.isSeeking) return
    if (this.element.querySelector(".share-sheet.is-open")) return
    // Don't treat scrolling the mood bar or interacting with the filters panel
    // as a card swipe vote.
    if (event.target.closest(".swipe-topbar, .mood-bar, .filters-panel, .playlist-sheet")) return
    const diff = event.changedTouches[0].clientX - this.startX
    if (!this.activeCard) return
    if (diff > 80)  this.vote("liked")
    if (diff < -80) this.vote("disliked")
  }

  // ── Audio ─────────────────────────────────────────────────────────────────────

  // Lazily fetch a fresh Deezer link only for the cards about to be played:
  // the active one and the next in line. The rest stay untouched (preload="none")
  // until the user reaches them, so we hit Deezer ~2 cards at a time, not all 10.
  armUpcoming() {
    const cards  = this.cardTargets
    const active = this.activeCard
    if (!active) return
    const idx = cards.indexOf(active)
    this.armCard(cards[idx])
    this.armCard(cards[idx + 1])
  }

  armCard(card) {
    if (!card) return
    const audio = card.querySelector(".card-audio")
    if (!audio || audio.src || !audio.dataset.src) return  // missing or already armed
    audio.src     = audio.dataset.src
    audio.preload = "auto"
    audio.load()
  }

  stopAllAudio() {
    this.cardTargets.forEach(c => {
      const a = c.querySelector(".card-audio")
      if (a) { a.pause(); a.currentTime = 0 }
    })
  }

  playCurrentAudio() {
    this.stopAllAudio()
    this.paused = false
    const card  = this.activeCard
    if (!card) return
    this.armUpcoming()
    const audio = card.querySelector(".card-audio")
    const fill  = card.querySelector(".player-bar__fill")
    if (fill) fill.style.width = "0%"
    if (audio) {
      audio.play().catch(() => {})
      this.bindProgressBar(audio, fill)
    }
    this.updatePlayerIcon()
    this.applyCardColor(card)
  }

  bindProgressBar(audio, fill) {
    audio.addEventListener("timeupdate", () => {
      if (!audio.duration || !fill) return
      fill.style.width = (audio.currentTime / audio.duration * 100) + "%"
    })
  }

  togglePlayPause() {
    this.armUpcoming()
    const audio = this.activeCard?.querySelector(".card-audio")
    if (!audio) return
    // Use the element's real state, not our intent: autoplay may have been
    // blocked, so the icon can say "playing" while the audio is actually paused.
    if (audio.paused) {
      audio.play().catch(() => {})
      this.audioUnlocked = true
      this.paused = false
      const fill = this.activeCard.querySelector(".player-bar__fill")
      this.bindProgressBar(audio, fill)
    } else {
      audio.pause()
      this.paused = true
    }
    this.updatePlayerIcon()
  }

  updatePlayerIcon() {
    const icon = this.activeCard?.querySelector(".player-bar__icon")
    if (!icon) return
    icon.className = this.paused
      ? "fa-solid fa-play player-bar__icon"
      : "fa-solid fa-pause player-bar__icon"
  }

  // ── Seek ──────────────────────────────────────────────────────────────────────

  seekFromClientX(clientX) {
    const card  = this.activeCard
    const audio = card?.querySelector(".card-audio")
    const fill  = card?.querySelector(".player-bar__fill")
    const bar   = card?.querySelector(".player-bar__progress")
    if (!audio || !audio.duration || !bar) return
    const rect  = bar.getBoundingClientRect()
    const ratio = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width))
    audio.currentTime = ratio * audio.duration
    if (fill) fill.style.width = (ratio * 100) + "%"
  }

  // ── Dominant Color ────────────────────────────────────────────────────────────

  // The ambient colour is precomputed server-side and carried on the card as
  // data-color. We drive a single registered custom property (--ambient-color)
  // that both the page background and the card's back face read; the CSS
  // transition crossfades it over ~0.6s as cards change.
  applyCardColor(card) {
    const color = card?.dataset.color
    if (color) {
      this.element.style.setProperty("--ambient-color", color)
    } else {
      this.element.style.removeProperty("--ambient-color") // fall back to midnight
    }
  }
}
