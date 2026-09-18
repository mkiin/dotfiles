#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# 壁紙・テーマ適用スクリプト (apply.sh)
#
# 役割:
#   1. awww による壁紙切り替え（トランジション付き）
#   2. matugen / wallust によるカラーパレットの並列生成
#   3. 各 UI（Waybar, Ghostty, Hyprland 等）へのリロード通知
#   4. hyprlock 用の固定キャッシュリンク (~/.cache/current_wallpaper) 更新
# ==============================================================================

# --- 定数・アニメーション設定 ------------------------------------------------
TRANSITION_TYPE="grow"
TRANSITION_FPS=120
TRANSITION_DURATION=3
TRANSITION_STEP=90
TRANSITION_BEZIER=".23,1,.32,1"

# --- パス設定 -----------------------------------------------------------------
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
LOG="$STATE_DIR/wallpaper-apply.log"
LAST="$STATE_DIR/last_wallpaper"
LAST_COLORED="$STATE_DIR/last_colored"
CURRENT_WALLPAPER="$CACHE_DIR/current_wallpaper"

img="${1:?usage: apply.sh <image>}"
mkdir -p "$STATE_DIR" "$CACHE_DIR"

log() { printf '[%s pid=%d apply] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

# pyprland ローテーションと手動呼び出しの競合を直列化し後勝ちで収束させる
exec {LOCK_FD}>"$STATE_DIR/apply.lock"
flock -x "$LOCK_FD"

# ログが肥大化したら切り詰める (ローテーション)
if [[ -s $LOG ]] && (($(wc -l <"$LOG") > 2000)); then
  tail -n 1000 "$LOG" >"$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

log "=== invoked img=$img"

# output ごとの表示状態を取得
displayed() { awww query 2>/dev/null | sed -n 's/.*currently displaying: //p' | sort -u; }
want="image: $img"

apply_img() {
  awww img "$img" \
    --transition-type "$TRANSITION_TYPE" \
    --transition-fps "$TRANSITION_FPS" \
    --transition-duration "$TRANSITION_DURATION" \
    --transition-step "$TRANSITION_STEP" \
    --transition-bezier "$TRANSITION_BEZIER"
}

# --- 1. output 揃い待ち ------------------------------------------------------
force=0
expected=$(hyprctl monitors -j 2>/dev/null | jq 'length' || echo 0)
[[ $expected =~ ^[0-9]+$ ]] || expected=0
if ((expected > 0)); then
  for _ in $(seq 1 50); do
    (($(awww query 2>/dev/null | wc -l) == expected)) && break
    sleep 0.1
  done
  actual=$(awww query 2>/dev/null | wc -l)
  if ((actual != expected)); then
    force=1
    log "output wait timeout actual=$actual expected=$expected"
  fi
else
  for _ in $(seq 1 50); do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
  done
fi

# --- 2. 壁紙の表示 (awww) ----------------------------------------------------
if ((force == 0)) && [[ "$(displayed)" == "$want" ]]; then
  log "display up-to-date, skip img"
else
  apply_img || log "awww img failed rc=$?"
  # 検証: IPC受理だけでなく実表示を再確認
  if [[ "$(displayed)" != "$want" ]]; then
    log "verify failed, re-push"
    apply_img || log "awww img re-push failed rc=$?"
  fi
fi

if [[ "$(displayed)" != "$want" ]]; then
  log "MISMATCH shown=[$(displayed | paste -sd' ' -)]"
  exit 1
fi

# --- 3. テーマ・色の生成 (matugen & wallust 並列処理) ------------------------
if [[ "$(cat "$LAST_COLORED" 2>/dev/null)" == "$img" ]]; then
  log "colors up-to-date, skip"
else
  declare -a PIDS=() TAGS=()
  PIPELINE_OK=1

  spawn() {
    local tag="$1"
    shift
    ("$@") >>"$LOG" 2>&1 &
    PIDS+=("$!")
    TAGS+=("$tag")
  }

  wait_all() {
    local i rc
    for i in "${!PIDS[@]}"; do
      rc=0
      wait "${PIDS[$i]}" || rc=$?
      ((rc == 0)) || PIPELINE_OK=0
      log "${TAGS[$i]} exit=$rc"
    done
    PIDS=()
    TAGS=()
  }

  matugen_with_fallback() {
    matugen image "$1" --source-color-index "$2" ||
      matugen image "$1" --source-color-index 0
  }

  # matugen (色抽出インデックスは 0 固定)
  source_idx=0
  log "matugen SOURCE_IDX=$source_idx"

  spawn matugen matugen_with_fallback "$img" "$source_idx"
  spawn wallust wallust run "$img" --quiet
  wait_all

  # 各アプリケーションのリロード通知
  "$HOME/.config/waybar/scripts/reload-css.sh" 2>>"$LOG" ||
    log "waybar/reload-css failed rc=$?"

  pkill -x -SIGUSR2 ghostty 2>>"$LOG" &&
    log "ghostty SIGUSR2 sent" ||
    log "ghostty SIGUSR2 failed rc=$? (no running ghostty?)"

  hyprctl reload 2>>"$LOG" || log "hyprctl reload failed rc=$?"

  if ((PIPELINE_OK)); then
    echo "$img" >"$LAST_COLORED"
  fi
fi

# --- 4. 状態の記録 & hyprlock 用シンボリックリンク更新 -----------------------
echo "$img" >"$LAST"

# hyprlock が参照する ~/.cache/current_wallpaper をアトミックに更新
ln -sf "$img" "$CURRENT_WALLPAPER"

log "=== complete last_wallpaper=$img"
