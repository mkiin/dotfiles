{ config, lib, ... }:
{
  services.kanshi = lib.mkIf config.modules.desktop.niri.enable {
    enable = true;
    systemdTarget = "niri.service";
  };
}
