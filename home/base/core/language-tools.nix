{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Nix
    nixd
    nixfmt

    # Lua
    lua-language-server
    stylua

    # Shell
    bash-language-server
    shellcheck
    shfmt
  ];
}
