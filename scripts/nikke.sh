#!/usr/bin/env bash
# NIKKE(anime-games-launcher / dwproton)の起動ラッパー。
# 公式ランチャーの保留中の更新を反映し、更新終了時だけ自動再起動する。
set -euo pipefail

# --- 調整可能パラメータ ---
MAX_UPDATE_RESTARTS="${MAX_UPDATE_RESTARTS:-2}" # ランチャー更新による再起動回数の上限
WATCH_INTERVAL_S=5                              # ゲーム起動確認のポーリング間隔

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die() {
  printf '\033[1;31m[err]\033[0m %s\n' "$*" >&2
  exit 1
}

# --- パス解決(AGL 非依存。安定パス + nix store の dwproton) ---
# 実体は AGL のハッシュパスではなく XDG 配下の固定パスに置く。dwproton は nix が
# NIKKE_PROTON で渡す(= ラッパー経由起動が前提)。umu は nixpkgs umu-launcher を使う。
# steam-run で umu をくるむのは AGL の既知良好構成の踏襲(FHS を与え bwrap 即死を避ける)。
NIKKE_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/nikke"
PREFIX="$NIKKE_HOME/prefix"
PROTON="${NIKKE_PROTON:-}"
LAUNCHER="$PREFIX/drive_c/NIKKE/Launcher/nikke_launcher.exe"
LAUNCHER_DIR="${LAUNCHER%/*}"
LAUNCHER_UPDATE_DIR="$LAUNCHER_DIR/update_files"
# umu/proton/launcher の各プロセス argv には $LAUNCHER(=prefix 絶対パス)が乗る。
# これをセッション生存判定/kill のトークンにする(旧 AGL の goddess_of_victory_nikke 相当)。
# nikke ラッパー自身の argv には prefix パスが出ないため pkill の self-match は起きない。
SESSION_MATCH="$PREFIX"
UMU="$(command -v umu-run || true)"
STEAMRUN="$(command -v steam-run || true)"
[ -x "$UMU" ] || die "umu-run が見つからない(nixpkgs umu-launcher を導入してください)"

# --- プロセス判定ヘルパ ---
# 本体プロセス(nikke.exe)は pressure-vessel の PID namespace 内にあり host の pgrep から見えない。
# よって本体の有無はウィンドウで判定する: steam_proton・title=NIKKE 窓はランチャー単体で 1 枚、
# 本体(ゲーム画面)が出ると 2 枚以上になる。NIKKE はランチャーが常駐するのでこの判定で足りる。
nikke_window_count() {
  { command -v hyprctl && command -v jq; } >/dev/null 2>&1 || {
    echo 0
    return
  }
  hyprctl clients -j 2>/dev/null | jq -r '[.[] | select(.class == "steam_proton" and .title == "NIKKE")] | length' 2>/dev/null || echo 0
}
game_running() { [ "$(nikke_window_count)" -ge 2 ]; }
session_running() { pgrep -f "$SESSION_MATCH" >/dev/null 2>&1; }

# 宙吊りセッションを畳む。prefix 固有トークンで一致(pkill は自 PID を除外するので self-match しない)。
cleanup_session() {
  pkill -TERM -f "$SESSION_MATCH" 2>/dev/null || true
  for _ in 1 2 3 4 5; do
    session_running || break
    sleep 1
  done
  session_running && pkill -KILL -f "$SESSION_MATCH" 2>/dev/null
}

# 公式ランチャーは自己更新を update_files/ へ展開するが、Wine 上では実行中の exe/DLL を
# Windows と同じ手順で置換できない。セッション停止中に限り内容を Launcher/ へ反映する。
# コピーに失敗した場合は update_files/ を残し、次回の再実行や手動調査を可能にする。
apply_launcher_update() {
  [ -e "$LAUNCHER_UPDATE_DIR" ] || return 0
  [ -d "$LAUNCHER_UPDATE_DIR" ] || die "ランチャー更新先がディレクトリではない: $LAUNCHER_UPDATE_DIR"
  [ ! -L "$LAUNCHER_UPDATE_DIR" ] || die "ランチャー更新先がシンボリックリンクになっている: $LAUNCHER_UPDATE_DIR"
  session_running && die "NIKKE セッション稼働中のためランチャーを更新できない"
  case "$LAUNCHER_UPDATE_DIR" in
  "$PREFIX/drive_c/NIKKE/Launcher/update_files") ;;
  *) die "安全でないランチャー更新パス: $LAUNCHER_UPDATE_DIR" ;;
  esac

  log "保留中のランチャー更新を反映: $LAUNCHER_UPDATE_DIR"
  cp -a -- "$LAUNCHER_UPDATE_DIR"/. "$LAUNCHER_DIR"/
  rm -rf -- "$LAUNCHER_UPDATE_DIR"
  [ -e "$LAUNCHER" ] || die "更新後のランチャーが見つからない: $LAUNCHER"
  log "ランチャー更新の反映完了"
}

