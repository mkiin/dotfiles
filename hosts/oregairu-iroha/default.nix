{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "oregairu-iroha";
  networking.networkmanager.enable = true;

  # Wake yukino's wired NIC (enp10s0) from this LAN: wakeonlan 9c:6b:00:98:be:bc
  environment.systemPackages = [ pkgs.wakeonlan ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Use wired networking; the unused Wi-Fi adapter repeatedly fails H2C commands.
  boot.blacklistedKernelModules = [ "rtw88_8821ce" ];
  hardware.enableRedistributableFirmware = true;

  console.keyMap = "us";
  system.stateVersion = "26.11";
}
