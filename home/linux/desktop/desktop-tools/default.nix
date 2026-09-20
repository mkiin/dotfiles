# tools/screenshot/default.nix
{
  inputs,
  pkgs,
  ...
}:

let
  screenshotMenu = pkgs.writeShellApplication {
    name = "screenshot-menu";

    runtimeInputs = with pkgs; [
      rofi
      inputs.hyprcap.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    text = builtins.readFile scripts/screenshot-menu.sh;
  };

  recordMenu = pkgs.writeShellApplication {
    name = "record-menu";

    runtimeInputs = with pkgs; [
      rofi
      inputs.hyprcap.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    text = builtins.readFile scripts/record-menu.sh;
  };

  wallpaperApply = pkgs.writeShellApplication {
    name = "wallpaper-apply";
    runtimeInputs = with pkgs; [
      awww
      hyprland # hyprctl
      jq
      matugen
      wallust
      procps # pkill
      coreutils # date, sleep, mktemp, ln
      gnused # sed
      util-linux # flock
    ];
    text = builtins.readFile scripts/apply.sh;
  };

in
{
  imports = [
    ./hypridle.nix
    ./pyprland.nix
  ];

  _module.args = {
    inherit wallpaperApply;
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # for any ozone-based browser & electron apps to run on wayland
    MOZ_ENABLE_WAYLAND = "1"; # for firefox to run on wayland
    MOZ_WEBRENDER = "1";
    # enable native Wayland support for most Electron apps
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    # misc
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_QPA_PLATFORM = "wayland;xcb";
    # QT_QPA_PLATFORMTHEME = "qt6ct";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    SDL_VIDEODRIVER = "wayland";
    GDK_BACKEND = "wayland";
    XDG_SESSION_TYPE = "wayland";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  home.packages = with pkgs; [
    screenshotMenu
    recordMenu
    wallpaperApply

    wl-clipboard
    wf-recorder
    libnotify
    grim
    slurp
  ];

  programs.satty.enable = true;

  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  services.wl-clip-persist.enable = true;

}
