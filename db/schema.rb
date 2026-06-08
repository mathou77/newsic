# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_08_151130) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user1_id", null: false
    t.bigint "user2_id", null: false
    t.index ["user1_id", "user2_id"], name: "index_conversations_on_user1_id_and_user2_id", unique: true
    t.index ["user1_id"], name: "index_conversations_on_user1_id"
    t.index ["user2_id"], name: "index_conversations_on_user2_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.bigint "addressee_id", null: false
    t.datetime "created_at", null: false
    t.bigint "requester_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["addressee_id"], name: "index_friendships_on_addressee_id"
    t.index ["requester_id", "addressee_id"], name: "index_friendships_on_requester_id_and_addressee_id", unique: true
    t.index ["requester_id"], name: "index_friendships_on_requester_id"
  end

  create_table "message_reactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji", null: false
    t.bigint "message_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["message_id", "user_id", "emoji"], name: "index_message_reactions_on_message_id_and_user_id_and_emoji", unique: true
    t.index ["message_id"], name: "index_message_reactions_on_message_id"
    t.index ["user_id"], name: "index_message_reactions_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "read_at"
    t.bigint "song_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["song_id"], name: "index_messages_on_song_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "song_id", null: false
    t.integer "status"
    t.bigint "suggestion_id", null: false
    t.datetime "updated_at", null: false
    t.index ["song_id"], name: "index_playlists_on_song_id"
    t.index ["suggestion_id"], name: "index_playlists_on_suggestion_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "songs", force: :cascade do |t|
    t.string "album_name"
    t.string "artist"
    t.string "artist_picture"
    t.datetime "created_at", null: false
    t.bigint "deezer_id"
    t.integer "duration"
    t.boolean "explicit"
    t.string "genre"
    t.string "image_url"
    t.string "preview_url"
    t.integer "rank"
    t.string "release_date"
    t.string "spotify_id"
    t.string "spotify_uri"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "suggestions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "mood"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_suggestions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email"
    t.string "friend_code", null: false
    t.datetime "spotify_cache_refreshed_at"
    t.string "spotify_playlist_id"
    t.string "spotify_uid"
    t.jsonb "top_artists", default: [], null: false
    t.jsonb "top_genres", default: [], null: false
    t.jsonb "top_tracks", default: [], null: false
    t.datetime "updated_at", null: false
    t.index ["friend_code"], name: "index_users_on_friend_code", unique: true
    t.index ["spotify_uid"], name: "index_users_on_spotify_uid", unique: true
  end

  add_foreign_key "conversations", "users", column: "user1_id"
  add_foreign_key "conversations", "users", column: "user2_id"
  add_foreign_key "friendships", "users", column: "addressee_id"
  add_foreign_key "friendships", "users", column: "requester_id"
  add_foreign_key "message_reactions", "messages"
  add_foreign_key "message_reactions", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "songs"
  add_foreign_key "messages", "users"
  add_foreign_key "playlists", "songs"
  add_foreign_key "playlists", "suggestions"
  add_foreign_key "suggestions", "users"
end
