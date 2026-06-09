class User < ApplicationRecord
  # Unambiguous alphabet (no O/0/I/1/L) for human-shareable friend codes.
  FRIEND_CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789".chars.freeze

  before_create :assign_friend_code

  has_many :suggestions, dependent: :destroy

  # Friendships this user initiated / received.
  has_many :sent_friendships,
           class_name: "Friendship", foreign_key: :requester_id, dependent: :destroy
  has_many :received_friendships,
           class_name: "Friendship", foreign_key: :addressee_id, dependent: :destroy

  has_many :messages, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :sent_notifications, class_name: "Notification", foreign_key: :actor_id, dependent: :destroy

  validates :spotify_uid, presence: true, uniqueness: true
  validates :friend_code, uniqueness: true, allow_nil: true

  # Normalizes user input ("#7g2k9q ", "7G2K9Q") to a comparable code.
  def self.normalize_code(input)
    input.to_s.delete("#").strip.upcase
  end

  def self.find_by_code(input)
    find_by(friend_code: normalize_code(input))
  end

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

  private

  def assign_friend_code
    return if friend_code.present?

    loop do
      self.friend_code = Array.new(6) { FRIEND_CODE_ALPHABET.sample }.join
      break unless User.exists?(friend_code: friend_code)
    end
  end
end
