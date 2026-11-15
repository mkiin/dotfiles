{ ... }:
let
  defaultTerminal = "ghostty";
  terminals = {
    ghostty = ./ghostty;
    wezterm = ./wezterm;
  };
in
{
  imports = [ terminals.${defaultTerminal} ];

  home.sessionVariables.TERMINAL = defaultTerminal;
}
