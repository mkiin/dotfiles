#!/usr/bin/env bash
# NIKKE(anime-games-launcher / dwproton)を ACE の初期化レースに強い形で起動する監視ラッパー。
# ACE 本体は一切改ざんしない。「正しく初期化させる」ための無侵襲な下ごしらえ+自動リトライ+宙吊り復旧のみ。
#   1. Steam を健全化(古い常駐は ACE-kick 要因。ACE 初期化には Steam 常駐が要る)
#   2. ACE サービスの Start を 4(遅延起動)にする冪等な system.reg tweak
#   3. lottery 起動: 初期化ウィンドウ内に本体が出なければ畳んで自動リトライ。出たらウォッチドッグへ
set -euo pipefail

# --- 調整可能パラメータ ---
STEAM_MAX_UPTIME_H="${STEAM_MAX_UPTIME_H:-3}" # Steam 常駐がこの時間を超えたら再起動を促す
INIT_WINDOW_S="${INIT_WINDOW_S:-90}"          # 起動〜本体出現を待つ上限
MAX_RETRIES="${MAX_RETRIES:-4}"               # lottery リトライ回数
WATCH_INTERVAL_S=5                            # ウォッチドッグのポーリング間隔

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
die() {
  printf '\033[1;31m[err]\033[0m %s\n' "$*" >&2
  exit 1
}
notify() { command -v notify-send >/dev/null 2>&1 && notify-send "NIKKE" "$1" || true; }

# --- パス解決(AGL 更新でパッケージハッシュが変わっても追随) ---
AGL="$HOME/.local/share/anime-games-launcher"
PKG_DIR=$(find "$AGL/packages/persistent" -maxdepth 1 -type d -name '*lua_proton' 2>/dev/null | head -1)
[ -n "$PKG_DIR" ] || die "lua_proton パッケージが見つからない。先に AGL で NIKKE を一度導入してください。"
PREFIX="$PKG_DIR/prefixes/goddess_of_victory_nikke/pfx"
PROTON=$(find "$PKG_DIR/versions" -maxdepth 1 -type d -name 'dwproton-*' 2>/dev/null | sort -V | tail -1)
LAUNCHER="$PREFIX/drive_c/NIKKE/Launcher/nikke_launcher.exe"
REG="$PREFIX/system.reg"
UMU="$PKG_DIR/umu-run"
[ -e "$LAUNCHER" ] || die "nikke_launcher.exe が無い: $LAUNCHER"
[ -d "$PROTON" ] || die "dwproton が無い: $PKG_DIR/versions"
[ -x "$UMU" ] || UMU="$(command -v umu-run || true)"
[ -n "$UMU" ] || die "umu-run が見つからない"

# --- プロセス判定ヘルパ ---
# 本体は ...\NIKKE\game\nikke.exe。ランチャー(...\Launcher\nikke_launcher.exe)や CrashHandler とは区別する。'.' で wine の '\' を吸収。
game_running() { pgrep -f 'NIKKE.game.nikke\.exe' >/dev/null 2>&1; }
session_running() { pgrep -f 'goddess_of_victory_nikke' >/dev/null 2>&1; }
crashhandler_up() { pgrep -f 'UnityCrashHandler64\.exe' >/dev/null 2>&1; }

# 宙吊りセッションを畳む。prefix 固有トークンで一致(pkill は自 PID を除外するので self-match しない)。
cleanup_session() {
  pkill -TERM -f 'goddess_of_victory_nikke' 2>/dev/null || true
  for _ in 1 2 3 4 5; do
    session_running || return 0
    sleep 1
  done
  pkill -KILL -f 'goddess_of_victory_nikke' 2>/dev/null || true
  sleep 1
}

