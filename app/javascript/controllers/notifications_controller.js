import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["replyForm"]

  connect() {
    this._requestPushPermission()
  }

  // Show/hide the quick-reply form for a notification (used from inside a toast).
  toggleReply(event) {
    const id = event.currentTarget.dataset.notifId
    const form = this.replyFormTargets.find(el => el.dataset.notifId === id)
    if (!form) return
    form.hidden = !form.hidden
    if (!form.hidden) form.querySelector("input")?.focus()
  }

  async _requestPushPermission() {
    if (!("serviceWorker" in navigator) || !("PushManager" in window)) return

    let permission = Notification.permission
    if (permission === "denied") return

    if (permission === "default") {
      permission = await Notification.requestPermission()
    }
    if (permission !== "granted") return

    try {
      const reg = await navigator.serviceWorker.ready
      let sub = await reg.pushManager.getSubscription()
      if (!sub) {
        const vapidPublicKey = document.querySelector('meta[name="vapid-public-key"]')?.content
        sub = await reg.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this._urlBase64ToUint8Array(vapidPublicKey)
        })
      }
      this._saveSubscription(sub)
    } catch (err) {
      console.warn("[Push] Subscribe failed:", err)
    }
  }

  _saveSubscription(sub) {
    const json = sub.toJSON()
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    fetch("/push_subscriptions", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrf },
      body: JSON.stringify({ subscription: { endpoint: json.endpoint, keys: json.keys } })
    })
  }

  _urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const raw = atob(base64)
    return Uint8Array.from([...raw].map(c => c.charCodeAt(0)))
  }
}
