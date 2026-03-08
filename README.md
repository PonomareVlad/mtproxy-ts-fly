# mtproxy-ts-fly

Run [Telegram MTProxy](https://hub.docker.com/r/telegrammessenger/proxy/) on [Fly.io](https://fly.io/) with [Tailscale](https://tailscale.com/) exit node and SSH access.

Based on the official [`telegrammessenger/proxy`](https://hub.docker.com/r/telegrammessenger/proxy/) Docker image — MTProxy runs completely unmodified. Tailscale is added as a sidecar for exit node and SSH functionality.

## Prerequisites

- [Fly CLI](https://fly.io/docs/flyctl/install/) (`flyctl`)
- A [Fly.io](https://fly.io/) account
- A [Tailscale](https://tailscale.com/) account with an [auth key](https://tailscale.com/kb/1085/auth-keys)

## Setup

1. **Create the Fly app:**

   ```sh
   fly apps create mtproxy-ts-fly
   ```

2. **Set the Tailscale auth key as a secret:**

   ```sh
   fly secrets set TAILSCALE_AUTHKEY=tskey-auth-...
   ```

3. **Deploy:**

   ```sh
   fly deploy
   ```

Once deployed, container logs will show the `tg://` and `t.me` proxy links. Connect to MTProxy via its Tailscale IP (visible in your [admin console](https://login.tailscale.com/admin/machines)) on port 443. Use `fly logs` to view the links.

## How it works

```
Fly VM
  ├── tailscaled (exit node + SSH)
  └── mtproto-proxy (official image, 0.0.0.0:443)
        └── persistent data → /data
```

- **MTProxy** runs from the official [`telegrammessenger/proxy`](https://hub.docker.com/r/telegrammessenger/proxy/) image — completely unmodified.
- **Tailscale** provides exit node (`--advertise-exit-node`) and SSH (`--ssh`) access.
- **IP forwarding and NAT masquerading** are enabled at startup for exit node support per [Tailscale docs](https://tailscale.com/docs/features/subnet-routers#enable-ip-forwarding).
- Connect to MTProxy through your Tailnet using the node's Tailscale IP on port 443.

## Configuration

### Secrets

| Variable | Description |
|---|---|
| `TAILSCALE_AUTHKEY` | Tailscale auth key used to join your Tailnet (set via `fly secrets set`) |

### Environment Variables

Set via `fly secrets set` or in your deploy pipeline:

| Variable | Default | Description |
|---|---|---|
| `TAILSCALE_HOSTNAME` | `mtproxy` | Tailscale node hostname |
| `SECRET` | *(auto-generated)* | MTProxy secret (32 hex chars); persists in `/data/secret` |
| `SECRET_COUNT` | `1` | Number of secrets to auto-generate (1–16) |
| `TAG` | *(none)* | Advertisement tag from [@MTProxybot](https://t.me/mtproxybot) |
| `WORKERS` | `2` | Number of MTProxy worker processes |
| `DEBUG` | *(none)* | Set to any value to enable shell debug output |

### fly.toml Settings

| Setting | Value | Notes |
|---|---|---|
| `primary_region` | `ams` | Change to a [region](https://fly.io/docs/reference/regions/) closer to you |
| `vm.size` | `shared-cpu-1x` | Smallest Fly VM tier |
| `persist_rootfs` | `always` | Persists filesystem across restarts (Tailscale state + MTProxy data) |

## Security

- No public IP is allocated on Fly.io — the `fly.toml` has no `[[services]]` section.
- MTProxy is accessible through the Tailnet only (via the node's Tailscale IP).
- MTProxy secrets are auto-generated and persisted across restarts.
- Tailscale state is persisted via `persist_rootfs` so the node identity survives restarts.