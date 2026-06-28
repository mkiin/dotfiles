{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  system.stateVersion = "26.05";
}
