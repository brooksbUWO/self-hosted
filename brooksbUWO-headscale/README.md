# Headscale (brooksbUWO app store)

Runs the [headscale](https://github.com/juanfont/headscale) control server plus
[headscale-admin](https://github.com/GoodiesHQ/headscale-admin) for browser-based management.

## First run

1. Open the app from the Umbrel dashboard — this opens headscale-admin at `/admin`.
2. headscale-admin needs an API key to talk to the headscale server. One is generated
   automatically on first container start and saved to this app's data directory at
   `data/lib/api-key.txt`. Open it via the Umbrel Files app (`apps/brooksbUWO-headscale/data/lib/api-key.txt`),
   copy the key, and paste it into headscale-admin's login screen along with the server
   address below.
3. Server address for headscale-admin to connect to: `http://<your-umbrel-ip-or-hostname>:37070`

No SSH or `docker exec` is required for this step.

## Connecting Tailscale client devices

Point Tailscale clients at your headscale server:

```
tailscale up --login-server http://<your-umbrel-ip-or-hostname>:37070
```

Port `37070` is published directly on the host for this purpose — it is the same port
used above for headscale-admin's connection.

## Data persistence

- `data/lib` — headscale's SQLite database, Noise/API keys, generated `api-key.txt`
- `data/run` — the headscale Unix control socket (used internally, not for external access)

## Notes

- No embedded reverse proxy and no Docker socket access are used in this package.
- `server_url` is derived automatically from Umbrel's device hostname at container start;
  no manual config file editing is required.
