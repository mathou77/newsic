import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replyForm", "replyToggle"]

  // Called by the bell button in the bottom nav.
  // The bell is outside this controller's element, so we look up the panel by ID.
  toggle() {
    const panel = document.getElementById("notifications_panel")
    if (!panel) return
    const isOpen = panel.classList.contains("notif-panel--open")
    isOpen ? this._close(panel) : this._open(panel)
  }

  close() {
    const panel = document.getElementById("notifications_panel")
    if (panel) this._close(panel)
  }

  // Show/hide the quick-reply form for a given notification.
  toggleReply(event) {
    const id = event.currentTarget.dataset.notifId
    const form = this.replyFormTargets.find(el => el.dataset.notifId === id)
    if (!form) return
    form.hidden = !form.hidden
    if (!form.hidden) form.querySelector("input")?.focus()
  }

  _open(panel) {
    panel.classList.add("notif-panel--open")
  }

  _close(panel) {
    panel.classList.remove("notif-panel--open")
  }
}
