{ lnk, ... }:
{
  xdg.configFile."wezterm/wezterm.lua".source = lnk ./wezterm.lua;
}
