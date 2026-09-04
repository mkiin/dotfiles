{ pkgs, ... }:
let
  dwproton = pkgs.callPackage ./dwproton { };
in
{
  home.packages = with pkgs; [
    matugen
    wallust
    awww
    rclone
    imagemagick
    wlogout
    rofi
    socat
    resvg
    mpv
    pwvucontrol
    audacity
    cava
    playerctl
    quickshell
    pyprland
    wezterm
    hyprlock
    wl-clipboard
    brightnessctl
    pamixer
    grim
    slurp
    jq
    libnotify
    satty
    gthumb
    imv
    obsidian
    umu-launcher
    (pkgs.writeShellScriptBin "nikke" ''
      export NIKKE_PROTON=${dwproton}
      export PROTON_NO_FSYNC=1
      export PROTON_NO_ESYNC=1
      ${builtins.readFile ./nikke/nikke.sh}
    '')
  ];
}
