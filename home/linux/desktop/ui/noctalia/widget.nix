{ ... }:
{
  programs.noctalia.settings = {
    widget = {
      launcher = {
        # custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
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
        focused_output_only = true;
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

      desktop-widgets = {
        type = "custom_button";
        glyph = "layout-dashboard";
        tooltip = "Toggle desktop widgets";
        actions.left = "desktop-widgets-toggle";
      };

      session = {
        icon_color = "error";
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

      audio-vis = {
        type = "audio_visualizer";
        width = 100;
        bands = 16;
        mirrored = true;
        centered = true;
        show_when_idle = true;
        color_1 = "primary";
        color_2 = "secondary";
      };

      media = {
        album_art_only = true;
        # hide_album_art = false;
        hide_artist = true;
        min_length = 100;
        max_length = 180;
        art_size = 16;
        title_scroll = "on_hover";
        hide_when_no_media = false;
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
