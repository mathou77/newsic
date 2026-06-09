self.addEventListener("push", (event) => {
  if (!event.data) return

  const data = event.data.json()

  const options = {
    body:    data.body,
    icon:    "/icon.png",
    badge:   "/icon.png",
    data:    { url: data.url },
    actions: data.actions || [],
    tag:     data.tag || "newsic-notif",
    renotify: true
  }

  event.waitUntil(
    self.registration.showNotification(data.title, options)
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
