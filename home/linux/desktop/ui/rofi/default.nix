{ pkgs, ... }:

let
  rofiLauncher = pkgs.writeShellApplication {
    name = "rofi-launcher";

    runtimeInputs = with pkgs; [
      rofi
      awww
      gnused
      procps
      coreutils
    ];

    text = builtins.readFile scripts/launch.sh;
  };
in
{
  home.packages = [
    pkgs.rofi
    rofiLauncher
  ];

  xdg.configFile = {
    "rofi/config.rasi".source = ./config.rasi;
    "rofi/themes".source = ./themes;
  };
}
