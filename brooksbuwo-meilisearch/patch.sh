#!/bin/sh
# brooksbuwo-meilisearch/patch.sh
# Runs as the linkwarden-patcher sidecar entrypoint (alpine:3.21).
#
# Purpose: keep MEILI_HOST + MEILI_MASTER_KEY present on Linkwarden's `app` service in its
# app-data docker-compose.yml. umbreld overwrites that compose ONLY on a Linkwarden update
# (copy_app_files whitelist); this sidecar detects the overwrite via inotifywait and
# re-applies the two env vars, then restarts Linkwarden. It also self-heals once on startup
# to catch any overwrite missed while the sidecar was down (OS update / reboot).
#
# MEILI_HOST and MEILI_MASTER_KEY come from this container's own environment (set by
# docker-compose.yml), so no values are hardcoded here. The key is ALSO available at
# /meili-key/meili-master-key (read-only mount) as a fallback source.
set -e

COMPOSE=/watch/docker-compose.yml

# alpine:3.21 ships none of these; install at start. Rare event (only on container (re)start,
# i.e. OS update / reboot). Requires outbound internet (this home box has it). docker-cli
# provides the `docker compose` v2 plugin via the docker-cli-compose package.
echo "[patcher] installing inotify-tools yq docker-cli docker-cli-compose via apk..."
apk add --no-cache inotify-tools yq docker-cli docker-cli-compose >/dev/null 2>&1 \
  || apk add --no-cache inotify-tools yq docker-cli docker-cli-compose

# Fallback: if MEILI_MASTER_KEY was not passed via env, read it from the mounted keyfile.
if [ -z "${MEILI_MASTER_KEY:-}" ] && [ -f /meili-key/meili-master-key ]; then
    MEILI_MASTER_KEY="$(cat /meili-key/meili-master-key)"
    export MEILI_MASTER_KEY
fi

apply_patch() {
    # Guard: verify the 'app' service exists (future Linkwarden rename safety).
    if ! yq '.services | has("app")' "$COMPOSE" | grep -q true; then
        echo "[patcher] WARNING: no 'app' service in Linkwarden compose; skipping"
        return
    fi
    # Linkwarden's `environment` is a YAML block SEQUENCE ("- KEY=value" items), NOT a map.
    # So detect presence by scanning the list items for a MEILI_HOST= entry, and add missing
    # vars by APPENDING list items (+=) -- map assignment (.environment.KEY = v) would corrupt
    # a sequence. Verified against the live Linkwarden v2.14.1 app-data compose (env is a list).
    if yq '.services.app.environment[] | select(. == "MEILI_HOST=*")' "$COMPOSE" 2>/dev/null | grep -q "MEILI_HOST="; then
        echo "[patcher] MEILI_HOST already present; no-op"
        return
    fi
    echo "[patcher] MEILI_HOST missing, re-applying..."
    # strenv() reads the values from THIS container's env (docker-compose.yml sets them),
    # so the key never appears as a literal in this script.
    MEILI_HOST="$MEILI_HOST" MEILI_MASTER_KEY="$MEILI_MASTER_KEY" \
      yq -i '.services.app.environment += ["MEILI_HOST=" + strenv(MEILI_HOST), "MEILI_MASTER_KEY=" + strenv(MEILI_MASTER_KEY)]' "$COMPOSE"
    docker compose \
      --project-name linkwarden \
      --file "$COMPOSE" \
      up --detach --no-build
    echo "[patcher] patch applied; linkwarden restarted"
}

# Self-heal on startup (catches missed events during downtime).
apply_patch

# Watch for future close_write events (a Linkwarden update rewriting the compose).
echo "[patcher] watching $COMPOSE for updates..."
inotifywait -m -e close_write "$COMPOSE" | while read -r _dir _event _file; do
    sleep 3   # CRITICAL: wait for umbreld's patchComposeServices() second write to complete
    apply_patch
done
