{ pkgs, ... }:

{
  home.packages = with pkgs; [
    unzip
    zip
  ];

  programs.zsh.shellAliases = {
    open = "explorer.exe .";
  };
}
