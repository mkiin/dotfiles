{ pkgs, vars, ... }:
{

  home.homeDirectory = "/home/${vars.username}";
  home.packages = with pkgs; [
    bubblewrap # require codex sand box
  ];
}
