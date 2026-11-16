{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "oregairu-iroha";
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.enableRedistributableFirmware = true;

  console.keyMap = "jp106";
  system.stateVersion = "26.11";
}
