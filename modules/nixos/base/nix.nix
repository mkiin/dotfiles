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

    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://noctalia.cachix.org"
      "https://mkiin-dotfiles.cachix.org"
      "https://ezkea.cachix.org"
      "https://cache.numtide.com"
    ];

    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      "mkiin-dotfiles.cachix.org-1:LJ6X3uYDglOyphSEDcaz/wrwGDmetitbmrUDkwvUzjM="
      "ezkea.cachix.org-1:ioBmUbJTZIKsHmWWXPe1FSFbeVe+afhfgqgTSNd34eI="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
    builders-use-substitutes = true;
  };

  nix.extraOptions = ''
    !include ${config.age.secrets.nix-access-tokens.path}
  '';
}
