class Friendship < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :addressee, class_name: "User"

  enum :status, { pending: 0, accepted: 1 }

  validates :requester_id, uniqueness: { scope: :addressee_id }
  validate  :not_self

  # The friendship between two users, regardless of who sent the request.
  def self.between(a, b)
    where(requester: a, addressee: b).or(where(requester: b, addressee: a)).first
  end

  # The other party from a given user's point of view.
  def other_than(user)
    requester_id == user.id ? addressee : requester
  end

  private

  def not_self
    errors.add(:addressee, "ne peut pas être soi-même") if requester_id == addressee_id
  end
end
