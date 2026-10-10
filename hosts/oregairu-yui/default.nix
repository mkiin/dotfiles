#############################################################
#
#  Yui - my laptop computer, with NixOS + Ryzen5 3500U.
#
#############################################################
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./hardware-amd.nix
  ];

  _module.args.hostVars.primaryOutput = null;

  networking.hostName = "oregairu-yui";

  services.openssh.settings = {
    PermitRootLogin = "no";
    KbdInteractiveAuthentication = false;
  };

  system.stateVersion = "26.05";
}
