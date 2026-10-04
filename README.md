# ha-music-assistant-kasa-addon

A Home Assistant add-on repository holding two builds of Music Assistant,
both with [ha-lights-sync](https://github.com/zachfeldman/ha-lights-sync)
loaded via [music-assistant-plugin-manager](https://github.com/TigreGotico/music-assistant-plugin-manager)
(no change to Music Assistant's own source tree - see that project's
README for why a plugin needs loading this way rather than installing
cleanly into the stock app).

## `music_assistant/` - the permanent instance

Replaces the official "Music Assistant" app as of 2026-10-04. Starts from
the official app's own real `/data` (library, Spotify/Sendspin/Cast state,
playlists, settings), migrated in via a one-time copy wired into
`entrypoint.sh`, not Supervisor's backup/restore (which can't move an
add-on's data to a different slug - see the Dockerfile's header comment for
why and the full trace). Everything else about it - version, behavior,
UI - matches the official app; the only addition is ha-lights-sync.

## `music_assistant_kasa/` - the original test build

Kept around as a rollback / isolated test environment. Starts with its own
empty `/data`, independent of both the official app and `music_assistant/`
above - a Spotify login or light selection made here doesn't affect either
of the others. This is where ha-lights-sync was originally developed and
tested against a real garage speaker before becoming the permanent
instance.

## Installing this repository

Add this repository in Home Assistant under Settings → Add-ons → Add-on
Store → ⋮ → Repositories, or via the Supervisor API
(`POST /store/repositories` with `{"repository": "<this repo's URL>"}`).
