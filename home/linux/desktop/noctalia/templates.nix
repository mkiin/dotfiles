{ ... }:
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
        "niri"
        "gtk3"
        "gtk4"
      ];
      community_ids = [
        "discord"
        "obsidian"
        "zed"
      ];
    };
  };
}
