# subdocker-2

nginx running from a pre-built Docker Hub image inside the Docker-in-Docker
daemon. Nothing is built here. This directory holds the config and content,
mounted read-only into the container.

## Image

[`nginxinc/nginx-unprivileged`](https://hub.docker.com/r/nginxinc/nginx-unprivileged),
pinned by tag and digest in `stack/compose.yaml`. The official nginx build,
running as a non-root user (uid 101) on port 8080.

## Files

- `nginx/default.conf`: server config. Serves `html/`, answers `/healthz` for
  the health check, allows only `GET` and `HEAD`, refuses dotfiles, and hides
  the nginx version.
- `html/index.html`: the page served at `/`.

Changes under `html/` show up on the next page load. After editing
`default.conf`, restart the service:

```bash
docker compose exec dind docker compose -f /workspace/stack/compose.yaml restart subdocker-2
```

## Access

Traefik sends every request on the published port to subdocker-2
(<http://127.0.0.1:8080/> by default) and adds the security headers.

subdocker-2 is only on the internal `web-backend` network: no published port,
no internet access, and nothing reachable except Traefik.

```bash
./exec.sh subdocker-2 nginx -T   # print the effective config
```
