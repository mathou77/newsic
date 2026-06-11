import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "chips", "inputs"]
  static values  = { url: String, initialArtists: Array, initialArtistImages: Array, initialTracks: Array }

  connect() {
    this.seeds = []
    this.timer = null

    this.initialArtistsValue.forEach((name, i) => {
      const image = this.initialArtistImagesValue[i] || null
      this.seeds.push({ kind: "artist", value: name, label: name, image: image || undefined })
    })

    this.initialTracksValue.forEach(entry => {
      const [artist, title] = entry.split("|")
      this.seeds.push({ kind: "track", value: entry, label: `${title} — ${artist}` })
    })

    this.render()

    this._clickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this._clickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this._clickOutside)
    clearTimeout(this.timer)
  }

  search() {
    clearTimeout(this.timer)
    const q = this.inputTarget.value.trim()
    if (q.length < 2) { this.resultsTarget.innerHTML = ""; return }
    this.timer = setTimeout(() => {
      fetch(`${this.urlValue}?q=${encodeURIComponent(q)}`, {
        headers: { "Accept": "application/json" }
      })
        .then(r => r.json())
        .then(data => this.renderResults(data))
        .catch(() => { this.resultsTarget.innerHTML = "" })
    }, 300)
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) this.resultsTarget.innerHTML = ""
  }

  addSeed(seed) {
    const dup = this.seeds.some(s => s.kind === seed.kind && s.value.toLowerCase() === seed.value.toLowerCase())
    if (!dup) { this.seeds.push(seed); this.render() }
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
  }

  removeSeed(index) {
    this.seeds.splice(index, 1)
    this.render()
  }

  // Wipe every selected artist/track. Called when the filters panel is reset.
  clear() {
    this.seeds = []
    this.inputTarget.value = ""
    this.resultsTarget.innerHTML = ""
    this.render()
  }

  render() {
    this.chipsTarget.innerHTML = ""
    this.inputsTarget.innerHTML = ""

    this.seeds.forEach((s, i) => {
      const chip = document.createElement("span")
      chip.className = "seed-chip"

      if (s.image) {
        const img = document.createElement("img")
        img.src = s.image
        img.alt = ""
        chip.appendChild(img)
      }

      const txt = document.createElement("span")
      txt.textContent = s.image ? s.label : (s.kind === "artist" ? "🎤 " : "🎵 ") + s.label

      const btn = document.createElement("button")
      btn.type = "button"
      btn.textContent = "×"
      btn.addEventListener("click", () => this.removeSeed(i))

      chip.append(txt, btn)
      this.chipsTarget.appendChild(chip)

      const hidden = document.createElement("input")
      hidden.type  = "hidden"
      hidden.name  = s.kind === "artist" ? "seed_artists[]" : "seed_tracks[]"
      hidden.value = s.value
      this.inputsTarget.appendChild(hidden)
    })
  }

  renderResults(data) {
    this.resultsTarget.innerHTML = ""
    ;(data.artists || []).forEach(a =>
      this.resultsTarget.appendChild(
        this.resultRow(a.name, a.image, { kind: "artist", value: a.name, label: a.name, image: a.image })
      )
    )
    ;(data.tracks || []).forEach(t => {
      const label = `${t.title} — ${t.artist}`
      this.resultsTarget.appendChild(
        this.resultRow(label, t.image, { kind: "track", value: `${t.artist}|${t.title}`, label, image: t.image })
      )
    })
  }

  resultRow(text, imageUrl, seed) {
    const row = document.createElement("div")
    row.className = "seed-result"

    if (imageUrl) {
      const img = document.createElement("img")
      img.src = imageUrl
      img.alt = ""
      row.appendChild(img)
    }

    const span = document.createElement("span")
    span.textContent = text
    row.appendChild(span)

    row.addEventListener("click", () => this.addSeed(seed))
    return row
  }
}