# --- 1. Steam 健全化 ---
preflight_steam() {
  local pid up_s up_h
  pid=$(pgrep -x steam | head -1 || true)
  if [ -z "$pid" ]; then
    log "Steam が起動していない → 起動する(ACE 初期化に必要)"
    start_steam
    return
  fi
  up_s=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ' || echo 0)
  up_h=$((up_s / 3600))
  if [ "$up_h" -ge "$STEAM_MAX_UPTIME_H" ]; then
    warn "Steam が ${up_h}h 起動しっぱなし(ACE-kick の要因)。再起動を推奨。"
    if [ -t 0 ]; then
      read -r -p "Steam を再起動しますか? [y/N] " ans
      case "$ans" in
      [yY]*) restart_steam ;;
      *) log "Steam 再起動をスキップ" ;;
      esac
    else
      warn "非対話のため Steam 再起動はスキップ(STEAM_MAX_UPTIME_H で調整可)"
    fi
  else
    log "Steam 起動 ${up_h}h(しきい値 ${STEAM_MAX_UPTIME_H}h 未満) → そのまま"
  fi
}
start_steam() {
  command -v steam >/dev/null 2>&1 || {
    warn "steam コマンドが無い。手動で起動してください。"
    return
  }
  nohup steam -silent >/dev/null 2>&1 &
  log "Steam の起動を待機..."
  for _ in $(seq 1 30); do
    pgrep -x steam >/dev/null 2>&1 && {
      sleep 5
      return
    }
    sleep 1
  done
  warn "Steam の起動確認がタイムアウト。続行します。"
}
restart_steam() {
  command -v steam >/dev/null 2>&1 || return
  log "Steam をシャットダウン"
  steam -shutdown >/dev/null 2>&1 || pkill -TERM -x steam || true
  for _ in $(seq 1 30); do
    pgrep -x steam >/dev/null 2>&1 || break
    sleep 1
  done
  pkill -KILL -x steam 2>/dev/null || true
  start_steam
}

# --- 2. ACE サービスの Start=4 tweak(冪等) ---
apply_reg_tweak() {
  [ -f "$REG" ] || {
    warn "system.reg が無い。tweak をスキップ"
    return
  }
  if session_running; then
    warn "prefix が稼働中。tweak は system.reg 停止時のみ → 一旦畳む"
    cleanup_session
  fi
  if ! grep -q '"Start"=dword:00000003' "$REG"; then
    log "ACE Start は既に非3(tweak 済み) → スキップ"
    return
  fi
  [ -f "$REG.orig" ] || cp -p "$REG" "$REG.orig" # 初回の素の状態を保全
  cp -p "$REG" "$REG.bak"                        # 直前状態
  local tmp
  tmp=$(mktemp)
  # ACE-BASE / AntiCheatExpert Protection ブロック内の Start:3 のみ 4 へ。他サービスの Start:3 は触らない。
  awk '
    /^\[/ { inblk = (index($0,"ACE-BASE]")>0 || index($0,"AntiCheatExpert Protection]")>0) }
    inblk && $0=="\"Start\"=dword:00000003" { $0="\"Start\"=dword:00000004" }
    { print }
  ' "$REG" >"$tmp"
  mv "$tmp" "$REG"
  log "ACE サービスの Start を 4(遅延起動)に設定(バックアップ: system.reg.bak)"
}

# --- 3. lottery 起動 + ウォッチドッグ ---
launch_once() {
  log "NIKKE 起動(umu-run)"
  GAMEID=umu-nikke STORE=none PROTONPATH="$PROTON" WINEPREFIX="$PREFIX" \
    nohup "$UMU" "$LAUNCHER" >/dev/null 2>&1 &
  local waited=0
  while [ "$waited" -lt "$INIT_WINDOW_S" ]; do
    game_running && {
      log "本体プロセス出現 → ACE ハンドシェイク成功"
      return 0
    }
    session_running || {
      warn "セッションが早期終了"
      return 1
    }
    sleep 3
    waited=$((waited + 3))
  done
  warn "初期化ウィンドウ(${INIT_WINDOW_S}s)内に本体が出現せず → ACE レース失敗とみなす"
  return 1
}

watchdog() {
  log "ウォッチドッグ開始(本体終了を監視)。Ctrl-C で監視のみ終了(ゲームは残る)。"
  while game_running; do sleep "$WATCH_INTERVAL_S"; done
  sleep 3
  if session_running && crashhandler_up; then
    warn "本体が消えたのにセッションが宙吊り(ACE/Unity クラッシュ) → 自動復旧"
    cleanup_session
    notify "クラッシュを検知し、宙吊りセッションを自動で畳みました。再度起動できます。"
    return 1
  fi
  log "NIKKE 正常終了"
  return 0
}

main() {
  log "prefix: $PREFIX"
  log "proton: $(basename "$PROTON")"
  preflight_steam
  apply_reg_tweak
  local n
  for n in $(seq 1 "$MAX_RETRIES"); do
    log "起動試行 $n/$MAX_RETRIES"
    if launch_once; then
      watchdog || true
      exit 0
    fi
    cleanup_session
    warn "リトライします..."
    sleep 2
  done
  die "$MAX_RETRIES 回試みても ACE の初期化に失敗。時間を置くか、Steam 再起動後に再試行してください。"
}

main "$@"
