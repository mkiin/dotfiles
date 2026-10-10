{ ... }:
{
  programs.noctalia.settings = {
    bar.capsule = {
      enabled = true;

      position = "top";
      margin_edge = 18;
      margin_ends = 14;

      background_opacity = 0.0;
      widget_spacing = 10;

      thickness = 35;
      scale = 1.0;
      font_scale = 1.0;

      capsule = true;
      capsule_thickness = 1.0;
      capsule_padding = 10.00;
      capsule_opacity = 0.8;
      capsule_border = "outline";

      start = [
        "control-center"
        "weather"
        "taskbar"
      ];

      center = [
        "clock"
        "workspaces"
        "group:player"
      ];

      end = [
        "tray"
        "volume"
        "network"
        "group:tools"
        "session"
      ];

      capsule_group = [
        {
          id = "tools";
          members = [
            "notifications"
            "wallpaper"
            "clipboard"
            "screenshot"
            "screen-recorder"
            "desktop-widgets"
          ];
          padding = 10;
          widget_spacing = 15;
          border = "outline";
        }
        {
          id = "player";
          members = [
            "media"
            "audio-vis"
          ];
          padding = 7;
          widget_spacing = 4;
          border = "outline";
        }
      ];
    };
  };
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
    control-center = {
      actions.right = "panel-toggle launcher";
    };
  };
}
