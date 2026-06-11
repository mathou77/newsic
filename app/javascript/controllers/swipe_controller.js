import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]
  static values  = { recapUrl: String }

  connect() {
    this.paused        = false  // start in "playing" state — autoplay if the browser allows it
    this.audioUnlocked = false
    this.isSeeking     = false
    this.startX        = 0
    this.startY        = 0
    this.dragging      = false  // a finger is currently dragging the active card
    this.dragCard      = null
    this.dragDX        = 0
    this.suppressFlip  = false  // a drag just ended — don't let its click flip the card
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

    this.cardTargets.forEach(card => this.applyCardColor(card))
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
    if (this.suppressFlip) { this.suppressFlip = false; return } // a drag just ended
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

    fetch(card.dataset.voteUrl, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ status })
    })

    card.classList.add(status === "liked" ? "fly-right" : "fly-left")

    setTimeout(() => {
      card.remove()
      const remaining = this.cardTargets
      if (remaining.length === 0) {
        window.location.href = this.recapUrlValue
      } else {
        remaining[0].classList.add("active")
        this.playCurrentAudio()
      }
    }, 400)
  }

  // ── Touch Swipe ───────────────────────────────────────────────────────────────

  touchStart(event) {
    // Reset drag state for every new touch so a bailed-out gesture never leaks
    // into the next one.
    this.dragging     = false
    this.dragCard     = null
    this.dragDX       = 0
    this.suppressFlip = false

    if (this.isSeeking) return
    if (this.element.querySelector(".share-sheet.is-open")) return
    // Don't drag the card when the touch starts on the surrounding UI or on the
    // card's own controls (player bar, share, artist link) — those handle taps.
    if (event.target.closest(".filters-panel")) return
    if (event.target.closest(".card-player-bar, .card-share, .card-artist-link")) return

    const card = this.activeCard
    if (!card) return
    if (card.querySelector(".flip-card-inner.is-flipped")) return // don't drag a flipped card

    this.startX        = event.touches[0].clientX
    this.startY        = event.touches[0].clientY
    this.dragCard      = card
    this.dragging      = true
    card.style.transition = "none" // follow the finger with no easing lag
  }

  touchMove(event) {
    if (!this.dragging || !this.dragCard) return
    const dx = event.touches[0].clientX - this.startX
    const dy = event.touches[0].clientY - this.startY
    this.dragDX = dx
    // Slight rotation tied to horizontal distance, like a card being flicked.
    const rot = Math.max(-12, Math.min(12, dx / 14))
    this.dragCard.style.transform = `translate(${dx}px, ${dy}px) rotate(${rot}deg)`
  }

  touchEnd() {
    if (!this.dragging || !this.dragCard) return
    const card = this.dragCard
    const dx   = this.dragDX
    this.dragging = false
    this.dragCard = null

    card.style.transition = "" // restore the CSS easing for fly-off / snap-back
    if (Math.abs(dx) > 10) this.suppressFlip = true // it was a drag, not a tap

    if (dx > 80) {
      card.style.transform = ""  // let .fly-right take over
      this.vote("liked")
    } else if (dx < -80) {
      card.style.transform = ""  // let .fly-left take over
      this.vote("disliked")
    } else {
      card.style.transform = ""  // snap back to centre
    }
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

  applyCardColor(card) {
    const img = card.querySelector(".card-cover")
    if (!img) return
    const apply = () => this.getDominantColor(img, color => {
      if (!color) return
      const { r, g, b } = color
      this.element.style.background = `
        radial-gradient(circle at 50% 40%, rgba(${r},${g},${b},0.45) 0%, rgba(${r},${g},${b},0.08) 55%, #050510 80%),
        #050510
      `
    })
    if (img.complete) apply()
    else img.addEventListener("load", apply)
  }

  getDominantColor(img, callback) {
    try {
      const canvas = document.createElement("canvas")
      canvas.width = canvas.height = 32
      const ctx = canvas.getContext("2d")
      ctx.drawImage(img, 0, 0, 32, 32)
      const data = ctx.getImageData(0, 0, 32, 32).data
      let r = 0, g = 0, b = 0, count = 0
      for (let i = 0; i < data.length; i += 16) {
        const pr = data[i], pg = data[i + 1], pb = data[i + 2]
        const brightness = (pr + pg + pb) / 3
        if (brightness > 30 && brightness < 230) { r += pr; g += pg; b += pb; count++ }
      }
      if (count === 0) { callback(null); return }
      callback({ r: Math.round(r / count), g: Math.round(g / count), b: Math.round(b / count) })
    } catch (e) { callback(null) }
  }
}
