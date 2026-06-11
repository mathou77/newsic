import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "panel", "badge"]

  connect() {
    this.initMoodPills()
    this.initFinetune()
    this.updateBadge()
    this.element.querySelector(".filters-form")
      ?.addEventListener("change", () => this.updateBadge())
  }

  open() { this.panelTarget.classList.add("open") }

  close() { this.panelTarget.classList.remove("open") }

  reset() {
    const form = this.element.querySelector(".filters-form")
    if (!form) return
    form.querySelectorAll("input[type='radio']").forEach(r => { r.checked = false })
    form.querySelectorAll("input[type='checkbox']").forEach(c => { c.checked = false })
    form.querySelectorAll("select").forEach(s => { s.selectedIndex = 0 })
    this.element.querySelectorAll(".mood-pill").forEach(p => p.classList.remove("is-active"))

    // Clear the artist/track seeds, which live in their own controller.
    const seedEl = this.element.querySelector("[data-controller~='seed-search']")
    if (seedEl) {
      this.application
        .getControllerForElementAndIdentifier(seedEl, "seed-search")
        ?.clear()
    }

    this.updateBadge()
  }

  surprise() {
    const form = this.element.querySelector(".filters-form")
    if (!form) return
    const diverse   = form.querySelector("input[name='diverse']")
    const discovery = form.querySelector("input[name='discovery']")
    if (diverse)   diverse.checked   = true
    if (discovery) discovery.checked = true
    form.submit()
  }

  initFinetune() {
    const toggle = this.element.querySelector("#finetune-toggle")
    const block  = this.element.querySelector("#finetune-block")
    if (!toggle || !block) return
    toggle.addEventListener("click", () => block.classList.toggle("is-open"))
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

    if (form.querySelector("input[name='genre']:checked")?.value) count++
    if (form.querySelector("input[name='mood']:checked")?.value) count++
    if (form.querySelector("input[name='decade']:checked")?.value) count++
    if (form.querySelector("input[name='tempo']:checked")?.value) count++

    const tr = form.querySelector("input[name='time_range']:checked")
    if (tr && tr.value !== "long_term") count++

    form.querySelectorAll("input[type='checkbox']:checked").forEach(() => count++)

    const seeds = form.querySelectorAll("input[name='seed_artists[]'], input[name='seed_tracks[]']")
    if (seeds.length > 0) count++

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
