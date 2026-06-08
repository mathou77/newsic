import { Controller } from "@hotwired/stimulus"

const DECADE_LABELS  = ["1960s", "1970s", "1980s", "1990s", "2000s", "2010s", "2020s"]
const DECADE_VALUES  = ["1960",  "1970",  "1980",  "1990",  "2000",  "2010",  "2020"]
const POP_LABELS     = ["Hidden gems 💎", "Mainstream 🔥"]
const POP_VALUES     = ["hidden",          "mainstream"]
const TEMPO_LABELS   = ["Lent 🐢", "Moyen 🚶", "Rapide 🚀"]
const TEMPO_VALUES   = ["slow",    "medium",   "fast"]

export default class extends Controller {
  connect() {
    this.initMoodPills()
  }

  initRange(rangeId, labelId, hiddenId, toggleId, blockId, labels, values) {
    const range  = document.getElementById(rangeId)
    const label  = document.getElementById(labelId)
    const hidden = document.getElementById(hiddenId)
    const toggle = document.getElementById(toggleId)
    const block  = document.getElementById(blockId)
    if (!range) return

    range.addEventListener("input", () => {
      const idx         = parseInt(range.value)
      label.textContent = labels[idx]
      hidden.value      = values[idx]
    })

    toggle.addEventListener("click", () => {
      const active = block.classList.toggle("is-active")
      toggle.textContent = active ? "✕" : "+"
      range.disabled     = !active
      hidden.value       = active ? values[parseInt(range.value)] : ""
    })
  }

  initMoodPills() {
    document.querySelectorAll(".mood-pill").forEach(pill => {
      pill.addEventListener("click", () => {
        document.querySelectorAll(".mood-pill").forEach(p => p.classList.remove("is-active"))
        pill.classList.add("is-active")
      })
    })
  }
}
