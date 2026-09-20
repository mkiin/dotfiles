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

  system.stateVersion = "26.05";
}
