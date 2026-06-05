import { Controller } from "@hotwired/stimulus"

// Toggles an emoji reaction. The server broadcasts the updated counter back to
// every participant (incl. us), so we don't touch the DOM here.
export default class extends Controller {
  static values = { messageId: Number }

  toggle(event) {
    const emoji = event.currentTarget.dataset.emoji
    fetch(`/messages/${this.messageIdValue}/reactions`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({ emoji })
    })
  }
}
