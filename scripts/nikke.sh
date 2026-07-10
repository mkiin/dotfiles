#!/usr/bin/env bash
# NIKKE(anime-games-launcher / dwproton)を ACE の初期化レースに強い形で起動する監視ラッパー。
# ACE 本体は一切改ざんしない。「正しく初期化させる」ための無侵襲な下ごしらえ+自動リトライ+宙吊り復旧のみ。
#   1. Steam を健全化(古い常駐は ACE-kick 要因。ACE 初期化には Steam 常駐が要る)
#   2. ACE サービスの Start を 4(遅延起動)にする冪等な system.reg tweak
#   3. lottery 起動: 初期化ウィンドウ内に本体が出なければ畳んで自動リトライ。出たらウォッチドッグへ
set -euo pipefail

# --- 調整可能パラメータ ---
STEAM_MAX_UPTIME_H="${STEAM_MAX_UPTIME_H:-3}" # Steam 常駐がこの時間を超えたら再起動を促す
MAX_RETRIES="${MAX_RETRIES:-4}"               # 起動失敗(session 早期終了)時のリトライ回数
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
# AGL の既知良好構成を再現する。AGL は同梱 umu-run を steam-run(FHS)でくるんで叩く。
# steam-run が FHS を与えるので「同梱 umu-run が素 bwrap を拾い即死」問題は起きない。
# pkgs.umu-launcher に差し替えるとランタイムコンテナの組み方が変わり体感が重くなるため、
# 同梱 umu-run を最優先(無い時だけ pkgs へフォールバック)。
UMU="$PKG_DIR/umu-run"
[ -x "$UMU" ] || UMU="$(command -v umu-run || true)"
STEAMRUN="$(command -v steam-run || true)"
[ -e "$LAUNCHER" ] || die "nikke_launcher.exe が無い: $LAUNCHER"
[ -d "$PROTON" ] || die "dwproton が無い: $PKG_DIR/versions"
[ -x "$UMU" ] || die "umu-run が見つからない"

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
session_running() { pgrep -f 'goddess_of_victory_nikke' >/dev/null 2>&1; }
crashhandler_up() { pgrep -f 'UnityCrashHandler64\.exe' >/dev/null 2>&1; }

# NIKKE ランチャーの枠/影は steam_proton・空タイトルの Xwayland override-redirect 窓として
# 描かれ、本体を kill しても Hyprland のタイル境界に取り残され「端の残像」になる。
# 本体が完全に消えている前提で、残った steam_proton 窓を閉じる(稼働中は誤爆しないよう即 return)。
cleanup_stray_windows() {
  session_running && return 0
  command -v hyprctl >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0
  hyprctl clients -j 2>/dev/null |
    jq -r '.[] | select(.class == "steam_proton") | .address' 2>/dev/null |
    while read -r addr; do
      [ -n "$addr" ] && hyprctl dispatch closewindow "address:$addr" >/dev/null 2>&1 || true
    done
}

# 宙吊りセッションを畳む。prefix 固有トークンで一致(pkill は自 PID を除外するので self-match しない)。
cleanup_session() {
  pkill -TERM -f 'goddess_of_victory_nikke' 2>/dev/null || true
  for _ in 1 2 3 4 5; do
    session_running || break
    sleep 1
  done
  session_running && pkill -KILL -f 'goddess_of_victory_nikke' 2>/dev/null
  sleep 1
  cleanup_stray_windows
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
  log "NIKKE 起動(steam-run + umu-run / AGL 再現)"
  # AGL の実起動を再現: PROTON_USE_WOW64=1 を付け、steam-run で umu-run をくるむ。
  # STORE=none は AGL は付けない(付けると umu の GAMEID 解決経路が変わる)ので外す。
  GAMEID=umu-nikke PROTON_USE_WOW64=1 PROTONPATH="$PROTON" WINEPREFIX="$PREFIX" \
    nohup ${STEAMRUN:+"$STEAMRUN"} "$UMU" "$LAUNCHER" >/dev/null 2>&1 &
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

watchdog() {
  log "ウォッチドッグ開始(セッション終了を監視)。ランチャー窓を閉じてもゲームは残る。Ctrl-C で監視のみ終了。"
  # 生存判定は umu セッション(wine prefix)で行う。窓枚数だと「ランチャー窓を閉じた」と
  # 「ゲームが終わった」を区別できず誤って終了扱いする。セッションはランチャー窓を閉じても
  # 生きているので誤爆しない。ACE/Unity クラッシュで本体だけ消えセッションが宙吊りになる
  # 場合のみ、crashhandler かつ本体窓なしを検知して畳む。
  while session_running; do
    if crashhandler_up && ! game_running; then
      warn "本体が消えたのにセッションが宙吊り(ACE/Unity クラッシュ) → 自動復旧"
      cleanup_session
      notify "クラッシュを検知し、宙吊りセッションを自動で畳みました。再度起動できます。"
      return 1
    fi
    sleep "$WATCH_INTERVAL_S"
  done
  log "NIKKE 正常終了"
  cleanup_stray_windows
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
