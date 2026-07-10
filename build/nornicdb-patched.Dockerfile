# nornicdb-patched.Dockerfile
#
# Builds a patched NornicDB v1.1.10 image for linux/amd64.
# Strategy: clone upstream at the exact tag, apply one .patch file, build headless.
#
# Why headless (noui,nolocalllm tags)?
#   - Our compose supplies external embedding/rerank services (llama.cpp containers).
#   - The UI is not needed in the Umbrel app (Umbrel provides its own proxy/dashboard).
#   - Skipping the UI build stage eliminates a Node.js layer and ~200 MB from the image.
#
# Why CGO_ENABLED=1 (not 0)?
#   - NornicDB uses badger/v4 which has no CGO dependency, but the build system
#     links against libc for platform detection. The upstream Dockerfile uses
#     CGO_ENABLED=1 and bookworm-slim at runtime. Keeping that alignment avoids
#     silent linker issues. The nolocalllm tag removes the only CGO-heavy path
#     (embedded llama.cpp), so the final binary is effectively pure Go in practice.
#
# APOC plugin: deliberately NOT built here.
#   - APOC is a plugin .so; no NORNICDB_PLUGINS_DIR is set in our compose,
#     and the brook-memory deployment does not use APOC procedures.
#   - Skipping it halves build time (no second go build -buildmode=plugin pass).

# =============================================================================
# Stage 1: Build
# =============================================================================
FROM golang:1.26-bookworm AS builder

WORKDIR /build

RUN apt-get update && \
    apt-get install -y --no-install-recommends git build-essential ca-certificates patch && \
    rm -rf /var/lib/apt/lists/*

# Clone upstream at the pinned tag (shallow: only the tagged commit, no history)
RUN git clone --depth 1 --branch v1.1.10 \
        https://github.com/orneryd/NornicDB.git .

# Apply the MCP notifications/initialized patch.
# The patch targets pkg/mcp/server.go in the upstream source tree.
# Validation: the hunk context (lines "switch req.Method", "case \"initialize\":",
# "case \"tools/list\":") is present verbatim in v1.1.10 pkg/mcp/server.go
# (source-verified against local mirror at .claude/workspace/repos/NornicDB/).
# 'git apply' verifies context lines before applying; the build fails if they do not match.
COPY mcp-notifications-initialized.patch .
RUN git apply mcp-notifications-initialized.patch && \
    echo "Patch applied cleanly."

# Pre-download Go module dependencies (layer-cached separately from source)
RUN go mod download

# Build: headless (no UI, no embedded llama.cpp), linux/amd64, strip debug info
RUN CGO_ENABLED=1 GOOS=linux GOARCH=amd64 \
    go build -tags "noui,nolocalllm" \
      -ldflags="-s -w -X main.buildTime=$(date -u +%Y%m%d-%H%M%S)" \
      -o nornicdb \
      ./cmd/nornicdb

# =============================================================================
# Stage 2: Runtime
# =============================================================================
FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates tzdata wget && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /data

COPY --from=builder /build/nornicdb /app/nornicdb

# Entrypoint script: mirrors the upstream docker/entrypoint.sh exactly.
# It builds "serve --data-dir --http-port --bolt-port --address" args from env vars,
# then execs /app/nornicdb. Copied inline to avoid any COPY from the clone.
COPY --from=builder /build/docker/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EXPOSE 7474 7687 9091

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD wget --spider -q http://localhost:7474/health || exit 1

ENV NORNICDB_DATA_DIR=/data \
    NORNICDB_HTTP_PORT=7474 \
    NORNICDB_BOLT_PORT=7687 \
    NORNICDB_EMBEDDING_PROVIDER=none \
    NORNICDB_EMBEDDING_ENABLED=false \
    NORNICDB_NO_AUTH=true \
    NORNICDB_GPU_ENABLED=false \
    NORNICDB_HEADLESS=true

ENTRYPOINT ["/app/entrypoint.sh"]
