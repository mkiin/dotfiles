{ config, lib, ... }:
let
  # TODO: set this to the IPv4 subnet on iroha's wired LAN to allow client access.
  lanIPv4Subnet = null;
in
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "oregairu-iroha";
  networking.networkmanager.enable = true;
  networking.nftables.enable = true;
  networking.firewall.extraInputRules = lib.optionalString (lanIPv4Subnet != null) ''
    ip saddr ${lanIPv4Subnet} tcp dport 443 accept
    ip saddr ${lanIPv4Subnet} udp dport 5353 accept
  '';

  services.avahi = {
    enable = true;
    openFirewall = false;
    settings = {
      server.use-ipv6 = false;
      publish = {
        disable-publishing = false;
        publish-addresses = true;
      };
    };
  };

  services.nextcloud = {
    enable = true;
    hostName = "${config.networking.hostName}.local";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Use wired networking; the unused Wi-Fi adapter repeatedly fails H2C commands.
  boot.blacklistedKernelModules = [ "rtw88_8821ce" ];
  hardware.enableRedistributableFirmware = true;

  console.keyMap = "us";
  system.stateVersion = "26.11";
}
