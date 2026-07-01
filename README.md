## brooksbuwo Umbrel Community App Store

Personal Umbrel Community App Store (store id `brooksbuwo`). Add its GitHub URL in the
umbrelOS "Community App Stores" settings to install apps from it.

Store URL: `https://github.com/brooksbUWO/self-hosted`

### Apps in this store

- **[brooksbuwo-headscale](./brooksbuwo-headscale)** — [Headscale](https://github.com/juanfont/headscale),
  a self-hosted Tailscale control server, plus [headscale-admin](https://github.com/GoodiesHQ/headscale-admin)
  for browser-based management.

Additional apps can be added as new top-level folders, each with its own `umbrel-app.yml` and
`docker-compose.yml`. App ids must be all-lowercase (Docker Compose rejects mixed-case project
names), so folders follow `<store-id-lowercase>-<app-name>`, e.g. `brooksbuwo-headscale`.
