{
  config,
  myvars,
  lib,
  ...
}:
{
  nixpkgs.config.allowUnfree = lib.mkForce true;

  nix.gc = {
    automatic = lib.mkDefault true;
    dates = lib.mkDefault "weekly";
    options = lib.mkDefault "--delete-older-than 7d";
  };

  nix.channel.enable = false;

  nix.settings = {
    auto-optimise-store = true;

    experimental-features = [
      "nix-command"
      "flakes"
    ];

    trusted-users = [ myvars.username ];

    substituters = [
    ];

    trusted-public-keys = [
    ];
    builders-use-substitutes = true;
  };

  nix.extraOptions = ''
    !include ${config.age.secrets.nix-access-tokens.path}
  '';
}
