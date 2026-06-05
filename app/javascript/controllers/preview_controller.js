import { Controller } from "@hotwired/stimulus"

// Plays/pauses a 30s preview, pausing any other preview already playing.
export default class extends Controller {
  static targets = ["audio", "button"]

  toggle() {
    if (this.audioTarget.paused) {
      document.querySelectorAll("audio").forEach((a) => { if (a !== this.audioTarget) a.pause() })
      this.audioTarget.play().catch(() => {})
      this.setIcon(true)
      this.audioTarget.onended = () => this.setIcon(false)
    } else {
      this.audioTarget.pause()
      this.setIcon(false)
    }
  }

  setIcon(playing) {
    if (!this.hasButtonTarget) return
    const icon = this.buttonTarget.querySelector("i")
    if (icon) icon.className = playing ? "fa-solid fa-pause" : "fa-solid fa-play"
  }
}
