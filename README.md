# Docker-in-Docker with Traefik

This project runs a complete Docker environment inside a single container. You
start it with one command, look at a small website it serves, and throw the
whole thing away with one more command. Nothing it creates is left scattered
across your machine.

It is a good way to learn how containers, reverse proxies, and container
networks fit together without touching anything else you run in Docker.

## Contents

- [New to Docker? Start here](#new-to-docker-start-here)
- [What you need](#what-you-need)
- [Step-by-step: your first run](#step-by-step-your-first-run)
- [Things to try](#things-to-try)
- [Stopping and cleaning up](#stopping-and-cleaning-up)
- [Changing settings](#changing-settings)
- [Troubleshooting](#troubleshooting)
- [How it works](#how-it-works)
- [Adding your own container](#adding-your-own-container)
- [Security](#security)
- [Reference](#reference)

## New to Docker? Start here

A few terms come up throughout this guide:

| Term | What it means |
| ---- | ------------- |
| **Image** | A packaged, read-only template for a program, including everything it needs to run. Think of it as an installer. |
| **Container** | A running copy of an image. It is isolated from the rest of your computer, a bit like a very lightweight virtual machine. |
| **Docker daemon** | The background service that builds images and runs containers. The `docker` command talks to it. |
| **Docker Compose** | A tool that starts several containers together from a single file (`compose.yaml`). |
| **Docker-in-Docker (DinD)** | A container that runs its own Docker daemon, so it can run containers inside itself. |
| **Reverse proxy** | A server that receives web requests and forwards them to the right service. This project uses [Traefik](https://traefik.io/traefik/). |
| **Volume** | Storage managed by Docker that keeps data when a container is deleted. |

### What this project sets up

When you run it, Docker starts **one** container on your computer called
`dind`. Inside that container, a second Docker daemon starts four more
containers:

| Container | What it does |
| --------- | ------------ |
| `traefik` | Receives your browser's requests and forwards them to the website. |
| `socket-proxy` | Lets Traefik look up which containers exist, and nothing else. |
| `subdocker-1` | A small Debian Linux container with `curl`, built from the files in `subdocker-1/`. You can open a shell in it and experiment. |
| `subdocker-2` | An nginx web server that serves the page you will open in your browser. |

```
Your computer
|
|   browser --> http://127.0.0.1:8080
|                       |
+-- dind container -----|----------------------------------------
      |                 v
      +-- traefik ----------> subdocker-2 (web page)
      |      +--------------> socket-proxy (read-only container list)
      |
      +-- subdocker-1 ------> the internet (runs curl at startup)
```

Because everything lives inside `dind`, deleting that one container and its
volume removes everything this project created.

## What you need

1. **Docker**
   - **Windows or macOS:** install
     [Docker Desktop](https://www.docker.com/products/docker-desktop/) and
     start it. Wait until it says Docker is running.
   - **Linux:** install
     [Docker Engine](https://docs.docker.com/engine/install/) and the
     [Compose plugin](https://docs.docker.com/compose/install/linux/).
2. **A Bash terminal**
   - **macOS / Linux:** the built-in Terminal app works.
   - **Windows:** use a [WSL 2](https://learn.microsoft.com/windows/wsl/install)
     terminal such as Ubuntu, and turn on WSL integration in Docker Desktop
     (Settings > Resources > WSL Integration). PowerShell and Command Prompt
     cannot run the `.sh` scripts.
3. **Git** (optional) to download the project. You can also download it as a
   ZIP from GitHub.

### Check that Docker is ready

Run these in your terminal:

```bash
docker --version
docker compose version
docker run --rm hello-world
```

The last command should print `Hello from Docker!`. If any of them fail, fix
Docker first; see [Troubleshooting](#troubleshooting).

You need Docker Compose v2.20 or newer. Docker Desktop includes it.

## Step-by-step: your first run

### 1. Download the project

```bash
git clone https://github.com/martian1337/DinD.git
cd DinD
```

If you downloaded the ZIP instead, unzip it and `cd` into the folder in your
terminal.

### 2. Start everything

```bash
./setup.sh
```

The first run downloads several images and builds one, so it can take a few
minutes. You will see progress output, and at the end:

```
==> Done. subdocker-2 is available at http://127.0.0.1:8080/
```

> If you see `Permission denied`, run `bash setup.sh` instead. This happens when
> the files were downloaded as a ZIP, which drops the "executable" flag. The
> same applies to the other `.sh` scripts.

### 3. Open the website

Go to <http://127.0.0.1:8080/> in your browser. You should see a page titled
**subdocker-2**. Your request went to Traefik inside the `dind` container,
which passed it to the nginx container.

### 4. Look inside

List the containers running on your computer:

```bash
docker ps
```

Besides anything you were already running, you will see just **one** new
container, `dind-dind-1`. Now list the containers running inside it:

```bash
docker compose exec dind docker ps
```

This shows the four inner containers. That is Docker-in-Docker.

## Things to try

Run a command inside `subdocker-1`:

```bash
./exec.sh subdocker-1 curl --version
```

Open a shell inside it. Your prompt changes; type `exit` to leave:

```bash
./exec.sh subdocker-1
```

See what `subdocker-1` did when it started. It fetches a web page and writes a
line to a log file each time it starts:

```bash
./exec.sh subdocker-1 cat /data/runs.log
```

Change the web page: edit `subdocker-2/html/index.html` in any text editor,
save it, and refresh your browser.

Watch Traefik's log of incoming requests while you refresh the page (press
`Ctrl+C` to stop):

```bash
docker compose exec dind docker compose -f /workspace/stack/compose.yaml logs -f traefik
```

## Stopping and cleaning up

Stop everything but keep downloaded images and data, so the next start is fast:

```bash
./teardown.sh
```

Start again at any time with `./setup.sh`.

Remove everything this project created, including all downloaded images and
data:

```bash
./teardown.sh --volumes
```

## Changing settings

Settings live in a file called `.env`. Create it from the example:

```bash
cp .env.example .env
```

Open `.env` in a text editor, change what you need, and run `./setup.sh`
again.

| Setting | Default | What it does |
| ------- | ------- | ------------ |
| `HTTP_PORT` | `8080` | The port in `http://127.0.0.1:8080`. Change it if 8080 is already used by something else. |
| `HTTP_BIND` | `127.0.0.1` | Who can open the website. `127.0.0.1` means only this computer. `0.0.0.0` lets other devices on your network open it; read [Security](#security) first. |
| `TARGET_URL` | `https://example.com` | The page `subdocker-1` fetches when it starts. Must start with `https://`. |

## Troubleshooting

**`Cannot connect to the Docker daemon` or `cannot reach the Docker daemon`**
Docker is not running. Start Docker Desktop (or run
`sudo systemctl start docker` on Linux) and try again.

**`permission denied while trying to connect to the Docker daemon socket`** (Linux)
Your user is not allowed to use Docker. Follow Docker's
[post-install steps](https://docs.docker.com/engine/install/linux-postinstall/)
to add yourself to the `docker` group, then log out and back in.

**`Permission denied` when running `./setup.sh`**
Run `bash setup.sh`, or make the scripts executable once with
`chmod +x *.sh`.

**`port is already allocated`**
Another program is using port 8080. Set a different `HTTP_PORT` in `.env`,
for example `8081`, and use that port in your browser.

**`toomanyrequests` or `429`**
Docker Hub limits how many images you can download without an account. Create
a free Docker Hub account, then run both of these:

```bash
docker login
docker compose exec dind docker login
```

**`subdocker-1` is unhealthy**
It could not fetch `TARGET_URL`, usually because there is no internet access or
a company network requires a proxy. Check its log:

```bash
docker compose exec dind docker compose -f /workspace/stack/compose.yaml logs subdocker-1
```

**Something is broken and you want a fresh start**

```bash
./teardown.sh --volumes
./setup.sh
```

## How it works

This section explains what happens behind `./setup.sh`, for when you want to
go further.

1. `setup.sh` reads [`compose.yaml`](compose.yaml) and starts the `dind`
   container. The project folder is shared into it, read-only, at
   `/workspace`.
2. It waits until the Docker daemon inside `dind` answers.
3. It runs `docker compose` **inside** `dind` using
   [`stack/compose.yaml`](stack/compose.yaml), which builds `subdocker-1` and
   starts all four inner containers.
4. It waits until every container passes its health check, then prints the
   address.

The inner containers are split across separate networks, so each one can only
reach what it needs:

| Network | Members | Internet access |
| ------- | ------- | --------------- |
| `ingress` | traefik | yes (receives your requests) |
| `socket` | traefik, socket-proxy | no |
| `web-backend` | traefik, subdocker-2 | no |
| `egress` | subdocker-1 | yes |

Traefik finds the website by reading labels on the `subdocker-2` container in
`stack/compose.yaml`. The labels say "send every request to this container on
port 8080".

Every service has a health check, and `setup.sh` stops with an error if any of
them stays unhealthy:

| Service | Health check |
| ------- | ------------ |
| dind | `docker info` against the inner daemon |
| socket-proxy | the image's built-in health check |
| traefik | `traefik healthcheck --ping` |
| subdocker-1 | a marker file written after its startup commands succeed |
| subdocker-2 | `GET /healthz` on nginx |

Data is kept in two volumes. Both survive `./teardown.sh` and are deleted by
`./teardown.sh --volumes`:

- `dind-data` holds everything the inner Docker daemon stores: images, build
  cache, containers, and inner volumes.
- `subdocker-1-data` is mounted at `/data` in `subdocker-1`. It lives inside
  `dind-data`.

## Adding your own container

1. Create a folder next to the others, for example `subdocker-3/`. Put a
   `Dockerfile` in it, or the config files for an existing image.
2. Add a service to `stack/compose.yaml`. Copy `subdocker-1` (built from a
   `Dockerfile`) or `subdocker-2` (pre-built image) as a starting point, and
   keep the `<<: *hardening` line. Paths are relative to the `stack/` folder.
3. To make it reachable in the browser, add it to the `web-backend` network and
   copy the Traefik labels from `subdocker-2`. Give it its own rule, such as
   ``PathPrefix(`/app3`)``, so it does not clash with subdocker-2's catch-all
   ``PathPrefix(`/`)``. Traefik tries longer rules first.
4. Run `./setup.sh`. It only rebuilds and restarts what changed.

For changes you want to keep out of git, create `compose.override.yaml` (for
the `dind` container) or `stack/compose.override.yaml` (for the inner
containers). The scripts load them automatically, and git ignores them.

## Security

**Read this before using the project anywhere other than your own computer.**

The `dind` container needs Docker's `--privileged` mode to run a Docker daemon.
A privileged container has nearly full control of your computer. Anyone who can
run commands inside it could take over the machine. That is fine for learning,
development, and CI on a machine you control. Do not use this to run code you
do not trust.

What the project does to reduce risk:

- The inner Docker daemon has no network port. It is only reachable from inside
  the `dind` container. (The `2375-2376/tcp` that `docker ps` shows is image
  metadata, not an open port.)
- No container gets access to your computer's own Docker daemon.
- The website is only reachable from your computer unless you change
  `HTTP_BIND`.
- Traefik reads container information through
  [socket-proxy](https://github.com/wollomatic/socket-proxy), which only allows
  a few read-only requests (`HEAD /_ping`, and `GET` for `_ping`, `version`,
  `events`, and listing or inspecting containers).
- The Traefik dashboard and API are turned off.
- Every inner container runs as a regular user instead of root, cannot write to
  its own system files, has no special Linux privileges, and has memory and
  process limits. Logs are rotated so they cannot fill your disk.
- The networks in [How it works](#how-it-works) keep services apart. nginx has
  no internet access and cannot see the socket proxy.
- Traefik adds browser security headers (`Content-Security-Policy`,
  `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`,
  `Permissions-Policy`). nginx only accepts `GET` and `HEAD` requests, hides
  its version, and refuses to serve hidden files.
- Every image is pinned to an exact version and digest, and GitHub Actions are
  pinned to exact commits. Dependabot proposes updates weekly.
- `subdocker-1` only fetches `https://` URLs and refuses redirects to plain
  `http://`.

### Opening the website to your network

Setting `HTTP_BIND=0.0.0.0` makes the site reachable by other devices, over
unencrypted HTTP. Before doing that, add HTTPS (Traefik can get certificates
automatically) and a login if needed. Docker's published ports skip host
firewalls such as `ufw`, so do not rely on the firewall to block them.

### Turning on the Traefik dashboard

The dashboard is off because it has no login by default. To enable it, add
`--api.dashboard=true` in `stack/compose.override.yaml` and put it behind a
router that uses Traefik's `basicAuth` or `forwardAuth` middleware. Never use
`--api.insecure=true`.

## Reference

### Scripts

| Command | What it does |
| ------- | ------------ |
| `./setup.sh` | Start `dind`, build and start the inner containers, wait until healthy. Safe to run again. |
| `./teardown.sh` | Stop and remove all containers. Keeps images and data. |
| `./teardown.sh --volumes` | Same, and also delete all images and data. |
| `./exec.sh <name>` | Open a shell in an inner container. |
| `./exec.sh <name> <command>` | Run one command in an inner container. |

To run any other Docker Compose command against the inner containers:

```bash
docker compose exec dind docker compose -f /workspace/stack/compose.yaml <command>
```

For example `ps`, `logs -f`, or `restart subdocker-2`.

### Files

```
compose.yaml          starts the dind container on your computer
stack/compose.yaml    the four containers that run inside dind
subdocker-1/          Dockerfile and startup script for subdocker-1
subdocker-2/          nginx config and web page for subdocker-2
setup.sh              start everything
teardown.sh           stop everything, optionally delete data
exec.sh               run a command or shell in an inner container
scripts/common.sh     shared code used by the scripts
.env.example          example settings; copy to .env
.github/              automated checks and dependency updates
```

### Requirements summary

- Docker Engine 24+ or Docker Desktop, with Docker Compose v2.20+
- Bash (on Windows, a WSL 2 terminal)
- Permission to run privileged containers

## License

[MIT](LICENSE)
