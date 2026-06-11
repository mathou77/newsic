namespace :songs do
  desc "Backfill the ambient dominant_color for songs that have a cover but no colour yet"
  task backfill_colors: :environment do
    scope = Song.where(dominant_color: nil).where.not(image_url: [nil, ""])
    total = scope.count
    puts "Extracting colours for #{total} song(s)…"

    scope.find_each.with_index(1) do |song, i|
      ExtractDominantColorJob.perform_now(song.id)
      print "\r#{i}/#{total}" if (i % 10).zero? || i == total
    end
    puts "\nDone."
  end
end
