#!/usr/bin/env bash
set -uo pipefail

INTERVAL="${WALLSET_INTERVAL:-1800}"
PICKER="${HOME}/.config/hypr/scripts/wallset-pick-random.sh"

while :; do
  sleep "$INTERVAL"
  "$PICKER" || echo "[wallset-rotate-loop] pick failed (continuing)" >&2
done
