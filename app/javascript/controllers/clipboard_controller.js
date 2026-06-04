import { Controller } from "@hotwired/stimulus"

// Copies the controller's `text` value to the clipboard and briefly shows
// feedback on the clicked button.
export default class extends Controller {
  static values = { text: String }

  copy(event) {
    const btn = event.currentTarget
    navigator.clipboard.writeText(this.textValue).then(() => {
      const original = btn.textContent
      btn.textContent = "Copié !"
      btn.classList.add("is-copied")
      setTimeout(() => {
        btn.textContent = original
        btn.classList.remove("is-copied")
      }, 1500)
    })
  }
}
