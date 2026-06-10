---
name: deezer-preview-url-expiry
description: Audio previews come from Deezer (not Spotify) and the signed URLs expire within minutes — never cache them in the DB and serve them directly
metadata:
  type: project
---

Newsic's 30s audio previews come from **Deezer** (`dzcdn.net`), NOT Spotify — Spotify is only for OAuth login. Deezer preview URLs are signed with a fixed wall-clock `exp=` timestamp and die within minutes (observed: as little as ~15 min of remaining validity). An expired URL returns **HTTP 403**, so `<audio>.play()` rejects and the silent `.catch(() => {})` in [[swipe-controller]] hides it = "no sound" with no error.

The old bug: URLs were cached in `songs.preview_url` and only refreshed when the row was `> 3.hours` old (way longer than the ~15 min expiry), so previews were almost always dead. Verified on real DB: every song had a URL expired 75+ min ago.

**Fix (2026-06-10):** `GET /songs/:id/preview` (`SongsController#preview`) mints a fresh Deezer URL on every load via `DeezerService#fresh_preview_url` and 302-redirects to it (`allow_other_host: true`). All `<audio src>` / `data-preview` for persisted Songs point to `preview_song_path(song)`. Removed the broken `refresh_stale_previews` 3h logic from `SuggestionsController#show`.

**Why:** signed CDN URLs must be regenerated at play time, never persisted and served. **How to apply:** if adding a new preview player, route through `preview_song_path`, never embed `song.preview_url` directly.
