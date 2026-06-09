class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, :p256dh, :auth, presence: true

  def to_web_push_subscription
    {
      endpoint: endpoint,
      keys: { p256dh: p256dh, auth: auth }
    }
  end
end
