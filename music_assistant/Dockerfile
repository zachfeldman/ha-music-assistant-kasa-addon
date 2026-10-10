# syntax=docker/dockerfile:1
#
# Music Assistant 2.10.4, stock, plus ha-lights-sync loaded via
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
# in this same repo for that, kept around as a rollback). Migrated from the
# official app's real /data on 2026-10-04 via the one-time copy in
# entrypoint.sh below, since Supervisor's backup/restore API only restores
# an add-on's data back into an add-on with the exact same slug it was
# backed up from (confirmed against the documented
# /backups/{slug}/restore/partial schema - no remap/rename parameter
# exists), and a custom-repo add-on can never acquire the official add-on's
# slug (slugs are <sha of the registering repo URL>_<config slug>, and
# that repo is music-assistant/home-assistant-addon, not this one).
#
# TODO once the migration is confirmed stable over a few days: delete the
# "One-time migration" block in entrypoint.sh below and remove `backup:rw`
# from config.yaml's map - neither is needed again after the first boot,
# and there's no reason for this add-on to keep read/write access to every
# Home Assistant backup indefinitely.
FROM ghcr.io/music-assistant/server:2.10.4

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
# `--python $VIRTUAL_ENV/bin/python` matters: plain `pip install` here installs
# into the SYSTEM Python, not $VIRTUAL_ENV (the venv the base image actually
# runs from and that `mass`/our entrypoint invoke) - the venv has no `pip`
# binary of its own (the base image's builder stage populates it with `uv`,
# not pip), so a bare `pip install` silently lands somewhere the running
# server never sees. Caught this on the first real deploy: `mass` started but
# immediately failed with "No module named music_assistant_plugin_manager".
RUN pip --python "$VIRTUAL_ENV/bin/python" install --no-cache-dir \
    "ha-lights-sync @ git+https://github.com/zachfeldman/ha-lights-sync.git@451cc885784e1c297453a63e0c7fb4c6d7a81a1e" \
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
