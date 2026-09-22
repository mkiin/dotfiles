#!/usr/bin/env bash
set -euo pipefail

MAX_UPDATE_RESTARTS="${MAX_UPDATE_RESTARTS:-2}"
WATCH_INTERVAL_S="${WATCH_INTERVAL_S:-5}"

NIKKE_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/nikke"
PREFIX="$NIKKE_HOME/prefix"
PROTON="${NIKKE_PROTON:-}"

LAUNCHER="$PREFIX/drive_c/NIKKE/Launcher/nikke_launcher.exe"
LAUNCHER_DIR="${LAUNCHER%/*}"
LAUNCHER_UPDATE_DIR="$LAUNCHER_DIR/update_files"

LOG_FILE="$NIKKE_HOME/umu.log"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/nikke-$UID}/nikke"
SID_FILE="$RUNTIME_DIR/session-id"

log() {
  printf '\n\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[warn]\033[0m %s\n' "$*"
}

die() {
  printf '\033[1;31m[err]\033[0m %s\n' "$*" >&2
  exit 1
}

read_session_id() {
  [ -r "$SID_FILE" ] || return 1

  local sid
  sid="$(cat "$SID_FILE" 2>/dev/null || true)"

  case "$sid" in
  '' | *[!0-9]*)
    rm -f "$SID_FILE"
    return 1
    ;;
  esac

  printf '%s\n' "$sid"
}

session_running() {
  local sid
  sid="$(read_session_id)" || return 1

  if pgrep -s "$sid" >/dev/null 2>&1; then
    return 0
  fi

  rm -f "$SID_FILE"
  return 1
}

cleanup_session() {
  local sid
  sid="$(read_session_id)" || return 0

  if ! pgrep -s "$sid" >/dev/null 2>&1; then
    rm -f "$SID_FILE"
    return 0
  fi

  log "Stopping NIKKE session (SID=$sid)"
  pkill -TERM -s "$sid" 2>/dev/null || true

  for _ in 1 2 3 4 5; do
    if ! pgrep -s "$sid" >/dev/null 2>&1; then
      rm -f "$SID_FILE"
      return 0
    fi
    sleep 1
  done

  warn "Session did not terminate; sending SIGKILL"
  pkill -KILL -s "$sid" 2>/dev/null || true
  sleep 1

  if pgrep -s "$sid" >/dev/null 2>&1; then
    return 1
  fi

  rm -f "$SID_FILE"
}

nikke_window_count() {
  command -v hyprctl >/dev/null 2>&1 || {
    echo 0
    return
  }

  hyprctl clients -j 2>/dev/null |
    jq -r '
      [
        .[]
        | select(.class == "steam_proton" and .title == "NIKKE")
      ]
      | length
    ' 2>/dev/null || echo 0
}

game_running() {
  [ "$(nikke_window_count)" -ge 2 ]
}

apply_launcher_update() {
  [ -e "$LAUNCHER_UPDATE_DIR" ] || return 0

  [ -d "$LAUNCHER_UPDATE_DIR" ] ||
    die "Launcher update path is not a directory: $LAUNCHER_UPDATE_DIR"

  [ ! -L "$LAUNCHER_UPDATE_DIR" ] ||
    die "Launcher update path must not be a symlink: $LAUNCHER_UPDATE_DIR"

  session_running &&
    die "Cannot update launcher while the NIKKE session is running"

  case "$LAUNCHER_UPDATE_DIR" in
  "$PREFIX/drive_c/NIKKE/Launcher/update_files") ;;
  *) die "Unsafe launcher update path: $LAUNCHER_UPDATE_DIR" ;;
  esac

  log "Applying pending launcher update"

  cp -a -- "$LAUNCHER_UPDATE_DIR"/. "$LAUNCHER_DIR"/
  rm -rf -- "$LAUNCHER_UPDATE_DIR"

  [ -e "$LAUNCHER" ] ||
    die "Launcher disappeared after update: $LAUNCHER"

  log "Launcher update applied"
}

launch_and_wait() {
  mkdir -p "$NIKKE_HOME" "$RUNTIME_DIR"

  session_running &&
    die "A NIKKE session is already running; use 'nikke kill' first"

  rm -f "$SID_FILE"

  log "Starting NIKKE"
  log "Proton: $PROTON"

  GAMEID=umu-nikke \
    PROTON_USE_WOW64=1 \
    UMU_RUNTIME_UPDATE=0 \
    PROTONPATH="$PROTON" \
    WINEPREFIX="$PREFIX" \
    setsid \
    steam-run \
    umu-run \
    "$LAUNCHER" \
    </dev/null \
    >"$LOG_FILE" 2>&1 &

  local sid=$!
  printf '%s\n' "$sid" >"$SID_FILE"

  log "Session started (SID=$sid)"

  while session_running; do
    if game_running; then
      log "Game window detected"
      return 0
    fi

    sleep "$WATCH_INTERVAL_S"
  done

  warn "Session exited before the game window appeared"
  return 1
}

cmd_run() {
  [ -n "$PROTON" ] ||
    die "NIKKE_PROTON is not set"

  [ -d "$PROTON" ] ||
    die "DWProton directory not found: $PROTON"

  [ -e "$PROTON/proton" ] ||
    die "Invalid Proton directory: $PROTON"

  [ -e "$LAUNCHER" ] ||
    die "NIKKE launcher not found: $LAUNCHER"

  log "Prefix: $PREFIX"
  log "Proton: $PROTON"

  apply_launcher_update

  local update_restarts=0

  while true; do
    if launch_and_wait; then
      log "NIKKE started"
      return 0
    fi

    if [ ! -e "$LAUNCHER_UPDATE_DIR" ]; then
      die "NIKKE exited before launch; see $LOG_FILE"
    fi

    if [ "$update_restarts" -ge "$MAX_UPDATE_RESTARTS" ]; then
      die "Launcher update restart limit reached: $MAX_UPDATE_RESTARTS"
    fi

    update_restarts=$((update_restarts + 1))

    log "Launcher update detected (${update_restarts}/${MAX_UPDATE_RESTARTS})"
    apply_launcher_update
  done
}

cmd_kill() {
  if ! session_running; then
    log "No NIKKE session is running"
    return 0
  fi

  cleanup_session ||
    die "Failed to terminate NIKKE session"

  log "NIKKE session stopped"
}

cmd_status() {
  local sid

  if ! sid="$(read_session_id)"; then
    echo "NIKKE: stopped"
    return 0
  fi

  if ! session_running; then
    echo "NIKKE: stopped"
    return 0
  fi

  echo "NIKKE: running (SID=$sid)"
  pgrep -a -s "$sid" 2>/dev/null || true
}

usage() {
  cat <<'EOF'
Usage: nikke [run|kill|status]

Commands:
  run      Start NIKKE
  kill     Stop the current NIKKE session
  status   Show the current session state

Environment:
  NIKKE_PROTON         DWProton directory
  MAX_UPDATE_RESTARTS  Launcher update restart limit (default: 2)
  WATCH_INTERVAL_S     Game window polling interval (default: 5)
EOF
}

main() {
  case "${1:-run}" in
  run | "")
    cmd_run
    ;;
  kill)
    cmd_kill
    ;;
  status)
    cmd_status
    ;;
  -h | --help | help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
  esac
}

main "$@"