# --- ランチャー起動 ---
launch_and_wait() {
  log "NIKKE 起動(steam-run + umu-run / AGL 再現)"
  # AGL の実起動を再現: PROTON_USE_WOW64=1 を付け、steam-run で umu-run をくるむ。
  # STORE=none は AGL は付けない(付けると umu の GAMEID 解決経路が変わる)ので外す。
  # setsid で新セッション化し、nikke スクリプト/端末のプロセスグループから切り離す。
  # nohup だけだと SIGHUP は防げても Ctrl-C(SIGINT)は同一 pgroup 経由でゲームまで届き
  # セッションごと落ちる。setsid + </dev/null で端末を完全に手放し、ラッパーや端末が
  # 死んでもゲームは残す。umu/proton の出力は死因追跡のため umu.log に残す。
  GAMEID=umu-nikke PROTON_USE_WOW64=1 UMU_RUNTIME_UPDATE=0 PROTONPATH="$PROTON" WINEPREFIX="$PREFIX" \
    setsid ${STEAMRUN:+"$STEAMRUN"} "$UMU" "$LAUNCHER" </dev/null >"$NIKKE_HOME/umu.log" 2>&1 &
  # session(umu)が生きている限り本体ウィンドウの出現を待つ。ログイン完了までの時間は
  # ユーザー操作次第で読めないため固定タイムアウトは置かない。session が落ちれば起動失敗とみなす。
  while session_running; do
    game_running && {
      log "本体ウィンドウ出現 → 起動成功"
      return 0
    }
    sleep "$WATCH_INTERVAL_S"
  done
  warn "セッションが終了(本体ウィンドウ未出現)"
  return 1
}

cmd_run() {
  [ -n "$PROTON" ] || die "NIKKE_PROTON 未設定。端末直叩きでなく nix の nikke ラッパー経由で起動してください"
  [ -d "$PROTON" ] || die "dwproton が無い: $PROTON"
  [ -e "$LAUNCHER" ] || die "NIKKE が見つからない: $LAUNCHER (Miniloader で C:\\NIKKE へ導入してください)"
  log "prefix: $PREFIX"
  log "proton: $(basename "$PROTON")"
  apply_launcher_update
  local update_restarts=0
  while true; do
    if launch_and_wait; then
      log "NIKKE 起動完了"
      exit 0
    fi
    if [ -e "$LAUNCHER_UPDATE_DIR" ]; then
      if [ "$update_restarts" -ge "$MAX_UPDATE_RESTARTS" ]; then
        die "ランチャー更新が ${MAX_UPDATE_RESTARTS} 回続いたため停止。保留ファイル: $LAUNCHER_UPDATE_DIR"
      fi
      update_restarts=$((update_restarts + 1))
      log "ランチャー更新を検出。反映して再起動 (${update_restarts}/${MAX_UPDATE_RESTARTS})"
      apply_launcher_update
      continue
    fi
    die "ゲーム本体が起動する前に NIKKE セッションが終了しました。ログ: $NIKKE_HOME/umu.log"
  done
}

# ゲームやWineセッションが固まった状態を手で畳むための出口。
cmd_kill() {
  if ! session_running; then
    log "NIKKE セッションは動いていない"
    return 0
  fi
  log "NIKKE セッションを畳む"
  cleanup_session
  session_running && die "セッションを終了できなかった。手動で確認してください。"
  log "終了"
}

usage() {
  cat <<'EOF'
usage: nikke [run|kill]
  run     (既定) NIKKE を起動し、ランチャー更新を反映
  kill    固まった/残ったセッションを畳む

env:
  MAX_UPDATE_RESTARTS=2  ランチャー更新による再起動回数の上限
EOF
}

main() {
  case "${1:-run}" in
  run | "") cmd_run ;;
  kill) cmd_kill ;;
  -h | --help | help) usage ;;
  *)
    usage
    exit 1
    ;;
  esac
}

main "$@"
