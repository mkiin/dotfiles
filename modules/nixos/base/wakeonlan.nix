{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.modules.wakeonlan.enable = lib.mkEnableOption "Wake-on-LAN sender";

  config = lib.mkIf config.modules.wakeonlan.enable {
    environment.systemPackages = [ pkgs.wakeonlan ];
  };
}
