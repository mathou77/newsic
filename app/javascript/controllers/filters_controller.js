import { Controller } from "@hotwired/stimulus"

const DECADE_LABELS = ["1960s","1970s","1980s","1990s","2000s","2010s","2020s"]
const DECADE_VALUES = ["1960","1970","1980","1990","2000","2010","2020"]
const TEMPO_LABELS  = ["Lent 🐢","Moyen 🚶","Rapide 🚀"]
const TEMPO_VALUES  = ["slow","medium","fast"]

export default class extends Controller {
  static targets = ["toggle", "panel", "badge"]

  connect() {
    this.initRange("decade", DECADE_LABELS, DECADE_VALUES)
    this.initRange("tempo",  TEMPO_LABELS,  TEMPO_VALUES)
    this.initMoodPills()
    this.updateBadge()

    this.element.querySelector(".filters-form")?.addEventListener("change", () => this.updateBadge())
    this.element.querySelectorAll(".range-chip").forEach(btn =>
      btn.addEventListener("click", () => setTimeout(() => this.updateBadge(), 50))
    )
  }

  open() {
    this.panelTarget.classList.add("open")
  }

  close() {
    this.panelTarget.classList.remove("open")
  }

  initRange(name, labels, values) {
    const range  = this.element.querySelector(`#${name}-range`)
    const label  = this.element.querySelector(`#${name}-label`)
    const hidden = this.element.querySelector(`#${name}-hidden`)
    const toggle = this.element.querySelector(`#${name}-toggle`)
    const block  = this.element.querySelector(`#${name}-block`)
    if (!range || !toggle) return

    range.addEventListener("input", () => {
      label.textContent = " · " + labels[parseInt(range.value)]
      hidden.value = values[parseInt(range.value)]
    })

    toggle.addEventListener("click", () => {
      const active = block.classList.toggle("is-active")
      if (active) {
        label.textContent = " · " + labels[parseInt(range.value)]
        hidden.value = values[parseInt(range.value)]
      } else {
        label.textContent = ""
        hidden.value = ""
      }
    })
  }

  initMoodPills() {
    this.element.querySelectorAll(".mood-pill").forEach(pill => {
      pill.addEventListener("click", () => {
        this.element.querySelectorAll(".mood-pill").forEach(p => p.classList.remove("is-active"))
        pill.classList.add("is-active")
      })
    })
  }

  updateBadge() {
    let count = 0
    const form = this.element.querySelector(".filters-form")
    if (!form) return

    const genre = form.querySelector("select[name='genre']")
    if (genre?.value) count++

    const mood = form.querySelector("input[name='mood']:checked")
    if (mood?.value) count++

    this.element.querySelectorAll(".range-filter.is-active").forEach(() => count++)
    form.querySelectorAll("input[type='checkbox']:checked").forEach(() => count++)

    if (count > 0) {
      this.badgeTarget.textContent = count
      this.badgeTarget.style.display = "block"
      this.toggleTarget.classList.add("is-active")
    } else {
      this.badgeTarget.style.display = "none"
      this.toggleTarget.classList.remove("is-active")
    }
  }
}
