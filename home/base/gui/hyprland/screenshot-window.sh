#!/usr/bin/env bash
set -euo pipefail
window=$(hyprctl -j activewindow)
class=$(jq -r '.class // ""' <<< "$window")
pid=$(jq -r '.pid // 0' <<< "$window")
address=$(jq -r '.address // ""' <<< "$window")
[[ -n $address && $address != 0x0 ]] || exit 0
app_id=''
if [[ $class =~ ^steam_app_([0-9]+)$ ]]; then
  app_id=${BASH_REMATCH[1]}
else
  for ((i=0; i<12 && pid>1; i++)); do
    if [[ -r /proc/$pid/environ ]]; then
      while IFS= read -r variable; do
        if [[ $variable =~ ^(SteamAppId|SteamGameId)=([0-9]+)$ ]]; then
          app_id=${BASH_REMATCH[2]}
          break
        fi
      done < <(tr '\0' '\n' < "/proc/$pid/environ")
    fi
    [[ -z $app_id ]] || break
    [[ -r /proc/$pid/status ]] || break
    pid=$(awk '$1=="PPid:" {print $2; exit}' "/proc/$pid/status")
    [[ $pid =~ ^[0-9]+$ ]] || break
  done
fi

name=''
if [[ -n $app_id ]]; then
  roots=("$HOME/.local/share/Steam" "$HOME/.steam/steam" "$HOME/.steam/root" "${XDG_DATA_HOME:-$HOME/.local/share}/Steam")
  libraries=("${roots[@]}")
  for root in "${roots[@]}"; do
    [[ -r $root/steamapps/libraryfolders.vdf ]] || continue
    while IFS= read -r path; do
      [[ -n $path ]] && libraries+=("$path")
    done < <(awk -F '"' '$2=="path" {print $4}' "$root/steamapps/libraryfolders.vdf")
  done
  for library in "${libraries[@]}"; do
    manifest="$library/steamapps/appmanifest_$app_id.acf"
    [[ -r $manifest ]] || continue
    name=$(awk -F '"' '$2=="name" {print $4; exit}' "$manifest")
    [[ -z $name ]] || break
  done
fi

if [[ -z $name && -n $class ]]; then
  IFS=: read -r -a data_roots <<< "${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  fallback=''
  for root in "${data_roots[@]}"; do
    directory="$root/applications"
    [[ -d $directory ]] || continue
    while IFS= read -r -d '' file; do
      desktop_id=${file#"$directory/"}
      desktop_id=${desktop_id//\//-}
      desktop_id=${desktop_id%.desktop}
      entry=$(awk '
        /^\[Desktop Entry\]$/ {active=1; next}
        /^\[/ {active=0}
        active && /^Name=/ && !name {name=substr($0,6)}
        active && /^StartupWMClass=/ {wm=substr($0,16)}
        END {printf "%s\n%s\n", name, wm}
      ' "$file")
      display_name=${entry%%$'\n'*}
      wm_class=${entry#*$'\n'}
      [[ -n $display_name ]] || continue
      if [[ ${desktop_id,,} == ${class,,} ]]; then
        name=$display_name
        break 2
      fi
      if [[ -z $fallback && ${wm_class,,} == ${class,,} ]]; then
        fallback=$display_name
      fi
    done < <(find "$directory" -type f -name '*.desktop' -print0)
  done
  [[ -n $name ]] || name=$fallback
fi

[[ -n $name ]] || name=${class##*.}
[[ -n $name ]] || name=unknown
name=$(printf '%s' "$name" | tr '/\\\000-\037\177' '___' | sed -e 's/^[[:space:].]*//' -e 's/[[:space:].]*$//')
[[ -n $name ]] || name=unknown
name=$(printf '%s' "$name" | awk '{print substr($0,1,200)}')
[[ -n $name ]] || name=unknown
exec noctalia msg screenshot-window --save-to-file --directory "$HOME/Pictures/Screenshots/$name"
