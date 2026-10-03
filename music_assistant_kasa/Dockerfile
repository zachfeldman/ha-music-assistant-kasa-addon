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
    "ha-lights-sync @ git+https://github.com/zachfeldman/ha-lights-sync.git@4cbf5fc6d540f6cfc278976b171586e70e749ee7" \
    music-assistant-plugin-manager

# Same entrypoint as the base image (jemalloc preload for background-thread
# decay of idle RSS - see music-assistant/server's own Dockerfile), with
# `exec mass "$@"` swapped for the plugin-manager wrapper.
RUN printf '#!/bin/sh\n\
for path in /usr/lib/*/libjemalloc.so.2; do\n\
    [ -f "$path" ] && export LD_PRELOAD="$path" MALLOC_CONF="background_thread:true,dirty_decay_ms:5000,muzzy_decay_ms:5000" && break\n\
done\n\
exec python -m music_assistant_plugin_manager "$@"\n' > /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh", "--data-dir", "/data", "--cache-dir", "/data/.cache"]
