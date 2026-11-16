# Resolve the active Hyprland window to a readable screenshot directory.
def matching-value [content: string, key: string] : nothing -> string {
  let pattern = $'(?m)^\s*"($key)"\s+"(?<value>[^"]*)"'
  let match = ($content | parse --regex $pattern | get -o 0.value)
  $match | default ""
}

def steam-app-id [window: record] : nothing -> string {
  let class = ($window | get -o class | default "")
  if $class =~ '^steam_app_[0-9]+$' {
    return ($class | str replace 'steam_app_' '')
  }

  mut pid = ($window | get -o pid | default 0)
  for _ in 0..11 {
    if $pid <= 1 { break }
    let environment_path = $"/proc/($pid)/environ"
    if ($environment_path | path exists) {
      let values = (try { open --raw $environment_path | decode utf-8 | split row (char nul) } catch { [] })
      for value in $values {
        if $value =~ '^(SteamAppId|SteamGameId)=[0-9]+$' {
          return ($value | split row '=' | get 1)
        }
      }
    }

    let status_path = $"/proc/($pid)/status"
    if not ($status_path | path exists) { break }
    let parent = (try {
      open --raw $status_path
        | lines
        | parse --regex '^PPid:\s+(?<pid>[0-9]+)$'
        | get -o 0.pid
    } catch { null })
    if $parent == null { break }
    $pid = ($parent | into int)
  }
  ""
}

def steam-name [app_id: string] : nothing -> string {
  if $app_id == "" { return "" }
  let data_home = ($env | get -o XDG_DATA_HOME | default $"($env.HOME)/.local/share")
  let roots = [
    $"($env.HOME)/.local/share/Steam"
    $"($env.HOME)/.steam/steam"
    $"($env.HOME)/.steam/root"
    $"($data_home)/Steam"
  ] | uniq
  mut libraries = $roots
  for root in $roots {
    let config = ($root | path join steamapps libraryfolders.vdf)
    if not ($config | path exists) { continue }
    let entries = (try {
      open --raw $config | parse --regex '"path"\s*"(?<path>[^"]+)"' | get path
    } catch { [] })
    $libraries = ($libraries | append $entries)
  }
  for library in ($libraries | uniq) {
    let manifest = ($library | path join steamapps $"appmanifest_($app_id).acf")
    if not ($manifest | path exists) { continue }
    let name = (try { matching-value (open --raw $manifest) "name" } catch { "" })
    if $name != "" { return $name }
  }
  ""
}

def desktop-entry [file: string] : nothing -> record {
  mut active = false
  mut name = ""
  mut wm_class = ""
  mut kind = "Application"
  for line in (open --raw $file | lines) {
    let item = ($line | str trim)
    if $item == "[Desktop Entry]" {
      $active = true
      continue
    }
    if ($item | str starts-with "[") {
      $active = false
      continue
    }
    if not $active { continue }
    if ($item | str starts-with "Name=") {
      $name = ($item | str substring 5..)
    } else if ($item | str starts-with "StartupWMClass=") {
      $wm_class = ($item | str substring 15..)
    } else if ($item | str starts-with "Type=") {
      $kind = ($item | str substring 5..)
    }
  }
  { name: $name, wm_class: $wm_class, kind: $kind }
}

def desktop-name [class: string] : nothing -> string {
  if $class == "" { return "" }
  let data_home = ($env | get -o XDG_DATA_HOME | default $"($env.HOME)/.local/share")
  let data_dirs = ($env | get -o XDG_DATA_DIRS | default "/usr/local/share:/usr/share")
  let roots = ([$data_home] | append ($data_dirs | split row ":") | where { $in != "" } | uniq)
  mut fallback = ""
  for root in $roots {
    let directory = ($root | path join applications)
    if not ($directory | path exists) { continue }
    for file in (glob --no-dir $"($directory)/**/*.desktop") {
      let entry = (try { desktop-entry $file } catch { {name: "", wm_class: "", kind: ""} })
      if $entry.kind != "Application" or $entry.name == "" { continue }
      let desktop_id = ($file | path relative-to $directory | str replace --all "/" "-" | str replace --regex '\.desktop$' '')
      if ($desktop_id | str downcase) == ($class | str downcase) {
        return $entry.name
      }
      if $fallback == "" and ($entry.wm_class | str downcase) == ($class | str downcase) {
        $fallback = $entry.name
      }
    }
  }
  $fallback
}

def safe-name [name: string] : nothing -> string {
  let cleaned = ($name | str replace --all --regex '[/\\\x00-\x1f\x7f]' "_" | str trim | str trim --char "." | str trim)
  if $cleaned == "" { return "unknown" }
  # Keep the directory component under the Linux 255-byte limit.
  mut result = ($cleaned | str substring --grapheme-clusters 0..<180)
  while ($result | str length) > 200 {
    $result = ($result | str substring --grapheme-clusters 0..-2)
  }
  if $result == "" { "unknown" } else { $result }
}

def main [] {
  let response = (^hyprctl -j activewindow | complete)
  if $response.exit_code != 0 {
    error make { msg: $"hyprctl failed: ($response.stderr)" }
  }
  let window = ($response.stdout | from json --strict)
  let address = ($window | get -o address | default "")
  if $address == "" or $address == "0x0" { return }

  let class = ($window | get -o class | default "")
  let app_id = (steam-app-id $window)
  mut name = (steam-name $app_id)
  if $name == "" { $name = (desktop-name $class) }
  if $name == "" {
    $name = ($class | split row "." | last)
  }
  let destination = ($env.HOME | path join Pictures Screenshots (safe-name $name))
  ^noctalia msg screenshot-window --save-to-file --directory $destination
}
