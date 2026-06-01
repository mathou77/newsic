class Suggestion < ApplicationRecord
  has_many :songs_suggestions
  has_many :songs, through: :songs_suggestions
end
