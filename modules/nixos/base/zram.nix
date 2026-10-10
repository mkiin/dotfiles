{ config, lib, ... }:
{
  options.modules.zram.enable = lib.mkEnableOption "compressed zram swap device";

  config = lib.mkIf config.modules.zram.enable {
    zramSwap.enable = true;
    zramSwap.memoryPercent = lib.mkDefault 50;
  };
}
