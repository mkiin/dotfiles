{ ... }:
let
  defaultTerminal = "ghostty";
  terminals = {
    ghostty = ./ghostty;
    wezterm = ./wezterm;
    kitty = ./kitty.nix;
  };
in
{
  imports = [ terminals.${defaultTerminal} ];

  home.sessionVariables.TERMINAL = defaultTerminal;
}
