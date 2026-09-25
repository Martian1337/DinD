#!/usr/bin/env bash
# Startup commands for subdocker-1, then exec the container command.
set -Eeuo pipefail

: "${TARGET_URL:=https://example.com}"

log() { printf '%s subdocker-1: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }

rm -f /tmp/ready

log "fetching ${TARGET_URL}"
# HTTPS only, including redirects.
status="$(curl --fail --silent --show-error --location \
    --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --retry 3 --retry-delay 2 --connect-timeout 10 --max-time 30 \
    --output /dev/null --write-out '%{http_code}' \
    -- "${TARGET_URL}")"
log "received HTTP ${status}"

# Record the run on the persistent volume.
printf '%s %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${status}" "${TARGET_URL}" >> /data/runs.log

# Add more startup commands here.

touch /tmp/ready
log "startup commands finished"

exec "$@"
