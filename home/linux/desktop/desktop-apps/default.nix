{ pkgs, mylib, ... }:
{
  imports = mylib.scanPaths ./.;
  home.packages = with pkgs; [
    limo # mod manager
  ];

  programs.vesktop = {
    enable = true;

    settings = {
      tray = true;
      minimizeToTray = true;
      hardwareAcceleration = true;
      arRPC = true;
    };
  };
}
