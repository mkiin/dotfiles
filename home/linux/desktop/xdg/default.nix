{ config, pkgs, ... }:

{
  imports = [
    ./mime.nix
    ./autostart.nix
  ];

  xdg = {
    enable = true;

    userDirs = {
      enable = true;
      createDirectories = true;

      extraConfig = {
        SCREENSHOTS = "${config.xdg.userDirs.pictures}/Screenshots";
      };
    };
  };

  home.packages = [
    pkgs.xdg-utils
  ];
}
