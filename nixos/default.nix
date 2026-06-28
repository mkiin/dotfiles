{ ... }:
{
  imports = [
    ./core/boot.nix
    ./core/nix.nix
    ./core/users.nix
    ./core/locale.nix
    ./core/time.nix
    ./core/network.nix
    ./core/nix-ld.nix
    ./core/fonts.nix
    ./hardware
    ./desktop
    ./apps
  ];
}
