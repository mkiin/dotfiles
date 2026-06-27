{ inputs, ... }:

{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./agent-skills.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./packages.nix
    ./programs/zsh.nix
    ./programs/git.nix
    ./programs/mise.nix
    ./programs/lazygit.nix
    ./programs/starship.nix
    ./programs/sheldon.nix
    ./programs/neovim.nix
    ./programs/yazi.nix
    ./programs/goclipboard.nix
    ./programs/python.nix
  ];

  programs.home-manager.enable = true;

  news.display = "silent";
}
