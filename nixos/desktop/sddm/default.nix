{ lib, pkgs, ... }:
let
  theme = pkgs.sddm-astronaut.override { embeddedTheme = "black_hole"; };

  westonIni = pkgs.writeText "weston.ini" ''
    [keyboard]
    keymap_layout=us

    [output]
    name=DP-1
    mode=off

    [output]
    name=DP-3
    mode=off

    [output]
    name=HDMI-A-1
    mode=off
  '';
in
{
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    wayland.compositorCommand = "${lib.getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
    package = pkgs.kdePackages.sddm;
    theme = "sddm-astronaut-theme";
    extraPackages = [ theme ];

    settings = {
      Theme = {
        CursorTheme = "Bibata-Modern-Classic";
        CursorSize = 24;
      };
      # greeter の env は sddm が空から組み立てるため PAM の XCURSOR_PATH が届かない
      General.GreeterEnvironment = "XCURSOR_PATH=/run/current-system/sw/share/icons";
    };
  };

  environment.systemPackages = [
    theme
    pkgs.bibata-cursors
  ];

  fonts.packages = [ theme ];
}
