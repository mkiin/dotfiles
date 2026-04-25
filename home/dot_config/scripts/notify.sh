# Shared notification helper. Source this file then call `notify`.
#
# Usage:
#   source ~/.config/scripts/notify.sh
#   notify [--app NAME] [--icon ICON] [--urgency low|normal|critical] \
#          <summary> [body]
#
# Defaults:
#   app=dotfiles  icon=dialog-information  urgency=normal
#
# 例:
#   notify --app "wallset" --icon "preferences-desktop-wallpaper" \
#          "Wallpaper changed" "$(basename "$img")"
#   notify --urgency critical "Build failed" "$err_summary"
#
# 設計メモ:
#   - 実行可能ビットは付けない (sourceable library として扱う)。
#   - --app / --icon / --urgency 以外のフラグは notify-send に直接渡せないので必要なら
#     呼び出し元で `notify-send` を直叩きする。本ヘルパーは常用 3 軸に絞った最小 API。

notify() {
    local app="dotfiles"
    local icon="dialog-information"
    local urgency="normal"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --app)     app="$2"; shift 2 ;;
            --icon)    icon="$2"; shift 2 ;;
            --urgency) urgency="$2"; shift 2 ;;
            --) shift; break ;;
            -*) echo "notify: unknown option: $1" >&2; return 1 ;;
            *) break ;;
        esac
    done

    local summary="${1:?notify: <summary> is required}"
    local body="${2:-}"

    notify-send -a "$app" -i "$icon" -u "$urgency" "$summary" "$body"
}
