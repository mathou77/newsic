class User < ApplicationRecord
  has_many :suggestions, dependent: :destroy

  # Friendships this user initiated / received.
  has_many :sent_friendships,
           class_name: "Friendship", foreign_key: :requester_id, dependent: :destroy
  has_many :received_friendships,
           class_name: "Friendship", foreign_key: :addressee_id, dependent: :destroy

  has_many :messages, dependent: :destroy

  validates :spotify_uid, presence: true, uniqueness: true

  # Crée ou met à jour un utilisateur à partir du payload OmniAuth Spotify.
  def self.from_omniauth(auth)
    user = find_or_initialize_by(spotify_uid: auth["uid"])
    user.display_name = auth["info"]["name"]
    user.email        = auth["info"]["email"]
    user.avatar_url   = auth["info"]["image"] if auth["info"]["image"].present?
    user.save!
    user
  end

  # --- Friends ---------------------------------------------------------------

  def friendship_with(other)
    Friendship.between(self, other)
  end

  def friends?(other)
    friendship_with(other)&.accepted?
  end

  # All users this person is friends with (accepted in either direction).
  def friends
    ids = Friendship.accepted
                    .where("requester_id = :id OR addressee_id = :id", id: id)
                    .pluck(:requester_id, :addressee_id)
                    .flatten.uniq - [id]
    User.where(id: ids)
  end

  # Incoming requests awaiting this user's response.
  def pending_received
    received_friendships.pending
  end

  # --- Profile ---------------------------------------------------------------

  def initials
    (display_name.presence || "?").split.map(&:first).first(2).join.upcase
  end
end
