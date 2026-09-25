#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper-apply"
# Keep these paths aligned with the targets in wallust.toml.
declare -A theme_files=(
  [ghostty]="$HOME/.config/ghostty/themes/wallust"
  [waybar]="$HOME/.config/waybar/colors.css"
)
# Nix wrappers may change comm to .ghostty-... (truncated to 15 bytes).
# pkill -x matches the entire process name against these regular expressions.
declare -A process_patterns=(
  [ghostty]='\.?ghostty(-.*)?'
  [waybar]='waybar'
)

save_theme() {
  local target="$1" previous="$2"
  if [[ -f $target ]]; then
    cp "$target" "$previous"
  fi
}

reload_if_changed() {
  local target="$1" previous="$2" process="$3" status

  if [[ ! -f $target ]]; then
    echo "Error: wallust did not generate $target" >&2
    return 1
  fi

  if [[ -f $previous ]] && cmp -s "$previous" "$target"; then
    return 0
  fi

  # Ghostty and Waybar both reload on SIGUSR2.
  # Exit status 1 means the application is not running.
  pkill -SIGUSR2 -u "$(id -u)" -x "$process" || {
    status=$?
    [[ $status == 1 ]] || return "$status"
  }
}

mkdir -p "$state_dir"
exec 9>"$state_dir/apply.lock"
flock -x 9

# Serialize generation too: started and wallpaper_changed may run together.
snapshot_dir="$(mktemp -d "$state_dir/themes.XXXXXX")"
trap 'rm -rf "$snapshot_dir"' EXIT
for app in "${!theme_files[@]}"; do
  save_theme "${theme_files[$app]}" "$snapshot_dir/$app"
done

"$config_dir/wallust/scripts/run-wallust.sh"

for app in "${!theme_files[@]}"; do
  reload_if_changed "${theme_files[$app]}" "$snapshot_dir/$app" "${process_patterns[$app]}"
done
