{ nixRoot, ... }:

{
  imports = [
    (nixRoot + /home)
  ];

  programs.zsh.shellAliases = {
    open = "explorer.exe .";
  };
}
