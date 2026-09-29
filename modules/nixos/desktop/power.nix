{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.desktop.power;
in
{
  options.modules.desktop.power = {
    zswap = {
      enable = lib.mkEnableOption "compressed zswap cache in front of disk-backed swap";
      swappiness = lib.mkOption {
        type = lib.types.ints.between 0 200;
        default = 100;
        description = "Kernel swappiness used when zswap is enabled.";
      };
    };

    zramSwap.enable = lib.mkEnableOption "compressed zram swap device";

    suspend.async = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Run device suspend and resume callbacks asynchronously.";
    };
  };

  config = {
    # Keep frequently used anonymous pages compressed in RAM, while retaining
    # the disk-backed swap device required to store a hibernation image.
    boot.zswap.enable = cfg.zswap.enable;
    boot.kernel.sysctl = lib.mkIf cfg.zswap.enable {
      "vm.swappiness" = cfg.zswap.swappiness;
    };

    # zram cannot be used as a hibernation resume device. Hosts that hibernate
    # provide a disk-backed swap device through swapDevices instead.
    zramSwap.enable = cfg.zramSwap.enable;

    boot.kernelParams = lib.optional (!cfg.suspend.async) "pm_async=off";

    services.tuned = {
      enable = true;
      settings.dynamic_tuning = true;
      ppdSupport = true; # translation of power-profiles-daemon API calls to TuneD
      ppdSettings.main.default = "balanced"; # balanced / performance / power-saver
    };

    services.upower.enable = true;

    services.power-profiles-daemon.enable = false;
    services.tlp.enable = false;
  };
}
