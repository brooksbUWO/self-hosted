# Headscale (brooksbuwo app store)

Runs the [headscale](https://github.com/juanfont/headscale) control server plus
[Headplane](https://github.com/tale/headplane) for browser-based management.

Everything is served on **one port (37070)** through an embedded Traefik reverse proxy:

| Path | Service |
| --- | --- |
| `/admin` | Headplane admin UI |
| everything else (`/api`, `/ts2021`, ...) | headscale daemon |

This same-origin layout is required: headscale's REST API sends no CORS headers, so a
browser-based UI can only call it from the same origin it was loaded from.

## First run

Open the app from the Umbrel dashboard. The Headplane admin UI loads automatically after
Umbrel login. No terminal commands and no API key creation are required.

A one-shot provisioner service creates the internal headscale API key on first start and
writes it to the persistent data directory. Headplane reads the key automatically on startup.

## Connecting Tailscale client devices

Point Tailscale clients at the DIRECT headscale port (37071), using the
Umbrel's IP address:

```
tailscale up --login-server http://<your-umbrel-ip>:37071
```

Two rules here, both learned the hard way:

- **Port 37071, not 37070.** Umbrel's app proxy fronts every app port and
  closes connections carrying the non-websocket
  `Upgrade: tailscale-control-protocol` header, so a client pointed at 37070
  fetches the server key but its `/ts2021` Noise handshake dies with an empty
  reply and registration never completes. Port 37071 bypasses the proxy.
- **IP address, not a hostname.** An open Tailscale client bug
  (tailscale/tailscale#15008) latches the client into TLS/port-443 mode after
  a failed Noise dial when the login server URL is a hostname
  (`"controlhttp: forcing port 443 dial due to recent noise dial"`). Literal
  private IPs are exempt from the heuristic on tailscale 1.80.3+.

## API access

| Access path | Port | Auth required | What it reaches |
| --- | --- | --- | --- |
| Tailscale control protocol | 37071 | None (by design) | headscale directly |
| headscale REST API from LAN | 37071 | None | headscale directly |
| Headplane admin UI | 37070 | Umbrel login wall, then auto-sign-in via proxy_auth | Headplane at /admin |
| headscale REST API via 37070 | 37070 | Umbrel login wall | headscale via Traefik |

The headscale REST API is accessible without authentication on port 37071. This is a
deliberate trade-off: the Tailscale control protocol requires a raw TCP connection on this
port and Umbrel's app proxy cannot forward it. Headscale's own API key authentication
(the `Authorization: Bearer` header) still applies on port 37071 for REST calls.

## Data persistence

- `data/lib`: headscale's SQLite database and Noise private key
- `data/run`: the headscale Unix control socket (used internally, not for external access)
- `data/headplane`: Headplane session data and the internal API key
- `config.yaml`: rendered from `config.yaml.template` at install time; `server_url` and
  the MagicDNS base domain are derived automatically from Umbrel's device hostname

## Notes

- The embedded Traefik instance mounts the Docker socket read-only, the same as the
  reference package this layout follows. It routes by path prefix only (no Host rule),
  so the app works via IP address, `umbrel.local`, or any other hostname without
  manual configuration.
- The `/android` endpoint returns the Android enrollment page, compiled from source in
  the same Dockerfile build that adds the `/apple` configuration endpoint.
