# subdocker-1

A small Debian image with curl, built from the local `Dockerfile` inside the
Docker-in-Docker daemon.

## What it does

On start, `run-commands.sh`:

1. Fetches `TARGET_URL` (default `https://example.com`) with `curl`, over HTTPS
   only, with retries and timeouts.
2. Appends a line with the timestamp, HTTP status, and URL to
   `/data/runs.log` on the persistent `subdocker-1-data` volume.
3. Writes `/tmp/ready`, which the health check looks for.
4. Hands off to the container command, `sleep infinity` by default, so the
   container stays up and you can exec into it.

If the fetch fails, the script exits non-zero, the container restarts, and
`./setup.sh` reports it unhealthy. Put your own startup commands in
`run-commands.sh` before `touch /tmp/ready`.

## Files

- `Dockerfile`: Debian trixie slim, pinned by digest, with `curl` and
  `ca-certificates`. Runs as the unprivileged user `app` (uid 10001).
- `run-commands.sh`: the startup script.
- `.dockerignore`: limits the build context to `run-commands.sh`.

## Usage

`./setup.sh` builds and starts it. From the repository root:

```bash
./exec.sh subdocker-1                     # interactive bash shell
./exec.sh subdocker-1 curl --version      # single command
./exec.sh subdocker-1 cat /data/runs.log  # startup history
```

After editing the `Dockerfile` or `run-commands.sh`, run `./setup.sh` again to
rebuild and recreate the container.

## Runtime restrictions

Set in `stack/compose.yaml`: read-only root filesystem (only `/data` and a
small `/tmp` tmpfs are writable), all capabilities dropped,
`no-new-privileges`, an init process as PID 1, 128 MiB memory, and 64
processes. It is only on the `egress` network, so it can reach the internet
but not Traefik, the socket proxy, or subdocker-2.
