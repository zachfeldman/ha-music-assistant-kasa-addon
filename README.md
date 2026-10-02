# ha-music-assistant-kasa-addon

A **temporary** Home Assistant add-on repository holding one test build:
Music Assistant 2.10.4 with [kasa-lights-sync](https://github.com/zachfeldman/kasa-lights-sync)
loaded via [music-assistant-plugin-manager](https://github.com/TigreGotico/music-assistant-plugin-manager),
to verify real-time Kasa light sync against a real garage speaker before
deciding whether to run it long-term.

This add-on starts with its own empty `/data` - it does not share state
(library, Spotify auth, paired players) with the official Music Assistant
app. See `music_assistant_kasa/config.yaml`'s description for details.

Add this repository in Home Assistant under Settings → Add-ons → Add-on
Store → ⋮ → Repositories, or via the Supervisor API
(`POST /store/repositories` with `{"repository": "<this repo's URL>"}`).
