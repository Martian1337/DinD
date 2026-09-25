# shellcheck shell=bash
# Helpers sourced by setup.sh, teardown.sh, and exec.sh.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

# Paths inside the dind container.
readonly INNER_COMPOSE_FILE=/workspace/stack/compose.yaml
readonly INNER_OVERRIDE_FILE=/workspace/stack/compose.override.yaml
readonly INNER_ENV_FILE=/workspace/.env

log() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

require_docker() {
    command -v docker >/dev/null 2>&1 || die "docker is not installed or not on PATH"
    docker compose version >/dev/null 2>&1 || die "Docker Compose v2 ('docker compose') is required"
    docker info >/dev/null 2>&1 || die "cannot reach the Docker daemon (is it running, and can this user access it?)"
}

# docker compose for the host-level stack.
host_compose() {
    local files=(-f "$REPO_ROOT/compose.yaml")
    if [[ -f "$REPO_ROOT/compose.override.yaml" ]]; then
        files+=(-f "$REPO_ROOT/compose.override.yaml")
    fi
    docker compose --project-directory "$REPO_ROOT" "${files[@]}" "$@"
}

dind_running() {
    [[ -n "$(host_compose ps --status running --quiet dind 2>/dev/null)" ]]
}

# docker compose for the inner stack, run inside the dind container.
# Usage: inner_compose [--tty] <compose args...>
inner_compose() {
    local tty_flag=-T
    if [[ "${1:-}" == "--tty" ]]; then
        tty_flag=
        shift
    fi

    # The socket proxy needs the group that owns the inner daemon's socket.
    local sock_gid
    sock_gid="$(host_compose exec -T dind stat -c %g /var/run/docker.sock)" \
        || die "could not read the inner Docker socket; is the dind service healthy?"

    local args=(exec ${tty_flag:+"$tty_flag"} -e "DOCKER_SOCKET_GID=${sock_gid}" dind docker compose)
    if [[ -f "$REPO_ROOT/.env" ]]; then
        args+=(--env-file "$INNER_ENV_FILE")
    fi
    args+=(-f "$INNER_COMPOSE_FILE")
    if [[ -f "$REPO_ROOT/stack/compose.override.yaml" ]]; then
        args+=(-f "$INNER_OVERRIDE_FILE")
    fi

    host_compose "${args[@]}" "$@"
}
