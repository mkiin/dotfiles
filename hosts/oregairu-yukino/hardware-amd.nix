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
  boot.blacklistedKernelModules = [ "amdgpu" ];

  environment.systemPackages = [
    pkgs.lm_sensors
  ];
}
