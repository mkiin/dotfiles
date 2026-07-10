{ inputs, pkgs, ... }:
{
  home.packages = with pkgs; [
    # color / wallpaper pipeline
    matugen
    wallust
    awww
    rclone
    # desktop utilities (waybar=programs.waybar, cliphist/hypridle=services)
    wlogout
    socat
    resvg
    mpv
    pwvucontrol
    cava
    playerctl
    # shell / panel (qs + quickshell on PATH for keybinds and matugen post_hook)
    quickshell
    pyprland
    # terminals
    wezterm
    # session essentials (lock, screenshot, clipboard, media keys)
    hyprlock
    wl-clipboard
    brightnessctl
    pamixer
    # script dependencies (screenshot.sh, record.sh)
    grim
    slurp
    jq
    libnotify
    # anime-games-launcher (NIKKE 等)。NixOS 非対応の AGL 同梱 umu-run は壊れるため
    # NixOS 対応の umu-launcher(-bwrap 版)を PATH に置き nikke.sh に掴ませる
    inputs.anime-games-launcher.packages.${pkgs.system}.default
    umu-launcher
    # NIKKE 起動ラッパー(scripts/nikke.sh)を `nikke` として PATH に載せる。
    # Hyprland keybind(SHIFT+N)や端末から叩くため。store へ焼くので反映は switch。
    (pkgs.writeShellScriptBin "nikke" (builtins.readFile "${inputs.self}/scripts/nikke.sh"))
  ];
}
