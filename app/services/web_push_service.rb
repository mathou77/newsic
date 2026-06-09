require "web_push"

class WebPushService
  VAPID_PUBLIC_KEY  = ENV.fetch("VAPID_PUBLIC_KEY", nil).freeze
  VAPID_PRIVATE_KEY = ENV.fetch("VAPID_PRIVATE_KEY", nil).freeze

  def self.notify(user:, title:, body:, url: "/", tag: "newsic")
    return if VAPID_PUBLIC_KEY.blank? || VAPID_PRIVATE_KEY.blank?

    payload = JSON.generate(title: title, body: body, url: url, tag: tag)

    user.push_subscriptions.find_each do |sub|
      WebPush.payload_send(
        message:  payload,
        endpoint: sub.endpoint,
        p256dh:   sub.p256dh,
        auth:     sub.auth,
        vapid: {
          subject:     "mailto:contact@newsic.app",
          public_key:  VAPID_PUBLIC_KEY,
          private_key: VAPID_PRIVATE_KEY
        }
      )
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      sub.destroy
    rescue => e
      Rails.logger.error "[WebPush] Failed for user #{user.id}: #{e.message}"
    end
  end
end
