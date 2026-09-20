# modules/nixos/desktop/hyprland.nix
{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  hyprlandPackages = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  config = lib.mkIf config.programs.hyprland.enable {
    programs.hyprland = {
      package = hyprlandPackages.hyprland;
      portalPackage = hyprlandPackages.xdg-desktop-portal-hyprland;
      withUWSM = true;
    };
  };
}
