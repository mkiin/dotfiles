{ ... }:
{
  programs.noctalia.settings.theme = {
    source = "community";
    community_palette = "Catppuccin Mocha Sapphire";
    # wallpaper_scheme = "";
    templates = {
      enable_builtin_templates = true;
      enable_community_templates = true;
      builtin_ids = [
        "btop"
        "ghostty"
        "kitty"
        "hyprland"
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
