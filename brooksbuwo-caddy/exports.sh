#!/usr/bin/env bash
# brooksbuwo-caddy/exports.sh
# Reads CF token from APP_DATA_DIR/cf-api-token (written by hooks/pre-start).
# SECURITY: do not hardcode the token here; this file is committed to the repo.
# Token lives in APP_DATA_DIR/data/ -- a subdir that ships EMPTY (only .gitkeep, which
# rsync excludes on install). Root-level files are owned by the repo template and get
# overwritten by umbreld's rsync overlay on every install; a subdir file is preserved.
# This mirrors the official cloudflared community app's token pattern.
if [ -f "${APP_DATA_DIR}/data/cf-api-token" ]; then
    export APP_CF_API_TOKEN="$(cat "${APP_DATA_DIR}/data/cf-api-token")"
else
    export APP_CF_API_TOKEN=""
    echo "WARNING: ${APP_DATA_DIR}/data/cf-api-token not found; CF_API_TOKEN will be empty" >&2
fi
