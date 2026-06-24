{ ... }:

{
  imports = [
    ./packages.nix
    ./programs/zsh
    ./programs/git.nix
    ./programs/mise.nix
    ./programs/lazygit.nix
    ./programs/starship.nix
    ./programs/sheldon.nix
    ./programs/neovim.nix
    ./programs/yazi.nix
  ];

  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
