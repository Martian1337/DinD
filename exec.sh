#!/usr/bin/env bash
# Runs a command in a sub-docker, or opens a shell when no command is given.
#
#   ./exec.sh subdocker-1                  interactive shell
#   ./exec.sh subdocker-1 curl --version   run one command
set -Eeuo pipefail

# shellcheck source=scripts/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/scripts/common.sh"

usage() { sed -n '2,5s/^# \{0,1\}//p' "${BASH_SOURCE[0]}"; }

case "${1:-}" in
    "") usage >&2; exit 2 ;;
    -h | --help) usage; exit 0 ;;
    *) ;;
esac

service="$1"
shift

if [[ $# -eq 0 ]]; then
    # Prefer bash when the image has it.
    set -- sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'
fi

require_docker
dind_running || die "the dind service is not running; run ./setup.sh first"

if [[ -t 0 && -t 1 ]]; then
    inner_compose --tty exec "$service" "$@"
else
    inner_compose exec -T "$service" "$@"
fi
