#!/usr/bin/env bash
set -euo pipefail

DEV="ERGO M575SP"

run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    echo "solaar config \"$DEV\" $*"
  else
    solaar config "$DEV" "$@"
  fi
}

run dpi 1600
