# syntax=docker/dockerfile:1
#
# Music Assistant 2.10.6, stock, plus ha-lights-sync loaded via
# music-assistant-plugin-manager's entrypoint discovery (no changes to
# Music Assistant's own source tree - see that project's README for why).
# Launch command swaps `mass` for `python -m music_assistant_plugin_manager`,
# which patches provider discovery then calls straight into Music
# Assistant's own main() - same args, same behavior otherwise. See
# https://github.com/zachfeldman/ha-lights-sync for the plugin itself and
# https://github.com/TigreGotico/music-assistant-plugin-manager for the
# loader this depends on.
#
# This is the PERMANENT replacement for the official "Music Assistant" app
# (d5369777_music_assistant), not a test build (see music_assistant_kasa/
# in this same repo for that, kept around as a rollback). Its /data started
# as a one-time copy of the official app's own real /data on 2026-10-04
# (entrypoint.sh had a migration step for this, since removed - see git
# history on this file/README for how and why: Supervisor's backup/restore
# API only restores an add-on's data back into an add-on with the exact
# same slug it was backed up from, and a custom-repo add-on can never
# acquire the official add-on's slug). That migration is done and
# confirmed stable; entrypoint.sh is back to a plain pass-through.
#
# Bumped 2.10.4 -> 2.10.6 (2026-10-12) to pick up upstream fixes directly in
# the WiiM-Sendspin grouping path we hit live: a WiiM grouped with a native
# Sendspin device (via the AirPlay-Sendspin bridge) switches its own output
# protocol correctly and plays, but the other, native-Sendspin member of the
# group goes completely silent - confirmed with the server's own debug log
# (set_members/protocol-grouping lines show the bridge's group gaining the
# native client, but nothing ever addresses that client again once playback
# starts). Candidate fixes already in 2.10.6 and not in 2.10.4: #6474 "Fix a
# speaker group going silent when one room is powered off while another
# joins", #6510 "Fix a play command on a synced speaker locking up during a
# group change", #6505 same for an announcement, #6530 "Fix external
# playback not tracked after a player leaves a Sendspin group". None of
# those descriptions are a verbatim match for our symptom, so this bump is a
# bet, not a confirmed fix - re-test the exact repro (group a WiiM with a
# native Sendspin player, play, check both sides) after it deploys, and if
# the Sendspin side is still silent, the actual bug needs a real patch
# against music_assistant/controllers/players/protocol_linking.py and/or
# providers/sendspin/player.py instead.
FROM ghcr.io/music-assistant/server:2.10.6

# pip's git+https installer needs the `git` binary; the final server image
# doesn't carry one (git only lives in its disposable builder stage).
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ha-lights-sync isn't published to PyPI yet (still in active development -
# see its own repo's Status note), so install it straight from GitHub. Once
# it's published this can switch to a plain `ha-lights-sync` pin.
#
# Pinned to a commit (not a floating branch) for two reasons: reproducible
# builds, and because `RUN pip install ...@git+https://...` caches by the
# *command text*, not the remote repo's current content - a plain branch
# URL across two builds can silently serve yesterday's code from Docker's
# layer cache. Bump this SHA (from the ha-lights-sync repo) to pick up new
# commits; a `rebuild` alone will not.
#
# Bumped 451cc885 -> 52a45628 (2026-10-19) for add-sound-mode-control:
# color_mode becomes changeable from Home Assistant's own Sound Mode
# selector (media_player dropdown / select_sound_mode service), not just
# from Music Assistant's own settings page - see that commit's message in
# the ha-lights-sync repo for how (an instance-level monkey-patch of this
# bridge's own visualizer Player object, since this package can't modify
# Music Assistant's own installed source). Branched from 451cc885 itself
# (this Dockerfile's previous pin), not ha-lights-sync's later history, so
# this bump is ONLY that one feature - it deliberately does not also pull
# in that repo's later energetic/auto/strobe removal or render-loop
# heartbeat logging, which weren't part of this change.
#
# Bumped 52a45628 -> cb500ddb (2026-10-19, same day) still on
# add-sound-mode-control: brightness/Speed/transition style/sensitivity/
# Lock color/locked hue/restore-on-stop become controllable from Home
# Assistant too, via dedicated input_number/input_select/input_boolean
# helper entities this bridge seeds and two-way syncs itself (see that
# commit's message - Sound Mode was already spent on color_mode, and HA's
# own music_assistant integration doesn't surface Music Assistant's
# PlayerFeature.OPTIONS at all, so there was no media_player slot left for
# the rest of these). Requires the garage-media dashboard's matching
# input_number/input_select/input_boolean helpers (personal-ha-configuration
# repo, configuration.yaml) to already exist in Home Assistant - deployed
# there first, same day.
#
# Rolled BACK cb500ddb -> 52a45628 (2026-10-19, same day, ~4.5h later) as a
# diagnostic step: right after the cb500ddb deploy, grouping
# media_player.ha_lights_ha_lights_sync into media_player.garage_speaker
# started failing - Music Assistant's player controller logs "Player HA
# Lights: HA Lights Sync can not be grouped with Garage speaker"
# (music_assistant/controllers/players/controller.py's can_group_with
# check), both from the garage_speaker_group_ungroup_ha_lights_sync HA
# automation's own media_player.join call and from a manual attempt in the
# Music Assistant UI. cb500ddb's diff (bridge.py/provider.py) doesn't touch
# player registration, Sendspin/Chromecast linking, or can_group_with at
# all - only adds a subscribe_entities listener and HA helper-entity
# service calls - so there's no obvious mechanism by which it should cause
# this, but it's the only thing that changed. This rollback is to confirm
# whether 52a45628 alone (without cb500ddb's changes) restores grouping; if
# it does NOT, the regression is unrelated to ha-lights-sync entirely (a
# Music Assistant / Sendspin-Chromecast bridging issue instead - see this
# repo's prior WiiM-Sendspin grouping bug note). If it DOES, re-examine
# cb500ddb for a real (if non-obvious) side effect before re-deploying it.
#
# `--python $VIRTUAL_ENV/bin/python` matters: plain `pip install` here installs
# into the SYSTEM Python, not $VIRTUAL_ENV (the venv the base image actually
# runs from and that `mass`/our entrypoint invoke) - the venv has no `pip`
# binary of its own (the base image's builder stage populates it with `uv`,
# not pip), so a bare `pip install` silently lands somewhere the running
# server never sees. Caught this on the first real deploy: `mass` started but
# immediately failed with "No module named music_assistant_plugin_manager".
RUN pip --python "$VIRTUAL_ENV/bin/python" install --no-cache-dir \
    "ha-lights-sync @ git+https://github.com/zachfeldman/ha-lights-sync.git@52a456286076d72055654d69443312c14eee1078" \
    music-assistant-plugin-manager

# Same entrypoint as the base image (jemalloc preload for background-thread
# decay of idle RSS - see music-assistant/server's own Dockerfile), with
# `exec mass "$@"` swapped for the plugin-manager wrapper, plus a one-time
# data migration that runs before either - see entrypoint.sh, kept as a
# plain file (not generated inline via printf) so it's reviewable/diffable
# and immune to shell-escaping mistakes in the Dockerfile itself.
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "--data-dir", "/data", "--cache-dir", "/data/.cache"]
