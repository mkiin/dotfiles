#!/usr/bin/env bash
set -euo pipefail

# 壁紙の唯一の書き込み経路。表示(awww)と色(matugen/wallust)の順序をプロセス内の
# 逐次実行で保証する。正しさは呼び出しタイミングではなく awww query の実状態照合が担う。
# 呼び出し元: pyprland wallpapers command / mode.sh / 手動。

STATE="$HOME/.config/hypr/scripts/hyprctl-state"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
LOG="$STATE_DIR/wallpaper-apply.log"
LAST="$STATE_DIR/last_wallpaper"
LAST_COLORED="$STATE_DIR/last_colored"

img="${1:?usage: apply.sh <image>}"
mkdir -p "$STATE_DIR"

log() { printf '[%s pid=%d apply] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

# pyprland ローテーションと mode.sh の同時呼び出しを直列化し後勝ちで収束させる
exec {LOCK_FD}>"$STATE_DIR/apply.lock"
flock -x "$LOCK_FD"

if [[ -s $LOG ]] && (($(wc -l <"$LOG") > 2000)); then
  tail -n 1000 "$LOG" >"$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

log "=== invoked img=$img"

# output ごとの表示状態。画像未適用の output は "color: 000000" 行になるため、
# image/color を含む状態全体で比較し、黒モニタの存在を不一致として検出する。
displayed() { awww query 2>/dev/null | sed -n 's/.*currently displaying: //p' | sort -u; }
want="image: $img"

apply_img() {
  awww img "$img" \
    --transition-type "$("$STATE" get AWWW_TRANSITION_TYPE)" \
    --transition-fps "$("$STATE" get AWWW_TRANSITION_FPS)" \
    --transition-duration "$("$STATE" get AWWW_TRANSITION_DURATION)" \
    --transition-step "$("$STATE" get AWWW_TRANSITION_STEP)" \
    --transition-bezier "$("$STATE" get AWWW_TRANSITION_BEZIER)"
}

# --- 1. output 揃い待ち ---------------------------------------------------
# ソケット応答だけでは output 0 個でも通る(起動レースの原因)ため monitor 数と照合する。
# タイムアウト時は force=1 で入口ガードを無効化する。未登録 output は query に
# 行が出ず照合で検出できないため、無条件適用だけが遅延登録ケースを救える。
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
  # hyprctl が使えない環境ではソケット応答待ちまで劣化させる
  for _ in $(seq 1 50); do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
  done
fi

# --- 2-4. 表示 ------------------------------------------------------------
if ((force == 0)) && [[ "$(displayed)" == "$want" ]]; then
  # 照合: 同一画像の再適用(mode.sh 経由等)は再描画アニメーションごと省く
  log "display up-to-date, skip img"
else
  # daemon 停止等の失敗でもログを残して照合まで進める(set -e の即死を避ける)
  apply_img || log "awww img failed rc=$?"
  # 検証: awww img の正常終了は IPC 受理しか意味しない。実表示を読み直す
  if [[ "$(displayed)" != "$want" ]]; then
    log "verify failed, re-push"
    apply_img || log "awww img re-push failed rc=$?"
  fi
fi

if [[ "$(displayed)" != "$want" ]]; then
  # 古い画像から色を作らない。無限リトライせず次の契機(次の呼び出し)で収束させる
  log "MISMATCH shown=[$(displayed | paste -sd' ' -)]"
  exit 1
fi

# --- 5-7. 色 ---------------------------------------------------------------
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
  # matugen が指定 index で失敗したら 0 で再試行する safety net
  matugen_with_fallback() {
    matugen image "$1" --source-color-index "$2" ||
      matugen image "$1" --source-color-index 0
  }

  # --source-color-index 省略時に非 tty 起動で対話 UI に落ちて失敗するため必須
  if [[ "$("$STATE" get MATUGEN_RANDOM_INDEX)" == "true" ]]; then
    source_idx=$((RANDOM % 4))
  else
    source_idx=$("$STATE" get MATUGEN_SOURCE_INDEX)
  fi
  log "matugen SOURCE_IDX=$source_idx"

  spawn matugen matugen_with_fallback "$img" "$source_idx"
  # wallust: matugen が出さない @color0..15 (Pywal 系) を waybar style 用に追加生成
  spawn wallust wallust run "$img" --quiet
  wait_all

  "$HOME/.config/hypr/scripts/waybar/reload-css.sh" 2>>"$LOG" ||
    log "waybar/reload-css failed rc=$?"
  # ghostty: theme は window 起動時にしか読まれないため SIGUSR2 で reload_config を要求
  pkill -x -SIGUSR2 ghostty 2>>"$LOG" &&
    log "ghostty SIGUSR2 sent" ||
    log "ghostty SIGUSR2 failed rc=$? (no running ghostty?)"
  # Hyprland の $variable は parse 時に値置換されるため新色の伝播に全 reload が必要
  hyprctl reload 2>>"$LOG" || log "hyprctl reload failed rc=$?"

  # 失敗時は記録しない → 次の呼び出しが色生成を再試行できる
  if ((PIPELINE_OK)); then
    echo "$img" >"$LAST_COLORED"
  fi
fi

# --- 8. 記録 ---------------------------------------------------------------
echo "$img" >"$LAST"
log "=== complete last_wallpaper=$img"
