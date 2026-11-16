{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.kernelModules = [ "k10temp" ];

  environment.systemPackages = [
    pkgs.lm_sensors
  ];
}
