{ pkgs, ... }:
{
  security.polkit.enable = true;
  environment.systemPackages = [ pkgs.kdePackages.polkit-kde-agent-1 ];
  security.pam.services.hyprlock = { };
}
