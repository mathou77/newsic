import { Controller } from "@hotwired/stimulus"

// Bottom sheet listing the user's liked songs ("Newsic" playlist) with a quick
// audio preview — tap a row to play, tap again (or another row) to stop/switch.
export default class extends Controller {
  static targets = ["sheet", "song"]

  connect() {
    this.audio   = null
    this.current = null
  }

  disconnect() {
    this.stop()
  }

  open() {
    // Don't let the swiper's track keep playing under the preview.
    document.querySelectorAll(".card-audio").forEach((a) => a.pause())
    this.sheetTarget.hidden = false
    requestAnimationFrame(() => this.sheetTarget.classList.add("is-open"))
  }

  close() {
    this.stop()
    this.sheetTarget.classList.remove("is-open")
    setTimeout(() => { this.sheetTarget.hidden = true }, 250)
  }

  toggle(event) {
    const row = event.currentTarget
    if (this.current === row) { this.stop(); return }

    this.stop()
    this.current = row
    row.classList.add("is-playing")
    this.setIcon(row, "pause")

    this.audio = new Audio(row.dataset.previewUrl)
    this.audio.play().catch(() => {})
    this.audio.addEventListener("ended", () => this.stop())
  }

  stop() {
    if (this.audio) { this.audio.pause(); this.audio = null }
    if (this.current) {
      this.current.classList.remove("is-playing")
      this.setIcon(this.current, "play")
      this.current = null
    }
  }

  setIcon(row, name) {
    const icon = row.querySelector(".pl-song__icon i")
    if (icon) icon.className = `fa-solid fa-${name}`
  }
}
