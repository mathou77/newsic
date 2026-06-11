import { Controller } from "@hotwired/stimulus"

// Aligns message bubbles (mine vs theirs), groups consecutive messages from the
// same sender, inserts date separators, and keeps the thread pinned to the
// bottom — including messages that arrive in real time via Turbo Stream.
export default class extends Controller {
  static targets = ["messages"]
  static values = { currentUserId: Number, conversationId: Number }

  connect() {
    this.render()
    this.scrollToBottom()

    this.observer = new MutationObserver(() => {
      this.render()
      this.scrollToBottom()
    })
    this.observer.observe(this.messagesTarget, { childList: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  // Re-apply all visual decorations. We pause the observer while we write to the
  // DOM ourselves (separators are real nodes) so our own edits don't retrigger
  // the observer in an infinite loop.
  render() {
    this.observer?.disconnect()
    this.pruneForeign()
    this.alignAll()
    this.groupMessages()
    this.addDateSeparators()
    this.observer?.observe(this.messagesTarget, { childList: true })
  }

  // The recipient subscribes to a per-user stream, so a message landing in
  // another open conversation could leak in here — drop anything that isn't
  // ours.
  pruneForeign() {
    if (!this.hasConversationIdValue) return
    this.messagesTarget.querySelectorAll(".msg").forEach((msg) => {
      const cid = msg.dataset.conversationId
      if (cid && Number(cid) !== this.conversationIdValue) msg.remove()
    })
  }

  // Clear the input the instant the send round-trips, keeping focus so the user
  // can keep firing off messages without losing a beat.
  resetForm(event) {
    if (event.detail?.success === false) return
    const input = this.element.querySelector(".chat-form__input")
    if (input) {
      input.value = ""
      input.focus()
    }
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
    this.messagesTarget.querySelectorAll(".msg-date-sep").forEach((el) => el.remove())

    const msgs = Array.from(this.messagesTarget.querySelectorAll(".msg"))
    msgs.forEach((msg, i) => {
      const ts = Number(msg.dataset.timestamp)
      const prevTs = i > 0 ? Number(msgs[i - 1].dataset.timestamp) : null

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
    }

    const months = ["janvier", "février", "mars", "avril", "mai", "juin",
                    "juillet", "août", "septembre", "octobre", "novembre", "décembre"]
    return `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
