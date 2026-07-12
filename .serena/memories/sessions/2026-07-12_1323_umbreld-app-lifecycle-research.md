# Session: umbreld App Lifecycle Research — 2026-07-12

session_id: fc7d9f7d-d38d-4dee-81a4-3216ea5ee500

## Question
Whether any umbrelOS mechanism can make MEILI_HOST + MEILI_MASTER_KEY env vars
persist on the STOCK linkwarden app across updates, without forking the package.

## Sources opened and verified
1. https://raw.githubusercontent.com/getumbrel/umbrel/main/packages/umbreld/source/modules/apps/app.ts
2. https://raw.githubusercontent.com/getumbrel/umbrel/main/packages/umbreld/source/modules/apps/legacy-compat/app-script
3. https://raw.githubusercontent.com/getumbrel/umbrel/main/packages/umbreld/source/modules/apps/legacy-compat/app-environment.ts
4. https://raw.githubusercontent.com/getumbrel/umbrel/main/packages/umbreld/source/modules/apps/apps.ts

## Key findings

### Update whitelist (from app-script, pre-patch-update and update commands)
UPDATE_FILES_WHITELIST_PRE="docker-compose.yml *.template exports.sh torrc hooks"
UPDATE_FILES_WHITELIST_POST="umbrel-app.yml"
All are COPIED from the store repo into app-data via copy_app_files, OVERWRITING existing files.

### Hooks
- Looked up in app-data/${app}/hooks/ at runtime
- pre-install, post-install, pre-start, post-start, pre-stop, post-stop, pre-update, post-update, pre-uninstall, post-uninstall all exist
- hooks/ directory is in the update whitelist and gets OVERWRITTEN from the store on update
- Any hook placed manually in app-data/linkwarden/hooks/ is blown away when linkwarden updates

### exports.sh
- Sourced for ALL installed apps before every compose call (every start)
- Also OVERWRITTEN on update from the store's exports.sh
- Cross-app sourcing: all apps' exports.sh are sourced before any app's compose runs
- But exports only set bash env vars; linkwarden's canonical compose has no ${MEILI_HOST} references so they would not reach the container

### docker-compose.override.yml
- NOT supported. compose() uses explicit --file flags which disable Docker Compose auto-discovery of override files per Docker spec.

### Cross-app env injection
- No umbreld mechanism for one app to inject env into another app's containers.

### umbreld store
- Holds app list, torEnabled, recentlyOpenedApps, widgets. No per-app user env var store.

## Bottom line
NO supported mechanism exists. Manual re-apply after each linkwarden update is the only path without forking.
