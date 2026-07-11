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

# --- パス解決(AGL 非依存。安定パス + nix store の dwproton) ---
# 実体は AGL のハッシュパスではなく XDG 配下の固定パスに置く。dwproton は nix が
# NIKKE_PROTON で渡す(= ラッパー経由起動が前提)。umu は nixpkgs umu-launcher を使う。
# steam-run で umu をくるむのは AGL の既知良好構成の踏襲(FHS を与え bwrap 即死を避ける)。
NIKKE_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/nikke"
PREFIX="$NIKKE_HOME/prefix"
PROTON="${NIKKE_PROTON:-}"
LAUNCHER="$PREFIX/drive_c/NIKKE/Launcher/nikke_launcher.exe"
REG="$PREFIX/system.reg"
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
  pkill -TERM -f "$SESSION_MATCH" 2>/dev/null || true
  for _ in 1 2 3 4 5; do
    session_running || break
    sleep 1
  done
  session_running && pkill -KILL -f "$SESSION_MATCH" 2>/dev/null
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
  # setsid で新セッション化し、nikke スクリプト/端末のプロセスグループから切り離す。
  # nohup だけだと SIGHUP は防げても Ctrl-C(SIGINT)は同一 pgroup 経由でゲームまで届き
  # セッションごと落ちる。setsid + </dev/null で端末を完全に手放し、watchdog や端末が
  # 死んでもゲームは残す。umu/proton の出力は死因追跡のため umu.log に残す。
  GAMEID=umu-nikke PROTON_USE_WOW64=1 PROTONPATH="$PROTON" WINEPREFIX="$PREFIX" \
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

watchdog() {
  log "ウォッチドッグ開始(セッション終了を監視)。ランチャーを隠しても閉じてもゲームは残る。Ctrl-C で監視のみ終了。"
  # 観測専用。生存判定は umu セッション(wine prefix)のみで行い、こちらからは決して kill しない。
  # 旧実装は「crashhandler かつ本体窓なし」で宙吊りと見なし cleanup_session で強制 kill していたが、
  # ランチャーを「隠す」と窓が減って game_running=false になり、健全なセッションを誤って皆殺しにした。
  # 窓枚数でゲームの生死を判定するのが誤りの根。宙吊りの後始末は cmd_run 起動時の判定に委ね、
  # ここでは何も殺さない(健全なプレイを殺すより、稀な宙吊りを手動で畳む方が遥かにマシ)。
  while session_running; do
    sleep "$WATCH_INTERVAL_S"
  done
  log "NIKKE 正常終了"
  cleanup_stray_windows
  return 0
}

