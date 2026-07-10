# Headscale (brooksbuwo app store)

Runs the [headscale](https://github.com/juanfont/headscale) control server plus
[headscale-admin](https://github.com/GoodiesHQ/headscale-admin) for browser-based management.

Everything is served on **one port (37070)** through an embedded Traefik reverse proxy:

| Path | Service |
| --- | --- |
| `/admin` | headscale-admin web UI |
| everything else (`/api`, `/ts2021`, ...) | headscale daemon |

This same-origin layout is required: headscale's REST API sends no CORS headers, so a
browser-based UI can only call it from the same origin it was loaded from.

## First run

1. Open the app from the Umbrel dashboard. This opens headscale-admin at
   `http://<your-umbrel-ip-or-hostname>:37070/admin`.
2. Create an API key for headscale-admin. In the umbrelOS web terminal
   (Settings, Advanced, Terminal) or over SSH, run:

   ```bash
   sudo docker exec brooksbuwo-headscale_headscale_1 headscale apikey create
   ```

   The key is printed once; copy it.
3. In headscale-admin's Settings page enter:
   - API URL: `http://<your-umbrel-ip-or-hostname>:37070` (same address the admin UI
     itself is loaded from, without `/admin`)
   - API Key: the key from step 2

   After saving, the Users / Nodes / PreAuthKeys / Routes sections appear in the navigation.

## Connecting Tailscale client devices

Point Tailscale clients at your headscale server:

```
tailscale up --login-server http://<your-umbrel-ip-or-hostname>:37070
```

## Data persistence

- `data/lib` - headscale's SQLite database and Noise private key
- `data/run` - the headscale Unix control socket (used internally, not for external access)
- `config.yaml` - rendered from `config.yaml.template` at install time; `server_url` and
  the MagicDNS base domain are derived automatically from Umbrel's device hostname

## Notes

- The embedded Traefik instance mounts the Docker socket read-only, the same as the
  reference package this layout follows. It routes by path prefix only (no Host rule),
  so the app works via IP address, `umbrel.local`, or any other hostname without
  manual configuration.
