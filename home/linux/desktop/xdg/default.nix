{ config, pkgs, ... }:

{
  imports = [
    ./mime.nix
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

    autostart = {
      enable = true;
      entries = [ ];
    };
  };

  home.packages = [
    pkgs.xdg-utils
  ];

  home.sessionVariables = {
    BROWSER = "zen-beta";
    FILE_MANAGER = "nautilus";
  };
}
