import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: { type: Number, default: 4500 } }

  connect() {
    requestAnimationFrame(() => this.element.classList.add("notif-toast--visible"))
    if (this.durationValue > 0) {
      this._timer = setTimeout(() => this.dismiss(), this.durationValue)
    }
  }

  disconnect() {
    clearTimeout(this._timer)
  }

  dismiss() {
    clearTimeout(this._timer)
    this.element.classList.remove("notif-toast--visible")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
