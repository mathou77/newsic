import { Controller } from "@hotwired/stimulus"

// Slide-up sheet to share the current swipe track with one or more friends.
export default class extends Controller {
  static targets = ["sheet", "panel", "friend", "search", "message", "toast"]
  static values = { url: String }

  open(event) {
    this.songId = event.currentTarget.dataset.songId
    this.selected = new Set()
    this.friendTargets.forEach((f) => f.classList.remove("is-selected"))
    if (this.hasMessageTarget) this.messageTarget.value = ""
    if (this.hasSearchTarget) this.searchTarget.value = ""
    this.filter()
    this.sheetTarget.hidden = false
    requestAnimationFrame(() => this.sheetTarget.classList.add("is-open"))
  }

  close() {
    this.sheetTarget.classList.remove("is-open")
    setTimeout(() => { this.sheetTarget.hidden = true }, 250)
  }

  toggleFriend(event) {
    const btn = event.currentTarget
    const id = btn.dataset.friendId
    if (this.selected.has(id)) {
      this.selected.delete(id)
      btn.classList.remove("is-selected")
    } else {
      this.selected.add(id)
      btn.classList.add("is-selected")
    }
  }

  filter() {
    const q = (this.hasSearchTarget ? this.searchTarget.value : "").trim().toLowerCase()
    this.friendTargets.forEach((f) => { f.hidden = q && !f.dataset.name.includes(q) })
  }

  send() {
    if (!this.selected || this.selected.size === 0) return
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify({
        song_id: this.songId,
        friend_ids: [...this.selected],
        body: this.hasMessageTarget ? this.messageTarget.value : null
      })
    }).then(() => {
      this.close()
      this.showToast()
    })
  }

  // Swipe-down-to-dismiss, dragged from the top handle.
  dragStart(event) {
    this.startY = event.touches[0].clientY
    this.dragging = true
    if (this.hasPanelTarget) this.panelTarget.style.transition = "none"
  }

  dragMove(event) {
    if (!this.dragging) return
    const dy = event.touches[0].clientY - this.startY
    if (dy > 0 && this.hasPanelTarget) {
      this.panelTarget.style.transform = `translateX(-50%) translateY(${dy}px)`
    }
  }

  dragEnd(event) {
    if (!this.dragging) return
    this.dragging = false
    const dy = event.changedTouches[0].clientY - this.startY
    if (this.hasPanelTarget) {
      this.panelTarget.style.transition = ""
      this.panelTarget.style.transform = ""
    }
    if (dy > 100) this.close()
  }

  showToast() {
    if (!this.hasToastTarget) return
    this.toastTarget.hidden = false
    requestAnimationFrame(() => this.toastTarget.classList.add("is-visible"))
    setTimeout(() => {
      this.toastTarget.classList.remove("is-visible")
      setTimeout(() => { this.toastTarget.hidden = true }, 300)
    }, 1800)
  }
}