cmd_run() {
  [ -n "$PROTON" ] || die "NIKKE_PROTON 未設定。端末直叩きでなく nix の nikke ラッパー経由で起動してください"
  [ -d "$PROTON" ] || die "dwproton が無い: $PROTON"
  [ -e "$LAUNCHER" ] || die "NIKKE 未インストール。先に 'nikke install' を実行してください"
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

# 公式ミニローダ(コミュニティ報告では Linux での DL/更新が最新版より安定)。
# ローカルの exe を使いたい場合は NIKKE_INSTALLER_URL に file:// か別URLを指定。
INSTALLER_URL="${NIKKE_INSTALLER_URL:-https://nikke-en.com/NikkeMiniloader0.0.6.143.exe}"

# 空 prefix にインストーラを流して C:\NIKKE へ導入する(新PC用)。
bootstrap_install() {
  command -v curl >/dev/null 2>&1 || die "curl が無い。手動で prefix を用意するか curl を導入してください"
  mkdir -p "$NIKKE_HOME"
  local installer="$NIKKE_HOME/nikke_installer.exe"
  if [ ! -e "$installer" ]; then
    log "インストーラ取得: $INSTALLER_URL"
    curl -fL "$INSTALLER_URL" -o "$installer" || die "インストーラ取得に失敗: $INSTALLER_URL"
  fi
  preflight_steam
  log 'インストーラ起動。ウィザードで導入先を C:\NIKKE にしてください(完了まで数十GB DL)。'
  GAMEID=umu-nikke PROTON_USE_WOW64=1 PROTONPATH="$PROTON" WINEPREFIX="$PREFIX" \
    ${STEAMRUN:+"$STEAMRUN"} "$UMU" "$installer"
  [ -e "$LAUNCHER" ] || warn "導入後に $LAUNCHER が見つかりません。導入先が C:\\NIKKE か確認してください。"
}

cmd_install() {
  [ -n "$PROTON" ] && [ -d "$PROTON" ] || die "dwproton が無い。nikke ラッパー経由で実行してください"
  if [ -e "$LAUNCHER" ]; then
    log "既にインストール済み: $LAUNCHER"
    return 0
  fi
  # 現行機では AGL が作った 32G prefix を再DLせず安定パスへ移設する。
  local agl_pfx
  agl_pfx=$(find "$HOME/.local/share/anime-games-launcher/packages/persistent" \
    -maxdepth 4 -type d -path '*goddess_of_victory_nikke/pfx' 2>/dev/null | head -1)
  if [ -n "$agl_pfx" ] && [ -e "$agl_pfx/drive_c/NIKKE/Launcher/nikke_launcher.exe" ]; then
    log "既存 AGL prefix を検出 → 安定パスへ移設(再DL不要)"
    mkdir -p "$NIKKE_HOME"
    mv "$agl_pfx" "$PREFIX"
    log "移設完了: $PREFIX。AGL 残骸は 'nikke clean' で撤去できます。"
    return 0
  fi
  bootstrap_install
}

cmd_clean() {
  local agl="$HOME/.local/share/anime-games-launcher"
  # 未移設の NIKKE データを巻き込み削除しないよう警告(先に install で移設させる)。
  if [ ! -e "$LAUNCHER" ] &&
    find "$agl" -maxdepth 8 -path '*goddess_of_victory_nikke/pfx/drive_c/NIKKE*' -print -quit 2>/dev/null | grep -q .; then
    warn "AGL 内に未移設の NIKKE データがあります。先に 'nikke install'(自動移設)を実行しないと再DLになります。"
  fi
  local targets=(
    "$agl"
    "$HOME/.config/anime-games-launcher"
    "$HOME/.cache/anime-games-launcher"
    "$HOME/.local/share/applications/anime-games-launcher.desktop"
  )
  local found=() t
  for t in "${targets[@]}"; do
    [ -e "$t" ] && {
      printf '  %s (%s)\n' "$t" "$(du -sh "$t" 2>/dev/null | cut -f1)"
      found+=("$t")
    }
  done
  if [ "${#found[@]}" -eq 0 ]; then
    log "AGL 残骸なし。何もしません。"
    return 0
  fi
  log "上記を削除します。"
  if [ -t 0 ]; then
    read -r -p "本当に削除しますか? [y/N] " ans
    case "$ans" in
    [yY]*) ;;
    *)
      log "中止"
      return 0
      ;;
    esac
  else
    warn "非対話のためスキップ(対話端末で実行してください)"
    return 0
  fi
  for t in "${found[@]}"; do
    rm -rf "$t" && log "削除: $t"
  done
}

usage() {
  cat <<'EOF'
usage: nikke [run|install|clean]
  run     (既定) NIKKE を起動(Lottery + watchdog)
  install 初回セットアップ。既存 AGL prefix があれば移設、無ければ再DL
  clean   AGL の残骸(prefix/config/cache/desktop entry)を撤去
EOF
}

main() {
  case "${1:-run}" in
  run | "") cmd_run ;;
  install) cmd_install ;;
  clean) cmd_clean ;;
  -h | --help | help) usage ;;
  *)
    usage
    exit 1
    ;;
  esac
}

main "$@"
