{ config, lib, ... }:
let
  cfg = config.modules.desktop;
in
{
  programs.noctalia.settings.theme = {
    source = "community";
    community_palette = "Rose Pine Moon Alt";
    # wallpaper_scheme = "";
    templates = {
      enable_builtin_templates = true;
      enable_community_templates = true;
      builtin_ids = [
        "btop"
        "ghostty"
        "kitty"
        "gtk3"
        "gtk4"
      ]
      ++ lib.optional (cfg.hyprland.enable or false) "hyprland"
      ++ lib.optional cfg.niri.enable "niri";
      community_ids = [
        "bat"
        "discord"
        "fcitx5"
        "obsidian"
        "papirus-icons"
        "zed"
      ];
    };
  };
}
