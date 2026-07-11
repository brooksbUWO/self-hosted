#!/usr/bin/env bash
# brooksbuwo-caddy/exports.sh
# Reads CF token from APP_DATA_DIR/cf-api-token (written by hooks/pre-start).
# SECURITY: do not hardcode the token here; this file is committed to the repo.
if [ -f "${APP_DATA_DIR}/cf-api-token" ]; then
    export APP_CF_API_TOKEN="$(cat "${APP_DATA_DIR}/cf-api-token")"
else
    export APP_CF_API_TOKEN=""
    echo "WARNING: ${APP_DATA_DIR}/cf-api-token not found; CF_API_TOKEN will be empty" >&2
fi
