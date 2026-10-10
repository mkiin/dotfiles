{ config, lib, ... }:
{
  options.modules.zswap.enable = lib.mkEnableOption "compressed zswap cache in front of disk-backed swap";

  config = lib.mkIf config.modules.zswap.enable {
    boot.zswap.enable = true;
    boot.kernel.sysctl."vm.swappiness" = lib.mkDefault 100;
  };
}
