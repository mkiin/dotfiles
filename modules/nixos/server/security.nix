{ lib, myvars, ... }:
{
  # Remote deployment connects as root using the desktop's SSH key.
  users.users.root.openssh.authorizedKeys.keys = myvars.mainSshAuthorizedKeys;

  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Nix trusted users have root-equivalent access, bypassing the sudo boundary.
  nix.settings.trusted-users = lib.mkForce [ "root" ];
}
