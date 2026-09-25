# Docker-in-Docker with Traefik

One privileged container runs its own Docker daemon, and everything else runs
inside it:

- Traefik, the reverse proxy
- socket-proxy, a read-only filter between Traefik and the inner Docker API
- subdocker-1, built from a local Dockerfile
- subdocker-2, a pre-built nginx image from Docker Hub

The inner stack never touches the host's Docker daemon or socket. Deleting the
`dind` container and its volume deletes every inner image, container, network,
and volume.

```
host  127.0.0.1:8080
            |
            v
dind container (privileged, dockerd on a unix socket only)
  |
  +-- traefik :8000  (published as :80 on the dind container)
  |     +-- [socket]      --> socket-proxy --> inner docker.sock (read-only)
  |     +-- [web-backend] --> subdocker-2 (nginx, no egress)
  |
  +-- subdocker-1 --[egress]--> internet
```

## Requirements

- Docker Engine 24 or newer, or Docker Desktop
- Docker Compose v2.20 or newer (`docker compose`)
- Bash
- A host that allows privileged containers

## Quick start

```bash
git clone https://github.com/martian1337/DinD.git
cd DinD
./setup.sh
```

`setup.sh` starts `dind`, waits for its daemon, then builds and starts the
inner stack and waits for every service to report healthy. Then open
<http://127.0.0.1:8080/>.

To stop everything:

```bash
./teardown.sh             # remove containers, keep all data
./teardown.sh --volumes   # also delete the dind volume and everything in it
```

## Configuration

Copy `.env.example` to `.env` and edit it. All settings are optional.

| Variable     | Default               | Purpose                                                  |
| ------------ | --------------------- | -------------------------------------------------------- |
| `HTTP_BIND`  | `127.0.0.1`           | Host interface for the published port. `0.0.0.0` exposes it to your network. |
| `HTTP_PORT`  | `8080`                | Host port forwarded to Traefik.                          |
| `TARGET_URL` | `https://example.com` | URL subdocker-1 fetches at startup. HTTPS only.          |

Other local changes go in `compose.override.yaml` (host) or
`stack/compose.override.yaml` (inner stack). The scripts load them when
present. Both are git-ignored.

## Working with the sub-dockers

Run a command in a sub-docker:

```bash
./exec.sh subdocker-1 curl --version
./exec.sh subdocker-2 nginx -v
```

Open an interactive shell (bash when the image has it, otherwise sh):

```bash
./exec.sh subdocker-1
```

`exec.sh` takes any inner service name. To run other compose commands against
the inner stack:

```bash
docker compose exec dind docker compose -f /workspace/stack/compose.yaml ps
docker compose exec dind docker compose -f /workspace/stack/compose.yaml logs -f traefik
```

## Adding a sub-docker

1. Create a directory next to the existing ones, for example `subdocker-3/`,
   with a `Dockerfile` or the config files for a pre-built image.
2. Add a service to `stack/compose.yaml`. Paths are relative to `stack/` and
   resolve inside the `dind` container, where the repository is mounted
   read-only at `/workspace`. Merge in the `*hardening` anchor.
3. To route HTTP traffic to it, attach it to the `web-backend` network and add
   Traefik labels as `subdocker-2` does. Give it a router rule that does not
   collide with subdocker-2's catch-all `PathPrefix(`/`)`, such as a longer
   `PathPrefix` or a `Host` rule. Traefik gives longer rules priority.
4. Run `./setup.sh` again. It only recreates what changed.

## Persistent data

- `dind-data` (host volume): the inner daemon's `/var/lib/docker`, including
  inner images, build cache, containers, and inner volumes.
- `subdocker-1-data` (inner volume, stored inside `dind-data`): mounted at
  `/data` in subdocker-1. Each start appends a line to `/data/runs.log`.

Both survive `./teardown.sh` and are deleted by `./teardown.sh --volumes`.

```bash
./exec.sh subdocker-1 cat /data/runs.log
```

