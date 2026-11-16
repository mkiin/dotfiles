def main [--print-directory] {
    let response = (^hyprctl -j activewindow | complete)
    if $response.exit_code != 0 {
        error make {msg: $"hyprctl failed: ($response.stderr)"}
    }
    let window = ($response.stdout | from json --strict)
    let address = ($window | get --optional address | default "")
    if $address == "" or $address == "0x0" { return }

    let resolved = (^screenshot-app-name ($window | to json --raw) | complete)
    if $resolved.exit_code != 0 {
        error make {msg: $"App name resolution failed: ($resolved.stderr)"}
    }
    if $resolved.stderr != "" { print --stderr $resolved.stderr }
    let directory = ($env.HOME | path join Pictures Screenshots ($resolved.stdout | str trim))
    if $print_directory {
        print $directory
    } else {
        ^noctalia msg screenshot-window --save-to-file --directory $directory
        exit $env.LAST_EXIT_CODE
    }
}
