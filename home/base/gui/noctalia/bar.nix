{ ... }:
{
  programs.noctalia.settings = {
    bar.order = [
      "slate"
      "capsule"
    ];

    bar.capsule = {
      enabled = false;

      position = "top";
      margin_edge = 18;
      margin_ends = 14;

      background_opacity = 0.0;
      compositor_blur = false;
      widget_spacing = 10;

      thickness = 35;
      scale = 1.0;
      font_scale = 1.0;

      capsule = true;
      capsule_thickness = 1.0;
      capsule_padding = 10.00;
      capsule_opacity = 0.8;
      capsule_border = "outline_variant";

      start = [
        "control-center_capsule"
        "weather_capsule"
        "taskbar_capsule"
      ];

      center = [
        "clock_capsule"
        "workspaces_capsule"
        "group:player"
      ];

      end = [
        "tray"
        "volume_capsule"
        "network_capsule"
        "group:tools"
        "brightness"
        "battery"
        "session"
      ];

      capsule_group = [
        {
          id = "tools";
          members = [
            "wallpaper"
            "notifications"
            "clipboard"
            "screenshot_capsule"
            "screen-recorder_capsule"
            "desktop-widgets_capsule"
          ];
          padding = 10;
          widget_spacing = 15;
          border = "outline_variant";
          opacity = 0.8;
        }
        {
          id = "player";
          members = [
            "media_capsule"
            "audio_vis_capsule"
          ];
          padding = 7;
          widget_spacing = 4;
          border = "outline_variant";
          opacity = 0.8;
        }
      ];
    };

    bar.slate = {
      enabled = true;
      position = "top";
      margin_edge = 3;
      margin_ends = 160;
      thickness = 40;
      padding = 16;
      radius = 20;
      background_opacity = 1.0;
      compositor_blur = false;
      capsule = false;
      capsule_thickness = 0.7;
      widget_spacing = 14;

      start = [
        "launcher_slate"
        "workspaces_slate"
        "group:sysmon"
        "group:player"
      ];
      center = [ "clock_slate" ];
      end = [
        "tray"
        "wallpaper"
        "network_slate"
        "volume_slate"
        "notifications"
        "bluetooth"
        "brightness"
        "battery"
        "session"
      ];

      capsule_group = [
        {
          id = "sysmon";
          members = [
            "ram_slate"
            "cpu_slate"
          ];
          padding = 10;
          widget_spacing = 10;
          opacity = 0.0;
        }
        {
          id = "player";
          members = [
            "media_slate"
            "audio_vis_slate"
          ];
          padding = 4;
          widget_spacing = "auto";
          opacity = 0.0;
        }
      ];
    };
    widget = {
      ram_slate = {
        type = "sysmon";
        stat = "ram_used";
        # label_min_width = 50;
        visualization = "none";
      };
      cpu_slate = {
        type = "sysmon";
        stat = "cpu_usage";
        # label_min_width = 25;
        visualization = "none";
      };

      workspaces_slate = {
        type = "workspaces";
        show_labels = false;
        labels_only_when_occupied = false;
        focused_output_only = true;
        anchor = true;
      };

      clock_slate = {
        type = "clock";
        format = "{:%H:%M}";
        actions.left = "panel-toggle control-center calendar";
      };

      media_slate = {
        type = "media";
        album_art_only = false;
        hide_artist = true;
        hide_when_no_media = true;
        min_length = 0;
        max_length = 160;
      };

      audio_vis_slate = {
        type = "audio_visualizer";
        width = 150;
        bands = 40;
        show_when_idle = false;
      };

      network_slate = {
        type = "network";
        show_label = false;
        actions.left = "panel-toggle control-center network";
      };

      volume_slate = {
        type = "volume";
        show_label = false;
        actions = {
          left = "panel-toggle control-center audio";
          right = "volume-mute";
        };
      };

      wallpaper = {
        type = "custom_button";
        glyph = "photo";
        tooltip = "Wallpaper";
        actions.left = "panel-toggle mkiin/wallpaper-picker:picker";
      };

      launcher_slate = {
        type = "launcher";
        # custom_image = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
        custom_image_colorize = true;
      };

      weather_capsule = {
        type = "weather";
        show_condition = false;
      };

      clock_capsule = {
        type = "clock";
        format = "{:%I:%M %p}";
        actions.left = "panel-toggle control-center calendar";
      };

      workspaces_capsule = {
        type = "workspaces";
        show_labels = false;
        show_tooltip = false;
        labels_only_when_occupied = true;
        anchor = true;
        focused_output_only = true;
      };

      volume_capsule = {
        type = "volume";
        show_label = true;

        actions = {
          left = "panel-toggle control-center audio";
          right = "volume-mute";
        };
      };

      network_capsule = {
        type = "network";
        show_label = true;
        actions.left = "panel-toggle control-center network";
      };

      screenshot_capsule = {
        type = "screenshot";
        actions = {
          left = "screenshot-fullscreen";
          middle = "screenshot-annotate";
        };
      };

      screen-recorder_capsule = {
        type = "noctalia/screen_recorder:recorder";
      };

      desktop-widgets_capsule = {
        type = "custom_button";
        glyph = "layout-dashboard";
        actions.left = "desktop-widgets-toggle";
      };

      session = {
        icon_color = "error";
      };

      taskbar_capsule = {
        type = "taskbar";
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

      audio_vis_capsule = {
        type = "audio_visualizer";
        width = 100;
        bands = 16;
        mirrored = true;
        centered = true;
        show_when_idle = true;
        color_1 = "primary";
        color_2 = "secondary";
      };

      media_capsule = {
        type = "media";
        album_art_only = true;
        # hide_album_art = false;
        hide_artist = true;
        min_length = 100;
        max_length = 180;
        art_size = 16;
        title_scroll = "on_hover";
        hide_when_no_media = false;
      };
      control-center_capsule = {
        type = "control-center";
        actions.right = "panel-toggle launcher";
      };
    };
  };
}
