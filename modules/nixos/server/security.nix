{ lib, ... }:
{
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Nix trusted users have root-equivalent access, bypassing the sudo boundary.
  nix.settings.trusted-users = lib.mkForce [ "root" ];
}
