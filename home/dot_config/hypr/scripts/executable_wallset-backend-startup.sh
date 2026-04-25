#!/usr/bin/env bash
# 起動時の壁紙適用 entry point。Hyprland の exec-once から呼ばれる想定。
#
# 動作:
#   - awww-daemon を起動 (既起動なら no-op)
#   - WALLSET_RANDOM_ON_STARTUP の値に応じて分岐
#     * true:  ランダム壁紙を選択 → wallset-backend に委譲して全テーマ適用
#     * false: 前回壁紙を per-monitor cache から restore (色再生成は走らせない)
#
# 設定:
#   現状 WALLSET_RANDOM_ON_STARTUP は本ファイル冒頭の変数で固定。
#   将来的に settings UI から ON/OFF できるようにする予定 (該当時は環境変数か
#   設定ファイル経由に差し替え)。

set -euo pipefail

# === 設定 ===
WALLSET_RANDOM_ON_STARTUP=true   # true: 起動時ランダム / false: 前回壁紙を restore

# === パス ===
WALLPAPER_DIR="${HOME}/pictures/wallpaper"
LAST_FILE="${HOME}/.cache/last_wallpaper"
FALLBACK="${WALLPAPER_DIR}/1297749.jpg"
BACKEND="${HOME}/.config/hypr/scripts/wallset-backend.sh"

# === awww-daemon を起動 (既存判定は `awww query` の可否で行う) ===
if ! awww query >/dev/null 2>&1; then
    awww-daemon >/dev/null 2>&1 &
    disown
    # socket 作成まで最大 5 秒待機
    for _ in $(seq 1 50); do
        awww query >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

if [[ "$WALLSET_RANDOM_ON_STARTUP" == "true" ]]; then
    # === ランダム選択経路 ===
    # ~/pictures/wallpaper 直下の画像をリストアップし、直前と被らないものを選ぶ。
    mapfile -t FILES < <(fd --max-depth 1 --type f -e jpg -e jpeg -e png -e webp . "$WALLPAPER_DIR" 2>/dev/null | sort)

    if [[ ${#FILES[@]} -eq 0 ]]; then
        echo "[wallset-backend-startup] no images in $WALLPAPER_DIR" >&2
        exit 1
    fi

    LAST=""
    [[ -f "$LAST_FILE" ]] && LAST=$(<"$LAST_FILE")

    if [[ ${#FILES[@]} -eq 1 ]]; then
        # 1 枚しかなければ重複避けロジックを skip
        PICK="${FILES[0]}"
    else
        while :; do
            PICK="${FILES[RANDOM % ${#FILES[@]}]}"
            [[ "$PICK" != "$LAST" ]] && break
        done
    fi

    echo "$PICK" > "$LAST_FILE"

    # backend に委譲 (色生成 + テーマ適用パイプラインを全部実行)
    exec "$BACKEND" "$PICK"
else
    # === restore 経路 (前回壁紙、色再生成は走らせず軽量復帰) ===
    if ! awww restore 2>/dev/null; then
        if [[ -f "$FALLBACK" ]]; then
            awww img --transition-type none "$FALLBACK"
        else
            echo "[wallset-backend-startup] no restore cache and fallback missing: $FALLBACK" >&2
            exit 1
        fi
    fi
fi
