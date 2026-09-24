{
  inputs,
  config,
  myvars,
  ...
}:
let
  wallpaperDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}/images/wallpaper";
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      bar.default.enabled = false;

      wallpaper = {
        enabled = true;
        directory = "${wallpaperDir}";
        default.path = "${wallpaperDir}/yukino-yukinoshita-cute-close-up.png";
        fill_mode = "crop";
        transition = [
          "fade"
          "disc"
          "stripes"
        ];
        transition_duration = 800;
        transition_on_startup = false;
        automation = {
          enabled = true;
          interval_seconds = 3600;
          order = "alphabetical";
        };
      };

      theme = {
        source = "wallpaper";
        wallpaper_scheme = "m3-content";
        templates = {
          enable_builtin_templates = true;
          enable_community_templates = true;
          builtin_ids = [
            "btop"
            "ghostty"
          ];
          community_ids = [
            "discord"
            "obsidian"
          ];
        };
      };

      osd = {
        position = "bottom_right";
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
        lock_before_suspend = true;
      };

      hooks = {
        wallpaper_changed = [
          "${config.xdg.configHome}/wallust/scripts/run-wallust.sh"
          "${config.xdg.configHome}/waybar/scripts/reload-css.sh"
        ];
        started = [
          "noctalia msg greeter-sync"
          "${config.xdg.configHome}/wallust/scripts/run-wallust.sh"
          "${config.xdg.configHome}/waybar/scripts/reload-css.sh"
        ];
      };

      shell = {
        greeter_sync.auto_sync = true;
        session.show_shortcuts = false;
        settings_window_translucent = true;
        panel = {
          transparency_mode = "glass";
          # Noctalia's bar is disabled; open these panels without a bar anchor.
          control_center_placement = "floating";
          wallpaper_placement = "floating";
          session_placement = "floating";
        };
      };

      plugins = {
        enabled = [
          "noctalia/bitwarden"
          "noctalia/screen_recorder"
        ];
        auto_update = "all";
        source = {
          name = "official";
          kind = "git";
          location = "https://github.com/noctalia-dev/official-plugins";
          enabled = true;
        };
      };
    };
  };
}
