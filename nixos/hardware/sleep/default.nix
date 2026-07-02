{ config, ... }:
{
  boot.resumeDevice = (builtins.head config.swapDevices).device;
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];
}
