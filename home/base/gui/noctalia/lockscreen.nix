{ ... }:
{
  programs.noctalia.settings = {
    lockscreen = {
      enabled = true;
      lock_before_suspend = true;
      blurred_desktop = false;
      blur_intensity = 0.0;
      allow_empty_password = false;
    };

    lockscreen_widgets = {
      enabled = true;
      schema_version = 2;
      widget_order = [
        "lockscreen-widget-0000000000000013"
        "lockscreen-widget-0000000000000005"
        "lockscreen-login-box@DP-3"
        "lockscreen-login-box@DP-2"
        "lockscreen-login-box@DP-1"
        "lockscreen-widget-0000000000000001"
        "lockscreen-widget-0000000000000002"
        "lockscreen-widget-0000000000000003"
        "lockscreen-widget-0000000000000004"
        "lockscreen-widget-0000000000000007"
        "lockscreen-widget-000000000000000f"
        "lockscreen-widget-0000000000000010"
        "lockscreen-widget-0000000000000014"
      ];
      grid = {
        cell_size = 16;
        major_interval = 4;
        visible = true;
      };
      widget = {
        "lockscreen-login-box@DP-1" = {
          type = "login_box";
          output = "DP-1";
          cx = 960.0;
          cy = 898.0;
          box_width = 810.0;
          box_height = 196.0;
          placement_width = 1920.0;
          placement_height = 1080.0;
          rotation = 0.0;
          settings = {
            background_color = "surface_container";
            background_opacity = 0.88;
            background_radius = 12.0;
            center_password_text = false;
            input_opacity = 1.0;
            input_radius = 6.0;
            layout = "regular";
            show_caps_lock = true;
            show_keyboard_layout = true;
            show_login_button = true;
            show_media = true;
            show_password_reveal = true;
            show_session_buttons = true;
            show_unlock_hint = true;
            show_weather = true;
          };
        };
        "lockscreen-login-box@DP-2" = {
          type = "login_box";
          output = "DP-2";
          cx = 1280.0;
          cy = 1262.0;
          box_width = 810.0;
          box_height = 196.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings = {
            background_color = "surface_container";
            background_opacity = 0.9;
            background_radius = 12.0;
            center_password_text = false;
            input_opacity = 1.0;
            input_radius = 6.0;
            layout = "regular";
            show_caps_lock = true;
            show_keyboard_layout = false;
            show_login_button = true;
            show_media = true;
            show_password_reveal = true;
            show_session_buttons = true;
            show_unlock_hint = true;
            show_weather = true;
          };
        };
        "lockscreen-login-box@DP-3" = {
          type = "login_box";
          output = "DP-3";
          cx = 960.0;
          cy = 898.0;
          box_width = 810.0;
          box_height = 196.0;
          placement_width = 1920.0;
          placement_height = 1080.0;
          rotation = 0.0;
          settings = {
            background_color = "surface_container";
            background_opacity = 0.88;
            background_radius = 12.0;
            center_password_text = false;
            input_opacity = 1.0;
            input_radius = 6.0;
            layout = "regular";
            show_caps_lock = true;
            show_keyboard_layout = true;
            show_login_button = true;
            show_media = true;
            show_password_reveal = true;
            show_session_buttons = true;
            show_unlock_hint = true;
            show_weather = true;
          };
        };
        "lockscreen-widget-0000000000000001" = {
          type = "calendar";
          output = "DP-2";
          cx = 400.0;
          cy = 816.0;
          box_width = 608.0;
          box_height = 576.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings = {
            background = false;
            background_opacity = 0.96;
            background_padding = 10;
            font_family = "Inter Variable";
            show_events = false;
            show_week_numbers = false;
          };
        };
        "lockscreen-widget-0000000000000002" = {
          type = "clock";
          output = "DP-2";
          cx = 392.0;
          cy = 296.0;
          box_width = 528.0;
          box_height = 272.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings = {
            background_color = "surface";
            background_opacity = 0.0;
            background_padding = 0;
            color = "on_surface";
            font_family = "Inter Display ExtraBold";
          };
        };
        "lockscreen-widget-0000000000000003" = {
          type = "clock";
          output = "DP-2";
          cx = 400.0;
          cy = 400.0;
          box_width = 352.0;
          box_height = 80.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings = {
            background_opacity = 0.0;
            color = "secondary";
            font_family = "Inter Variable";
            format = "{:%A, %B %d}";
            timezone = "";
          };
        };
        "lockscreen-widget-0000000000000004" = {
          type = "sticker";
          output = "DP-2";
          cx = 1600.0;
          cy = 1024.0;
          box_width = 192.0;
          box_height = 192.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings = {
            background = false;
            image_path = "/home/mkiin/ghq/github.com/mkiin/dotfiles/assets/doro-sleeping.GIF";
            opacity = 1.0;
          };
        };
        "lockscreen-widget-0000000000000005" = {
          type = "audio_visualizer";
          output = "DP-2";
          cx = 1280.0;
          cy = 1040.0;
          box_width = 848.0;
          box_height = 160.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings = {
            background = false;
            bands = 40;
            centered = false;
            color_2 = "secondary";
            mirrored = true;
            reversed = false;
            show_when_idle = true;
          };
        };
        "lockscreen-widget-0000000000000007" = {
          type = "fancy_audio_visualizer";
          output = "DP-2";
          cx = 2128.0;
          cy = 1160.0;
          box_width = 752.0;
          box_height = 528.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings = {
            background = false;
            bloom_intensity = 0.5;
            inner_diameter = 0.7;
            visualization_mode = "bars_rings";
          };
        };
        "lockscreen-widget-000000000000000f" = {
          type = "sysmon";
          output = "DP-2";
          cx = 560.0;
          cy = 1164.0;
          box_width = 240.0;
          box_height = 144.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings = {
            background = false;
            background_opacity = 0.0;
            display = "graph";
            font_family = "Inter Display";
            gauge_layout = "horizontal";
            stat = "cpu_usage";
            stat2 = "cpu_temp";
          };
        };
        "lockscreen-widget-0000000000000010" = {
          type = "sysmon";
          output = "DP-2";
          cx = 560.0;
          cy = 1280.0;
          box_width = 240.0;
          box_height = 144.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings = {
            background = false;
            background_opacity = 0.0;
            display = "graph";
            font_family = "Inter Display";
            gauge_layout = "horizontal";
            stat = "ram_pct";
            stat2 = "gpu_vram";
          };
        };
        "lockscreen-widget-0000000000000013" = {
          type = "clock";
          output = "DP-2";
          cx = 400.00003051757812;
          cy = 720.0;
          box_width = 1440.0;
          box_height = 864.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 1.5707963705062866;
          settings = {
            background = true;
            background_opacity = 0.99;
            background_radius = 0;
            format = "";
            shadow = true;
          };
        };
        "lockscreen-widget-0000000000000014" = {
          type = "weather";
          output = "DP-2";
          cx = 248.0;
          cy = 1244.0;
          box_width = 304.0;
          box_height = 160.0;
          placement_width = 2560.0;
          placement_height = 1440.0;
          rotation = 0.0;
          settings.background = false;
        };
      };
    };
  };
}
