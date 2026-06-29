#!/usr/bin/env bash
set -euo pipefail

DEV="$(ratbagctl list 2>/dev/null | awk -F: 'NR==1 && /G703/ {print $1}')"
if [[ -z ${DEV:-} ]]; then
  echo "G703 not detected (offline or ratbagd down)" >&2
  exit 1
fi

run() {
  if [[ ${DRY_RUN:-0} == "1" ]]; then
    echo "ratbagctl $DEV $*"
  else
    ratbagctl "$DEV" "$@"
  fi
}

run profile active set 0
run rate set 1000

run resolution 0 dpi set 1600
run resolution active set 0

run button 3 action set button 4
run button 4 action set button 5
run button 5 action set key KEY_F24

for p in 1 2 3 4; do
  run profile $p dpi set 1600
done
