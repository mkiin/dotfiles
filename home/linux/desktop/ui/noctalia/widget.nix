{ pkgs, ... }:
{
  programs.noctalia.settings = {
    widget = {
      launcher = {
        custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        custom_image_colorize = true;
      };

      weather = {
        show_condition = false;
      };

      clock = {
        format = "{:%I:%M %p}";
        actions.left = "panel-toggle control-center calendar";
      };

      active_window = { };

      workspaces = {
        show_labels = false;
        labels_only_when_occupied = true;
        anchor = true;
      };

      volume = {
        show_label = true;

        actions = {
          left = "panel-toggle control-center audio";
          right = "volume-mute";
        };
      };

      network = {
        show_label = true;
        actions.left = "panel-toggle control-center network";
      };

      screen-recorder = {
        type = "noctalia/screen_recorder:recorder";
      };

      theme-switcher = {
        type = "theblackdon/theme-switcher:theme-switcher";
      };

      taskbar = {
        group_by_workspace = false;
        show_all_outputs = true;
        only_active_workspace = false;
        show_window_title = false;
        show_active_indicator = true;
        icon_scale = 1.0;
        item_spacing = 6;
        active_indicator_color = "primary";
        active_opacity = 1.0;
        inactive_opacity = 0.75;
      };

      tray = { };

      clipboard = { };

      screenshot = { };

      notifications = { };

      wallpaper = { };

      theme-mode = { };

      control-center = { };

    };
  };
}
