{ ... }:

{
  programs.ghostty = {
    enable = true;
    systemd.enable = false;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 14;

      theme = "wallust";

      cursor-style = "block";
      cursor-style-blink = true;
      cursor-opacity = 1;
      cursor-click-to-move = false;

      window-decoration = "none";
      window-padding-balance = true;
      window-padding-color = "extend";
      window-theme = "ghostty";
      window-show-tab-bar = "never";
      maximize = true;

      background-opacity = 0.7;
      background-opacity-cells = true;
      background-blur = true;

      unfocused-split-opacity = 1;
      window-new-tab-position = "end";

      confirm-close-surface = false;
      clipboard-paste-protection = false;

      keybind = [
        "ctrl+shift+k=goto_split:up"
        "ctrl+shift+j=goto_split:down"
        "ctrl+shift+h=goto_split:left"
        "ctrl+shift+l=goto_split:right"
        "ctrl+shift+w=close_surface"
        "ctrl+alt+h=resize_split:left,20"
        "ctrl+alt+j=resize_split:down,20"
        "ctrl+alt+k=resize_split:up,20"
        "ctrl+alt+l=resize_split:right,20"
        "ctrl+shift+[=jump_to_prompt:-1"
        "ctrl+shift+]=jump_to_prompt:1"
        "f11=toggle_fullscreen"
      ];
    };
  };
}
