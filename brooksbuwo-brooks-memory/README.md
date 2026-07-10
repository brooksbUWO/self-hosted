# brooks-memory

Deterministic graph-vector memory for AI agents, running on Umbrel.

Packages: NornicDB v1.1.10 daemon, bge-m3 Q8_0 embedding service, and bge-reranker-v2-m3 Q4_K_M cross-encoder reranking service.

## Ports

| Port | Protocol | Description |
|------|----------|-------------|
| 7475 | HTTP | NornicDB UI via Umbrel app proxy (Umbrel login required) |
| 7474 | HTTP | NornicDB direct machine port (JWT required; LAN access) |

Port 7474 is for harness adapters (Claude Code, OpenCode, AntiGravity, Codex). Point adapters at `http://<umbrel-ip>:7474`. JWT tokens are issued from the admin credentials.

## Required Environment Variables

Set these in the Umbrel app environment or in a `.env` file on the Umbrel box before installing:

| Variable | Description | Example |
|----------|-------------|---------|
| `NORNICDB_ADMIN_PASSWORD` | Admin password for initial setup | `your-strong-password-here` |
| `NORNICDB_JWT_SECRET_VALUE` | HS256 JWT signing secret (32+ characters) | `generate-with-openssl-rand-hex-32` |

Generate a secret: `openssl rand -hex 32`

Store both values in a local password manager before installing.

## Environment Variable Reference (NornicDB config names)

All environment variables are source-verified against NornicDB v1.1.10 `pkg/config/config.go`.

### JWT and Auth

| Compose Var | NornicDB Config Name | Source | Notes |
|-------------|---------------------|--------|-------|
| `NORNICDB_AUTH_JWT_SECRET` | `config.Auth.JWTSecret` | config.go line 1964 | **AUTH_ prefix is required**. `NORNICDB_JWT_SECRET` (without AUTH_) does NOT exist in the config loader and will be silently ignored, leaving JWT auth unconfigured. |
| `NORNICDB_AUTH` | `config.Auth.Credentials` | config.go | Format: `admin:<password>` |

### MVCC Retention

| Compose Var | NornicDB Config Name | Source | Notes |
|-------------|---------------------|--------|-------|
| `NORNICDB_MVCC_RETENTION_MAX_VERSIONS` | `config.Database.MVCCRetentionMaxVersions` | config.go line 2058 | Default is 1. Set to 100 for audit history. This IS a real environment variable; no YAML config file mount is needed. |

### Embedding and Reranker

| Compose Var | Value | Notes |
|-------------|-------|-------|
| `NORNICDB_SEARCH_RERANK_API_URL` | `http://reranker:8081/v1/rerank` | The **full `/v1/rerank` path is required**. NornicDB CrossEncoder POSTs directly to this URL (rerank.go line 106). The default without this env var is `http://localhost:8081/rerank` which does not exist on llama-server. |

### Workers Explicitly Disabled

| Env Var | Default | Set To | Reason |
|---------|---------|--------|--------|
| `NORNICDB_BOLT_ENABLED` | `true` | `false` | Bolt protocol not needed in MCP-only deploy; disables 5 Bolt goroutines (source: disposition table 2026-07-10, sites 24-28) |
| `NORNICDB_AUTO_LINKS_ENABLED` | `true` | `false` | Prevents automatic edge inference; single-node MCP-only deploy does not need link prediction |

Workers that are OFF by default (no env var needed in compose): K-means clustering, edge decay, access flusher, retention sweep, replication, Qdrant gRPC, Heimdall AI assistant.

## Image Digests

### NornicDB (patched)

The running image is **not the stock** `timothyswt/nornicdb-amd64-cpu:v1.1.10`. It includes the MCP `notifications/initialized` patch from Plan 01 (one-case addition to `pkg/mcp/server.go`). Without this patch the MCP handshake fails for all four harnesses.

**Path A (in use):** Local build from the patched fork.

Build the patched image (run on the Umbrel box or any linux/amd64 machine with Go and Docker):

```bash
cd .claude/workspace/repos/NornicDB
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o nornicdb-patched ./cmd/nornicdb
docker build -t brooksbuwo/nornicdb-patched:v1.1.10 -f Dockerfile.patched .
docker inspect --format='{{index .RepoDigests 0}}' brooksbuwo/nornicdb-patched:v1.1.10
```

Record the full sha256 digest and replace the `build:` block in `docker-compose.yml` with:
```yaml
image: >-
  brooksbuwo/nornicdb-patched:v1.1.10@sha256:<FULL-DIGEST-HERE>
```

**Stock v1.1.10 digest reference (12-char prefix, from gap register G5):** `29dbb66c88ad`

Full digest command: `docker manifest inspect timothyswt/nornicdb-amd64-cpu:v1.1.10`

**Path B (fallback if Path A unavailable):** Use the stock image and the `mcp-initialize-proxy.mjs` sidecar (see commented-out `mcp_proxy` service in docker-compose.yml). Activate only if the patched build is not yet ready.

### llama.cpp (embeddings and reranker)

