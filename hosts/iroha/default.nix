{ myvars, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "iroha";
  networking.networkmanager.enable = true;

  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.tailb6cf85.ts.net";
  };

  services.vaultwarden = {
    enable = true;
    host = "iroha";
    domain = "vaultwarden.tailb6cf85.ts.net";
  };

  services.tailscale.serve = {
    enable = true;
    services.nextcloud.endpoints."tcp:443" = "http://127.0.0.1:8080";
    services.vaultwarden.endpoints."tcp:443" = "http://127.0.0.1:8222";
  };

  users.users.${myvars.username}.openssh.authorizedKeys.keys = [
    myvars.sshPublicKeys.iphone13-termius
  ];

  # Wake yukino's wired NIC (enp10s0) from this LAN: wakeonlan 9c:6b:00:98:be:bc
  modules.wakeonlan.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Use wired networking; the unused Wi-Fi adapter repeatedly fails H2C commands.
  boot.blacklistedKernelModules = [ "rtw88_8821ce" ];
  hardware.enableRedistributableFirmware = true;

  console.keyMap = "us";
  system.stateVersion = "26.11";
}
