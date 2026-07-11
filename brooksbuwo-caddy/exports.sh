#!/usr/bin/env bash
# brooksbuwo-caddy/exports.sh
# Exports APP_CF_API_TOKEN for docker-compose.yml (CF_API_TOKEN env -> Caddy {env.CF_API_TOKEN}).
#
# CRITICAL: umbreld sources this file under `set -u` at a point where APP_DATA_DIR may be
# UNBOUND (it is not exported for the first source in app-script). Referencing a bare
# ${APP_DATA_DIR} there aborts the whole install with "APP_DATA_DIR: unbound variable"
# (exit 1). Always use the ${APP_DATA_DIR:-} default form so this file is safe to source
# before APP_DATA_DIR is set. On the later source (during start_app, when APP_DATA_DIR IS
# set) the token is read correctly.
#
# SECURITY: never hardcode the token here; this file is committed to the public repo.
# The token lives at ${APP_DATA_DIR}/data/cf-api-token -- a subdir that ships EMPTY
# (only .gitkeep, excluded by umbreld's rsync) so a token written there survives the
# install-time rsync overlay. This mirrors the official cloudflared community app.
_cf_token_file="${APP_DATA_DIR:-}/data/cf-api-token"
if [ -n "${APP_DATA_DIR:-}" ] && [ -f "$_cf_token_file" ]; then
    export APP_CF_API_TOKEN="$(cat "$_cf_token_file")"
else
    export APP_CF_API_TOKEN=""
fi
