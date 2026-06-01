class Suggestion < ApplicationRecord
  belongs_to :user
  has_many :songs_suggestions
  has_many :songs, through: :songs_suggestions
end
