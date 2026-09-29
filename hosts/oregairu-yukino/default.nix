{ ... }:
#############################################################
#
#  Yukino - my main computer, with NixOS + Ryzen7 7800x3D + RTX 5070ti GPU, for gaming & daily use.
#
#############################################################
{
  imports = [
    ./hardware-configuration.nix
    ./hardware-amd.nix
    ./hardware-nvidia.nix
  ];

  modules.desktop.power = {
    zswap.enable = true;
    zramSwap.enable = false;
    suspend.async = false;
  };

  # This machine resumes reliably through modern standby, while S3/deep is
  # intermittent. Keep the sleep-mode choice local to this host.
  boot.kernelParams = [ "mem_sleep_default=s2idle" ];

  system.stateVersion = "26.05";
}
