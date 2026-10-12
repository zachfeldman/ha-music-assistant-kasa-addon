#!/bin/sh
# Same entrypoint as the base image (jemalloc preload for background-thread
# decay of idle RSS - see music-assistant/server's own Dockerfile), with
# `exec mass "$@"` swapped for the plugin-manager wrapper so ha-lights-sync
# gets discovered - see the Dockerfile's header comment for the whole
# story, including the one-time /data migration this used to also run
# (done, removed - see git history on this file if that's ever needed
# again for a similar cutover).
for path in /usr/lib/*/libjemalloc.so.2; do
    [ -f "$path" ] && export LD_PRELOAD="$path" MALLOC_CONF="background_thread:true,dirty_decay_ms:5000,muzzy_decay_ms:5000" && break
done

exec python -m music_assistant_plugin_manager "$@"
