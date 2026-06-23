{ pkgs, ... }:

{
  home.packages = [ pkgs.zsh ];

  home.file = {
    ".zshrc".source = ../../zsh/zshrc;
    ".zshenv".source = ../../zsh/zshenv;
  };
}
