_: {
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.trusted-users = [
    "root"
    "mkiin"
  ];
  nix.settings.accept-flake-config = true;
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };
}
