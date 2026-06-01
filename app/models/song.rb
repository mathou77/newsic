class Song < ApplicationRecord
  has_many :songs_suggestions
  has_many :suggestions, through: :songs_suggestions
end
