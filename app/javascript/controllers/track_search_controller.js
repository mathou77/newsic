import { Controller } from "@hotwired/stimulus"

// Mini Deezer search inside the chat: find a track and send it as a music card.
export default class extends Controller {
  static targets = ["panel", "input", "results"]
  static values = { url: String, sendUrl: String }

  togglePanel() {
    this.panelTarget.hidden = !this.panelTarget.hidden
    if (!this.panelTarget.hidden) this.inputTarget.focus()
  }

  query() {
    clearTimeout(this.timer)
    const q = this.inputTarget.value.trim()
    if (q.length < 2) { this.resultsTarget.innerHTML = ""; return }
    this.timer = setTimeout(() => {
      fetch(`${this.urlValue}?q=${encodeURIComponent(q)}`, { headers: { Accept: "application/json" } })
        .then((r) => r.json())
        .then((data) => this.render(data))
        .catch(() => { this.resultsTarget.innerHTML = "" })
    }, 300)
  }

  render(data) {
    this.resultsTarget.innerHTML = ""
    ;(data.tracks || []).forEach((t) => {
      const row = document.createElement("button")
      row.type = "button"
      row.className = "track-result"
      row.innerHTML = `<img src="${t.image || ""}" alt=""><span>${t.title} — ${t.artist}</span>`
      row.addEventListener("click", () => this.sendTrack(t))
      this.resultsTarget.appendChild(row)
    })
  }

  sendTrack(track) {
    fetch(this.sendUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ track: { artist: track.artist, title: track.title } })
    }).then(() => {
      this.resultsTarget.innerHTML = ""
      this.inputTarget.value = ""
      this.panelTarget.hidden = true
    })
  }
}
