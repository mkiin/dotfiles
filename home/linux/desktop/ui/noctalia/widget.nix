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

      tray = { };

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

      clipboard = { };

      screenshot = { };

      screen-recorder = {
        type = "noctalia/screen_recorder:recorder";
      };

      notifications = { };

      wallpaper = { };

      theme-mode = { };

      control-center = { };

    };
  };
}
