#!/usr/bin/env bash
# Starts the Docker-in-Docker daemon, then builds and starts the inner stack
# (Traefik, socket proxy, subdocker-1, subdocker-2) inside it.
set -Eeuo pipefail

# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/scripts/common.sh"

require_docker

log "Starting the Docker-in-Docker daemon"
host_compose up --detach --wait --wait-timeout 180 dind

log "Building and starting the inner stack"
inner_compose up --detach --build --wait --wait-timeout 300 --remove-orphans

log "Inner stack status"
inner_compose ps

endpoint="$(host_compose port dind 80)"
log "Done. subdocker-2 is available at http://${endpoint}/"
