import { Controller } from "@hotwired/stimulus"

// Aligns message bubbles (mine vs theirs) using the sender id carried on each
// bubble, and keeps the thread scrolled to the latest message — including
// messages that arrive in real time via Turbo Stream broadcasts.
export default class extends Controller {
  static targets = ["messages"]
  static values = { currentUserId: Number }

  connect() {
    this.alignAll()
    this.scrollToBottom()

    this.observer = new MutationObserver(() => {
      this.alignAll()
      this.scrollToBottom()
    })
    this.observer.observe(this.messagesTarget, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  alignAll() {
    this.messagesTarget.querySelectorAll(".msg").forEach((msg) => {
      if (msg.dataset.aligned) return
      const mine = Number(msg.dataset.senderId) === this.currentUserIdValue
      msg.classList.add(mine ? "msg--mine" : "msg--theirs")
      msg.dataset.aligned = "1"
    })
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
