class Playlist < ApplicationRecord
  belongs_to :suggestion
  belongs_to :song

  enum :status, { pending: 0, liked: 1, disliked: 2 }
end
