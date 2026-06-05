class SongsController < ApplicationController
  # Track detail ("Learn More"): artist, genre, preview.
  def show
    @song = Song.find(params[:id])
  end
end
