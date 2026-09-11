{ config, ... }:
{
  boot.blacklistedKernelModules = [ "amdgpu" ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = true;
  };
}
