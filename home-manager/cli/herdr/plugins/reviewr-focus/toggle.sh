#!/usr/bin/env bash
set -euo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
workspace_id="${HERDR_WORKSPACE_ID:?reviewr-focus: no workspace context}"
current_tab="${HERDR_TAB_ID:?reviewr-focus: no tab context}"
state_dir="${HERDR_PLUGIN_STATE_DIR:?reviewr-focus: no state directory}"

before_panes=$("$herdr_bin" pane list --workspace "$workspace_id")
reviewr_tab=$(printf '%s' "$before_panes" | jq -r '
  [.result.panes[] | select(.label == "reviewr") | .tab_id][0] // empty
')

save_origin() {
  mkdir -p "$state_dir"
  state_file="$state_dir/$workspace_id.last-tab"
  tmp="$state_file.tmp.$$"
  printf '%s\n' "$current_tab" >"$tmp"
  mv "$tmp" "$state_file"
}

if [ -n "$reviewr_tab" ] && [ "$current_tab" != "$reviewr_tab" ]; then
  save_origin
  "$herdr_bin" tab focus "$reviewr_tab" >/dev/null
  exit 0
fi

if [ -n "$reviewr_tab" ]; then
  state_file="$state_dir/$workspace_id.last-tab"
  [ -s "$state_file" ] || exit 0
  target_tab=$(cat "$state_file")
  if ! "$herdr_bin" tab get "$target_tab" >/dev/null 2>&1; then
    rm -f "$state_file"
    exit 0
  fi
  "$herdr_bin" tab focus "$target_tab" >/dev/null
  exit 0
fi

if [ -z "$reviewr_tab" ]; then
  save_origin
fi

invoke=$("$herdr_bin" plugin action invoke toggle --plugin persiyanov.reviewr)
log_id=$(printf '%s' "$invoke" | jq -r '.result.log.log_id // empty')
[ -n "$log_id" ] || {
  printf 'reviewr-focus: toggle did not return a log id\n' >&2
  exit 1
}

for _ in $(seq 1 50); do
  logs=$("$herdr_bin" plugin log list --plugin persiyanov.reviewr --limit 20)
  status=$(printf '%s' "$logs" | jq -r --arg id "$log_id" '
    [.result.logs[] | select(.log_id == $id) | .status][0] // empty
  ')
  case "$status" in
  succeeded) break ;;
  failed)
    printf 'reviewr-focus: reviewr toggle failed\n' >&2
    exit 1
    ;;
  esac
  sleep 0.02
done

[ "$status" = succeeded ] || {
  printf 'reviewr-focus: timed out waiting for reviewr toggle\n' >&2
  exit 1
}

panes=$("$herdr_bin" pane list --workspace "$workspace_id")
tab_id=$(printf '%s' "$panes" | jq -r '
  [.result.panes[] | select(.label == "reviewr") | .tab_id][0] // empty
')

[ -z "$tab_id" ] || "$herdr_bin" tab focus "$tab_id" >/dev/null
