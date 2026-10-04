#!/bin/sh
# Same entrypoint as the base image (jemalloc preload for background-thread
# decay of idle RSS - see music-assistant/server's own Dockerfile), with
# `exec mass "$@"` swapped for the plugin-manager wrapper, plus a one-time
# data migration that runs before either. See this Dockerfile's header
# comment for why the migration exists and its TODO for when to remove it.
for path in /usr/lib/*/libjemalloc.so.2; do
    [ -f "$path" ] && export LD_PRELOAD="$path" MALLOC_CONF="background_thread:true,dirty_decay_ms:5000,muzzy_decay_ms:5000" && break
done

# One-time migration from the official add-on. MIGRATION_SRC only exists
# because it was placed there once, by hand, in the shared backup mount,
# during the cutover - a fresh install of this add-on on any other system
# has no such directory and this block is a complete no-op. Gated on
# MIGRATION_MARKER (written to the PERSISTED /data volume, so it survives
# every future restart/update/rebuild of this add-on) so this can never
# fire a second time and overwrite real data created since the migration.
MIGRATION_SRC="/backup/real_ma_migration/data"
MIGRATION_MARKER="/data/.migrated_from_official_addon"
if [ -d "$MIGRATION_SRC" ] && [ ! -f "$MIGRATION_MARKER" ]; then
    echo "One-time migration: copying real Music Assistant data from $MIGRATION_SRC into /data"
    cp -a "$MIGRATION_SRC"/. /data/
    touch "$MIGRATION_MARKER"
    echo "Migration complete"
fi

exec python -m music_assistant_plugin_manager "$@"
