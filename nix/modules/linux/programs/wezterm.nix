{ dotLink, ... }:

{
  xdg.configFile."wezterm/wezterm.lua".source = dotLink "wezterm" "wezterm.lua";
}
