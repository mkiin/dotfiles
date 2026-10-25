{
  config,
  lib,
  ...
}:
{
  imports = [
    ./bar.nix
    ./plugins.nix
    ./shell.nix
    ./templates.nix
    ./wallpaper.nix
  ];
  options.modules.desktop.noctalia.idle = {
    lockTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      description = "Seconds of idle before locking.";
    };
    screenOffTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      description = "Seconds of idle before turning off displays.";
    };
    suspendTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      description = "Seconds of idle before suspending.";
    };
  };

  config.programs.noctalia = {
    enable = true;
    systemd.enable = false;

    settings = {
      idle.behavior = {
        lock = {
          enabled = true;
          timeout = config.modules.desktop.noctalia.idle.lockTimeout;
          action = "lock";
        };
        screen-off = {
          enabled = true;
          timeout = config.modules.desktop.noctalia.idle.screenOffTimeout;
          action = "screen_off";
        };
        suspend = {
          enabled = true;
          timeout = config.modules.desktop.noctalia.idle.suspendTimeout;
          action = "lock_and_suspend";
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

      hooks = {
        started = [ "noctalia msg greeter-sync" ];
        wallpaper_changed = [ "noctalia msg templates-apply" ];
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

      lockscreen = {
        enabled = true;
        lock_before_suspend = true;
        blurred_desktop = false;
        blur_intensity = 0.0;
        allow_empty_password = true;
      };

      desktop_widgets.enabled = true;
      lockscreen_widgets.enabled = true;
    };
  };
}
