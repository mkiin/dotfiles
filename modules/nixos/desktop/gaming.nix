{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.modules.desktop.gaming;
in
{
  options.modules.desktop.gaming.enable = lib.mkEnableOption "Install Game Suite";

  imports = [
    inputs.aagl.nixosModules.default
  ];

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      protontricks.enable = true;
      extest.enable = true;
    };
    programs.gamemode.enable = true;
    programs.sleepy-launcher.enable = true;
  };
}
