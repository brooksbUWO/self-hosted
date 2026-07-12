#!/usr/bin/env bash
# brooksbuwo-meilisearch/exports.sh
# Exports APP_BROOKSBUWO_MEILISEARCH_MASTER_KEY for docker-compose.yml
# (MEILI_MASTER_KEY on the meilisearch + linkwarden-patcher services).
#
# CRITICAL: umbreld sources this file under `set -u` at a point where APP_DATA_DIR may be
# UNBOUND (it is not exported for the first source in app-script). Referencing a bare
# ${APP_DATA_DIR} there aborts the whole install with "APP_DATA_DIR: unbound variable"
# (exit 1). Always use the ${APP_DATA_DIR:-} default form so this file is safe to source
# before APP_DATA_DIR is set. On the later source (during start_app, when APP_DATA_DIR IS
# set) the key is read correctly. See brooksbuwo-caddy/exports.sh for the same trap.
#
# SECURITY: never hardcode the key here; this file is committed to the public repo.
# The master key lives at ${APP_DATA_DIR}/data/meili-key/meili-master-key -- a subdir that
# ships EMPTY (only .gitkeep, excluded by umbreld's rsync) so a key written there survives
# the install-time rsync overlay. This mirrors the brooksbuwo-caddy cf-api-token pattern.
_key_file="${APP_DATA_DIR:-}/data/meili-key/meili-master-key"
if [ -n "${APP_DATA_DIR:-}" ] && [ -f "$_key_file" ]; then
    export APP_BROOKSBUWO_MEILISEARCH_MASTER_KEY="$(cat "$_key_file")"
else
    export APP_BROOKSBUWO_MEILISEARCH_MASTER_KEY=""
fi
