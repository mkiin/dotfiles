{
  inputs,
  config,
  myvars,
  ...
}:
let
  wallpaperDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}/images";
in
{
  imports = [
    inputs.noctalia.homeModules.default
    ./bar.nix
    ./widget.nix
  ];
  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      wallpaper = {
        enabled = true;
        directory = "${wallpaperDir}";
        default.path = "${wallpaperDir}/yukino-yukinoshita-cute-close-up.png";
        fill_mode = "crop";
        transition = [
          "fade"
          # "disc"
          # "stripes"
        ];
        transition_duration = 800;
        transition_on_startup = false;
        automation = {
          # enabled = true;
          interval_seconds = 3600;
          order = "alphabetical";
        };
      };

      theme = {
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
          ];
          community_ids = [
            "discord"
            "obsidian"
          ];
        };
      };

      osd = {
        position = "top_right";
        kinds = {
          volume = false;
          volume_output = false;
          volume_input = false;
          dnd = false;
          keyboard_layout = false;
          media = false;
          keyboard_backlight = false;
        };
      };

      dock = {
        enabled = true;
        layer = "overlay";
      };

      lockscreen = {
        enabled = true;
        lock_before_suspend = false;
      };

      hooks = {
        wallpaper_changed = [
          "${config.xdg.configHome}/desktop-tools/scripts/apply.sh"
        ];
        started = [
          "noctalia msg greeter-sync"
          "${config.xdg.configHome}/desktop-tools/scripts/apply.sh"
        ];
      };

      shell = {
        greeter_sync.auto_sync = true;
        font_family = "SF Pro Text";
        settings_window_translucent = true;
        polkit_agent = true;

        session = {
          show_shortcuts = false;
          actions = [
            { action = "lock"; }
            { action = "logout"; }
            { action = "lock_and_suspend"; }
            { action = "reboot"; }
            {
              action = "shutdown";
              variant = "default";
            }
          ];
        };

        launcher = {
          categories = false;
          app_grid = true;
        };

        panel = {
          transparency_mode = "glass";
          control_center_position = "center";
          session_position = "center";
          control_center_placement = "floating";
          wallpaper_placement = "floating";
          session_placement = "floating";
        };
      };

      plugins = {
        enabled = [
          "noctalia/bitwarden"
          "noctalia/screen_recorder"
          "theblackdon/theme-switcher"
        ];
        auto_update = "all";
        source = [
          {
            name = "official";
            kind = "git";
            location = "https://github.com/noctalia-dev/official-plugins";
            enabled = true;
          }
          {
            name = "community";
            kind = "git";
            location = "https://github.com/noctalia-dev/community-plugins";
            enabled = true;
          }
        ];
      };

      plugin_settings."noctalia/screen_recorder" = {
        video_source = "focused";
        frame_rate = 30;
        audio_codec = "aac";
      };

      weather = {
        enabled = true;
        refresh_minutes = 15;
        unit = "celsius";
      };

      location = {
        auto_locate = false;
        address = "Sapporo, Hokkaido, Japan";
        # latitude = 43.0620;
        # longitude = 141.3544;
      };

      idle = {
        behavior_order = [
          "lock"
          "screen-off"
          "suspend"
        ];
        pre_action_fade_seconds = 2.0;
        behavior = {
          lock = {
            enabled = true;
            timeout = 60;
          };
          screen-off = {
            enabled = true;
            timeout = 90;
          };
          suspend = {
            enabled = true;
            timeout = 100;
          };
        };
      };
    };
  };
}