Both `embeddings` and `reranker` services use the same official CPU image: `ghcr.io/ggml-org/llama.cpp:server`.

Resolve the current linux/amd64 digest:
```bash
docker manifest inspect ghcr.io/ggml-org/llama.cpp:server \
  | python3 -c "
import sys, json
m = json.load(sys.stdin)
for x in m.get('manifests', []):
    p = x.get('platform', {})
    if p.get('architecture') == 'amd64' and p.get('os') == 'linux':
        print(x['digest'])
"
```

Update both `image:` lines in `docker-compose.yml` with:
```yaml
image: >-
  ghcr.io/ggml-org/llama.cpp:server@sha256:<FULL-DIGEST-HERE>
```

Record the digest and the llama.cpp build tag (check release notes for the tag corresponding to the resolved digest).

## GGUF Model Checksums

The `hooks/pre-start` script downloads both GGUFs and sha256-verifies them on every start.

**Before Plan 04 deploy**, obtain the real sha256 values and replace the placeholders in `hooks/pre-start`:

```bash
# bge-m3 Q8_0 (635 MB)
curl -fL --retry 3 -o /tmp/bge-m3-Q8_0.gguf \
  https://huggingface.co/gpustack/bge-m3-GGUF/resolve/main/bge-m3-Q8_0.gguf
sha256sum /tmp/bge-m3-Q8_0.gguf

# bge-reranker-v2-m3 Q4_K_M (approx 300 MB)
curl -fL --retry 3 -o /tmp/bge-reranker-v2-m3-Q4_K_M.gguf \
  https://huggingface.co/gpustack/bge-reranker-v2-m3-GGUF/resolve/main/bge-reranker-v2-m3-Q4_K_M.gguf
sha256sum /tmp/bge-reranker-v2-m3-Q4_K_M.gguf
```

Set `BGE_M3_SHA256` and `RERANKER_SHA256` in `hooks/pre-start` before committing the production version.

## One-Time Setup (after first install)

Run these steps once after the daemon starts for the first time.

### 1. Get an admin JWT

```bash
# Replace <umbrel-ip> and <password> with your actual values
curl -s -X POST http://<umbrel-ip>:7474/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"<NORNICDB_ADMIN_PASSWORD>"}'
# Response contains {"token": "<admin-jwt>"}
ADMIN_JWT="<paste-token-here>"
```

### 2. Create the llm_agent role

`llm_agent` is NOT a built-in NornicDB role (source: `pkg/auth/allowlist.go` line 25: built-ins are `admin`, `editor`, `viewer`). It must be created via API:

```bash
curl -X POST http://<umbrel-ip>:7474/auth/roles \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"name":"llm_agent"}'
```

### 3. Grant read and write privileges

```bash
curl -X PUT http://<umbrel-ip>:7474/auth/access/privileges \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"role":"llm_agent","database":"default","read":true,"write":true}'
```

### 4. Create an adapter user and issue a JWT

```bash
curl -X POST http://<umbrel-ip>:7474/auth/users \
  -H "Authorization: Bearer $ADMIN_JWT" \
  -H "Content-Type: application/json" \
  -d '{"username":"adapter","password":"<choose-adapter-password>","role":"llm_agent"}'

# Issue JWT for the adapter
curl -s -X POST http://<umbrel-ip>:7474/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"adapter","password":"<adapter-password>"}'
# Store the returned token as BROOKS_MEMORY_JWT in the harness adapter config
```

The adapter JWT is what goes into `BROOKS_MEMORY_JWT` in the Claude Code plugin config (`.mcp.json` and hook env).

## Secret Rotation

To rotate the JWT secret:
1. Update `NORNICDB_JWT_SECRET_VALUE` in the Umbrel app environment.
2. Restart the app: all existing tokens are immediately invalid.
3. Re-issue new adapter JWTs via the `/auth/login` endpoint.

## Reranker Score-Accuracy Note

If the reranker returns flat scores (all values within 0.05 of each other) for semantically different queries, the GGUF may be an embedding-style export rather than a proper cross-encoder output. Mitigation steps (in order):
1. Try the Q8_0 variant of bge-reranker-v2-m3.
2. Try an adjacent llama.cpp release (one build tag earlier or later).
3. Record the working combination and update the `RERANKER_SHA256` and image digest accordingly.

Plan 04 includes a formal score-accuracy gate test for this.

## APP_HOST Naming

The `APP_HOST` value for Umbrel's app_proxy follows the pattern `<app-id>_<service-name>_1`:

```yaml
APP_HOST: brooksbuwo-brooks-memory_nornicdb_1
```

This is source-verified from the `brooksbuwo-headscale` template (which uses `brooksbuwo-headscale_traefik_1`). The nornicdb service is published on the app-internal Docker network under this container name.

## Traefik Routing

This app does NOT use a traefik sidecar. The app_proxy routes directly to the nornicdb container on port 7474 using PathPrefix-only routing (no Host() matcher), consistent with the headscale template pattern. This ensures the UI works via IP address, `umbrel.local`, and the tailnet hostname without any configuration change.
