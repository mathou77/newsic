import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { messageId: Number }
  static targets = ["picker"]

  connect() {
    this._closeHandler = (e) => {
      if (!this.element.contains(e.target)) this.closePicker()
    }
    document.addEventListener("click", this._closeHandler)
  }

  disconnect() {
    document.removeEventListener("click", this._closeHandler)
  }

  togglePicker(e) {
    e.stopPropagation()
    this.pickerTarget.classList.toggle("reaction-picker--open")
  }

  closePicker() {
    this.pickerTarget.classList.remove("reaction-picker--open")
  }

  pick(event) {
    const emoji = event.currentTarget.dataset.emoji
    fetch(`/messages/${this.messageIdValue}/reactions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ emoji })
    })
    this.closePicker()
  }
}
