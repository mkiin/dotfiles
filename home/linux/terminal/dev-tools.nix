{ pkgs, ... }:
{
  # linux only packages
  home.packages = with pkgs; [
    bubblewrap # require codex sand box
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;

      enableZshIntegration = true;
      enableBashIntegration = true;
      enableNushellIntegration = true;
    };
  };
}
