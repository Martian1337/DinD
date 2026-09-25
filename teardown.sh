#!/usr/bin/env bash
# Stops the inner stack and the Docker-in-Docker daemon.
#
#   ./teardown.sh             stop and remove containers, keep all data
#   ./teardown.sh --volumes   also delete the dind volume (inner images,
#                             containers, and the subdocker-1 data volume)
set -Eeuo pipefail

# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/scripts/common.sh"

usage() { sed -n '2,7s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }

purge=false
case "${1:-}" in
    "") ;;
    -v | --volumes) purge=true ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

require_docker

if dind_running; then
    log "Stopping the inner stack"
    inner_compose down --remove-orphans
fi

if [[ "$purge" == true ]]; then
    log "Removing the Docker-in-Docker daemon and its volume"
    host_compose down --remove-orphans --volumes
else
    log "Removing the Docker-in-Docker daemon (data volume kept)"
    host_compose down --remove-orphans
fi
