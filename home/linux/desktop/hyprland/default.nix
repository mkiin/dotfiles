{ lib, config }:
let
  cfg = config.modules.desktop.hyprland;
in
{

  options.modules.desktop.hyprland = {
    enable = lib.mkEnableOption "hyprland compositor";
  };

  config = lib.mkIf cfg.enable {

  };
}
