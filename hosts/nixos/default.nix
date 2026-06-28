{ username, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  system.stateVersion = "26.05";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  users.users.${username} = {
    isNormalUser = true;
    group = username;
  };
  users.groups.${username} = { };
}
