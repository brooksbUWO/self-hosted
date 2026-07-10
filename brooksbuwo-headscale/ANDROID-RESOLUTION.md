# Android Endpoint: Phase 2 Resolution Note

## Decision

Keep build: headscale is built from source in docker-compose.yml; the user accepts slow install-time builds; no GHCR prebuilt image will be created.

## Compile Test Result

Status: PASSED

`docker build -t hs-android-test` succeeded on the Umbrel (2026-07-10, linux/amd64). Smoke run output (`docker run --rm hs-android-test version`; the ENTRYPOINT is already `headscale`):

```
headscale version v0.29.1+dirty
commit: 636f660caf3ca995fad5a9ed6f1b6b0578637b55
build time: 2026-06-18T10:22:27Z
built with: go1.26.4 linux/amd64
```

Build image sha256: `d4522c93703ffdbaf2e3dfcc3c3ccb4febf72ed6d177840c20f0cf6daa661daf`

## Fixes Applied

### CE-01: Replace undefined page() call (android.go)

File: `headscale-src/hscontrol/templates/android.go`

The original scaffold called `page()`, which does not exist in the v0.29.1 templates package. Replaced with the `HtmlStructure` + `mdTypesetBody` pattern, matching the existing `windows.go` template.

### CE-02: Replace undefined codeBlockText() call (android.go)

File: `headscale-src/hscontrol/templates/android.go`

`codeBlockText()` does not exist. Replaced with `Pre(PreCode(...))`, the same pattern used in other templates in the same package.

### Toolchain fix: Builder base image (Dockerfile)

File: `Dockerfile`

The original Dockerfile used `golang:1.24-alpine` as the builder stage base. headscale v0.29.1 `go.mod` requires `go >= 1.26.4`, and official Golang Docker images ship with `GOTOOLCHAIN=local`, so any base below 1.26.4 fails at the toolchain gate before any Go source is compiled. The base was bumped to:

```
FROM golang:1.26.4-alpine@sha256:3ad57304ad93bbec8548a0437ad9e06a455660655d9af011d58b993f6f615648 AS builder
```

The digest pin documents the exact image used during the verified compile test.

CE-03 (blank `_ "embed"` import in `platform_config.go`) never surfaced; that file compiled without modification.

## What Ships

The patched `headscale-src/` directory and `Dockerfile` in this repo build headscale v0.29.1 with an `/android` endpoint that renders setup instructions for the Android Tailscale client. The endpoint path is `/android`. The handler is `AndroidConfigMessage` in `hscontrol/platform_config.go`. Three files are overlaid onto the upstream v0.29.1 source at build time:

- `headscale-src/hscontrol/templates/android.go` (new file, this phase)
- `headscale-src/hscontrol/platform_config.go` (route registration, Phase 1)
- `headscale-src/hscontrol/app.go` (handler wiring, Phase 1)

## Phase 3 Note

The manifest version remains `0.29.1-2` (no bump in Phase 2, per locked decision D-02). The version bump from `0.29.1-2` to the next patch travels with Phase 3 (headplane admin UI release). This note is the confirmation that the android patch is compile-clean and ready to ship in that release.
