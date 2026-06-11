import { Controller } from "@hotwired/stimulus"

// Aligns message bubbles (mine vs theirs) using the sender id carried on each
// bubble, and keeps the thread scrolled to the latest message — including
// messages that arrive in real time via Turbo Stream broadcasts.
export default class extends Controller {
  static targets = ["messages"]
  static values = { currentUserId: Number }

  connect() {
    this.alignAll()
    this.groupMessages()
    this.addDateSeparators()
    this.scrollToBottom()

    this.observer = new MutationObserver(() => {
      this.alignAll()
      this.groupMessages()
      this.addDateSeparators()
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

  groupMessages() {
    const msgs = Array.from(this.messagesTarget.querySelectorAll(".msg"))
    msgs.forEach((msg, i) => {
      const next = msgs[i + 1]
      const isLastInGroup = !next ||
        next.dataset.senderId !== msg.dataset.senderId ||
        Number(next.dataset.timestamp) - Number(msg.dataset.timestamp) >= 300
      msg.classList.toggle("msg--grouped", !isLastInGroup)
    })
  }

  addDateSeparators() {
    this.messagesTarget.querySelectorAll(".msg-date-sep").forEach(el => el.remove())

    const msgs = Array.from(this.messagesTarget.querySelectorAll(".msg"))
    msgs.forEach((msg, i) => {
      const ts = Number(msg.dataset.timestamp)
      const prev = msgs[i - 1]
      const prevTs = prev ? Number(prev.dataset.timestamp) : null

      if (i === 0 || ts - prevTs > 3600) {
        const sep = document.createElement("div")
        sep.className = "msg-date-sep"
        sep.textContent = this.formatMsgDate(new Date(ts * 1000))
        msg.parentNode.insertBefore(sep, msg)
      }
    })
  }

  formatMsgDate(date) {
    const now = new Date()
    const sevenDaysAgo = new Date(now - 7 * 24 * 60 * 60 * 1000)
    const hh = String(date.getHours()).padStart(2, "0")
    const mm = String(date.getMinutes()).padStart(2, "0")

    if (date >= sevenDaysAgo) {
      const days = ["Dimanche", "Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi"]
      return `${days[date.getDay()]} ${hh}:${mm}`
    } else {
      const months = ["janvier", "février", "mars", "avril", "mai", "juin",
                      "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
      return `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`
    }
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