## Health checks

Every service has a health check. `setup.sh` fails if any of them stays
unhealthy.

| Service      | Check                                                    |
| ------------ | -------------------------------------------------------- |
| dind         | `docker info` against the inner daemon                   |
| socket-proxy | the image's built-in health check binary                 |
| traefik      | `traefik healthcheck --ping` on the internal entrypoint  |
| subdocker-1  | marker file written after the startup commands succeed   |
| subdocker-2  | `GET /healthz` on nginx                                  |

## Security

The `dind` container runs privileged, which is root-equivalent on the host.
Anyone who can run commands in it, or in a container it starts with extra
privileges, can take over the host. Use this for development, testing, and CI
on machines where that is acceptable. It is not a sandbox for untrusted code.

Hardening in place:

- The inner daemon listens only on its unix socket. The image's default TCP
  listener (2375/2376) is disabled. The `2375-2376/tcp` that `docker ps` shows
  is image metadata, not a published port.
- No container mounts the host's `/var/run/docker.sock`.
- The published port binds to `127.0.0.1` by default.
- Traefik reads the Docker API through
  [socket-proxy](https://github.com/wollomatic/socket-proxy). It accepts
  connections only from the `traefik` container and allows only `HEAD /_ping`
  and `GET` for `_ping`, `version`, `events`, and container list/inspect.
- The Traefik dashboard, API, telemetry, and version check are off. Only the
  `web` entrypoint is published.
- Every inner container runs as a non-root user with a read-only root
  filesystem, all capabilities dropped, `no-new-privileges`, memory and PID
  limits, and rotated logs.
- The `socket` and `web-backend` networks are internal (no outbound access).
  nginx cannot reach the internet or the socket proxy. subdocker-1 is the only
  service with egress, and it cannot reach the other services.
- Traefik adds `Content-Security-Policy`, `X-Frame-Options`,
  `X-Content-Type-Options`, `Referrer-Policy`, and `Permissions-Policy`. nginx
  accepts only `GET` and `HEAD`, hides its version, and refuses dotfiles.
- Images are pinned by tag and digest, GitHub Actions by commit SHA.
  Dependabot opens weekly update PRs.
- subdocker-1's startup `curl` refuses plain HTTP and HTTPS-to-HTTP redirects.

### Exposing the stack beyond localhost

`HTTP_BIND=0.0.0.0` publishes plain HTTP to your network. Add TLS (Traefik's
ACME support or your own certificates) and authentication first, and check
your firewall. Docker's published ports bypass host firewalls such as `ufw`.

### Enabling the Traefik dashboard

The dashboard is off because it has no authentication by default. To turn it
on, add `--api.dashboard=true` in `stack/compose.override.yaml` and route it
through a router with the `basicAuth` or `forwardAuth` middleware. Do not use
`--api.insecure=true`.

## Troubleshooting

- `port is already allocated`: set a different `HTTP_PORT` in `.env`.
- `toomanyrequests` or HTTP 429: Docker Hub rate-limits anonymous pulls. Run
  `docker login` on the host and `docker compose exec dind docker login` for
  the inner daemon.
- Inner containers have no internet access: make sure the host allows
  outbound container traffic. If you need a proxy, set `HTTPS_PROXY` on the
  `dind` service in `compose.override.yaml`.
- Full reset: `./teardown.sh --volumes && ./setup.sh`.

## Repository layout

```
compose.yaml               host level: the dind service
stack/compose.yaml         inner stack: traefik, socket-proxy, sub-dockers
subdocker-1/               Dockerfile and startup script (built locally)
subdocker-2/               nginx config and content (pre-built image)
setup.sh                   start dind and deploy the inner stack
teardown.sh                stop everything, optionally delete data
exec.sh                    run a command or shell in a sub-docker
scripts/common.sh          shared helpers for the scripts above
.github/                   CI (lint and end-to-end test) and Dependabot
```

## License

[MIT](LICENSE)
