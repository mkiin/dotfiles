{ config, lib, ... }:
{
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.graphics.enable = true;
  boot.initrd.kernelModules = [ "amdgpu" ];
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";
}
