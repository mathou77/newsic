class SongsSuggestion < ApplicationRecord
  belongs_to :suggestion
  belongs_to :song
end
