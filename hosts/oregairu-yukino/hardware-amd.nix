{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  boot.kernelModules = [ "k10temp" ];

  environment.systemPackages = [
    pkgs.lm_sensors
  ];
}
