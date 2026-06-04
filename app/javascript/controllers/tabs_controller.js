import { Controller } from "@hotwired/stimulus"

// Simple client-side tab switcher (All / Friends / Requests).
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const name = event.currentTarget.dataset.tab
    this.tabTargets.forEach((t) => t.classList.toggle("is-active", t.dataset.tab === name))
    this.panelTargets.forEach((p) => { p.hidden = p.dataset.tab !== name })
  }
}
