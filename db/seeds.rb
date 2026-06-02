# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Cleaning database..."

Playlist.destroy_all
Suggestion.destroy_all
Song.destroy_all

puts "Creating songs..."

songs = [
  {
    title: "Odd Look",
    artist: "Kavinsky",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/8d1b92f6c84bb2dfdc7d0c5d7f939574/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-3.dzcdn.net/stream/c-3d2f91f6a86dd71a2b81a78c3abda7d5-4.mp3",
    deezer_id: 64920072,
    genre: "Synthwave"
  },
  {
    title: "Nightcall",
    artist: "Kavinsky",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/3b7f64e19851f3f6b5cc9c97a7e6f287/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-9.dzcdn.net/stream/c-9c9ab9e9c6d5f1a12b3f4c1dbd2a0a97-4.mp3",
    deezer_id: 13566521,
    genre: "Synthwave"
  },
  {
    title: "Midnight City",
    artist: "M83",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/4e98c207c6427d7c59b32ff3b6a3fca4/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-0.dzcdn.net/stream/c-0c5cf96debd57b9db733b2f0c3f1e5de-5.mp3",
    deezer_id: 15665839,
    genre: "Electronic"
  },
  {
    title: "Instant Crush",
    artist: "Daft Punk",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/0f7f8906a944ce0f7fdfeab134a7d56b/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-8.dzcdn.net/stream/c-86f65c25b8c5ef48a5f0c95b5fbbd063-7.mp3",
    deezer_id: 67238745,
    genre: "Electronic"
  },
  {
    title: "Blinding Lights",
    artist: "The Weeknd",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/9f72b42e4c6e0dc0a74d6f0ed2452a0e/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-1.dzcdn.net/stream/c-1fdcb09e72eeb04d1d024c8c15b8cde1-6.mp3",
    deezer_id: 908604612,
    genre: "Pop"
  },
  {
    title: "Electric Feel",
    artist: "MGMT",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/7c170b98f5f7dd6a2f27fa253dba9fd9/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-4.dzcdn.net/stream/c-42fcb71d3907ad5f2d37fdc2375d1b2a-5.mp3",
    deezer_id: 3152166,
    genre: "Indie"
  },
  {
    title: "Sweet Disposition",
    artist: "The Temper Trap",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/84f1037c7285c0c3ddc03a2fa0ef8915/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-2.dzcdn.net/stream/c-2bb03f53f54dd47f50edcb3a58f9b0a1-3.mp3",
    deezer_id: 5633981,
    genre: "Indie Rock"
  },
  {
    title: "Tadow",
    artist: "Masego",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/2f24df45f52dd43075f9bb3e6c95b600/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-5.dzcdn.net/stream/c-5e82af1d89ddbc3bc59b3b8d2ea42f6d-6.mp3",
    deezer_id: 417340692,
    genre: "Jazz / R&B"
  },
  {
    title: "Space Song",
    artist: "Beach House",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/7c6aee55b99670f8d0f1f40c1ef81050/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-6.dzcdn.net/stream/c-61e7e5b027a49f2e84f7c0e0c03bc2f0-4.mp3",
    deezer_id: 110973398,
    genre: "Dream Pop"
  },
  {
    title: "Do I Wanna Know?",
    artist: "Arctic Monkeys",
    image_url: "https://e-cdns-images.dzcdn.net/images/cover/8f7f0b64c241ec9be4b3d5db930689c1/500x500-000000-80-0-0.jpg",
    preview_url: "https://cdns-preview-7.dzcdn.net/stream/c-74c91d9a8360c2ec7a3c2ea5eb0c7c43-6.mp3",
    deezer_id: 69839362,
    genre: "Rock"
  }
]

songs.each do |song_attributes|
  Song.create!(song_attributes)
end

puts "Created #{Song.count} songs!"
