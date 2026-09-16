{
  pkgs,
  ...
}:

{
  programs.ghostty = {
    enable = true;

    package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.ghostty;

    systemd.enable = false;

    installBatSyntax = !pkgs.stdenv.hostPlatform.isDarwin;

    settings = {
      font-family = "JetBrainsMono Nerd Font";
      font-size = 14;

      theme = "wallust";

      cursor-style = "block";
      cursor-style-blink = true;
      cursor-opacity = 1;
      cursor-click-to-move = false;

      mouse-hide-while-typing = true;

      window-decoration = "none";
      window-padding-balance = true;
      window-padding-color = "extend";
      window-theme = "ghostty";
      window-show-tab-bar = "never";
      window-new-tab-position = "end";
      maximize = true;

      background-opacity = 0.7;
      background-opacity-cells = true;
      background-blur = true;

      scrollback-limit = 20000;

      unfocused-split-opacity = 1;

      confirm-close-surface = false;
      clipboard-paste-protection = false;

      shell-integration = "detect";
      shell-integration-features = "no-cursor";

      notify-on-command-finish = "unfocused";
      notify-on-command-finish-action = "no-bell,notify";
      notify-on-command-finish-after = "10s";

      keybind = [
        "ctrl+shift+k=goto_split:up"
        "ctrl+shift+j=goto_split:down"
        "ctrl+shift+h=goto_split:left"
        "ctrl+shift+l=goto_split:right"

        "ctrl+alt+h=resize_split:left,20"
        "ctrl+alt+j=resize_split:down,20"
        "ctrl+alt+k=resize_split:up,20"
        "ctrl+alt+l=resize_split:right,20"

        "ctrl+shift+w=close_surface"

        "ctrl+shift+[=jump_to_prompt:-1"
        "ctrl+shift+]=jump_to_prompt:1"

        "f11=toggle_fullscreen"
      ];
    };
  };
}
