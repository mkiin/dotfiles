{ config, lib, ... }:
let
  cfg = config.modules.desktop.gaming;
in
{
  options.modules.desktop.gaming.enable = lib.mkEnableOption "Install Game Suite";

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      protontricks = true;
      extest.enable = true;
    };
    programs.gamemode.enable = true;
  };
}
