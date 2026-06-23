{ ... }:

{
  imports = [ ./home/common.nix ];

  home.username = "mkiin";
  home.homeDirectory = "/home/mkiin";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
