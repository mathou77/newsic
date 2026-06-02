class Song < ApplicationRecord
  has_many :playlists
  has_many :suggestions, through: :playlists
end
