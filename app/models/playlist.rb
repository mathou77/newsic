class Playlist < ApplicationRecord
  belongs_to :suggestion
  belongs_to :song
end
