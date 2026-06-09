self.addEventListener("push", (event) => {
  if (!event.data) return

  const data = event.data.json()

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      // App is open and focused — the in-app toast handles it, skip native notification
      const appFocused = clientList.some((c) => c.focused)
      if (appFocused) return

      return self.registration.showNotification(data.title, {
        body:     data.body,
        icon:     "/icon.png",
        badge:    "/icon.png",
        data:     { url: data.url },
        tag:      data.tag || "newsic-notif",
        renotify: true
      })
    })
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  const url = event.notification.data?.url || "/"

  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        const clientPath = new URL(client.url).pathname
        const targetPath = new URL(url, self.location.origin).pathname
        if (clientPath === targetPath && "focus" in client) return client.focus()
      }
      if (clients.openWindow) return clients.openWindow(url)
    })
  )
})
