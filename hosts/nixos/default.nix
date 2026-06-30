{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ../../nixos
    inputs.nixos-hardware.nixosModules.common-cpu-amd
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    inputs.disko.nixosModules.disko
  ];

  home-manager.users.mkiin.imports = [
    ../../home-manager
    ../../home-manager/desktop
  ];

  system.stateVersion = "26.05";
}
