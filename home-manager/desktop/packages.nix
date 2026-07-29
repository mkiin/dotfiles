{ inputs, pkgs, ... }:
let
  dwproton = pkgs.callPackage ./nikke { };
in
{
  home.packages = with pkgs; [
    # color / wallpaper pipeline
    matugen
    wallust
    awww
    rclone
    imagemagick
    # desktop utilities (waybar=programs.waybar, cliphist/hypridle=services)
    wlogout
    rofi
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
    # スクショ注釈/トリミング。撮影後 grim からパイプ、既存画像は --filename で開ける
    satty
    # アスペクト比固定クロップ(9:16 等)。satty はフリーフォームのみで比率ロック不可
    gthumb
    # 画像ビューア。yazi の opener から enter で開く(Wayland native, キー操作)
    imv
    obsidian
    # NIKKE ランナー。umu-launcher(-bwrap 版)を PATH に置き nikke.sh に掴ませる。
    # dwproton は nix store から NIKKE_PROTON でラッパーに渡す(AGL 非依存)。
    umu-launcher
    # NIKKE 起動ラッパー(scripts/nikke.sh)を `nikke` として PATH に載せる。
    # Hyprland keybind(SHIFT+N)や端末から叩くため。store へ焼くので反映は switch。
    (pkgs.writeShellScriptBin "nikke" ''
      export NIKKE_PROTON=${dwproton}
      ${builtins.readFile "${inputs.self}/scripts/nikke.sh"}
    '')
  ];
}
