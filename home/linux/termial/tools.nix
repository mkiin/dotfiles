{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bubblewrap # require codex sand box
  ];
}
