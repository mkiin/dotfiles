{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.desktop.hypridle;
in
{
  options.modules.desktop.hypridle = {
    # keyboardBacklightTimeout = lib.mkOption {
    #   type = lib.types.int;
    #   description = "Seconds of idle before turning off the keyboard backlight.";
    # };
    lockTimeout = lib.mkOption {
      type = lib.types.int;
      description = "Seconds of idle before locking the screen.";
    };
    screenOffTimeout = lib.mkOption {
      type = lib.types.int;
      description = "Seconds of idle before turning off the monitors (DPMS).";
    };
    suspendTimeout = lib.mkOption {
      type = lib.types.int;
      description = "Seconds of idle before suspending.";
    };

  };

  config = {
    services.hypridle = {
      enable = true;
      settings = {
        general = {
          lock_cmd = "noctalia msg session lock";
          # before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          inhibit_sleep = 3;
          ignore_dbus_inhibit = true;
        };
        listener = [
          {
            timeout = cfg.lockTimeout;
            ignore_inhibit = true;
            # Skip while media is playing, same as screen-off above.
            condition_cmd = "! playerctl -a status 2>/dev/null | grep -q '^Playing$'";
            condition_retry = 30;
            on-timeout = "loginctl lock-session";
          }
          {
            timeout = cfg.screenOffTimeout;
            ignore_inhibit = true;
            # Some apps keep idle-inhibit active even when they are only sitting
            # on a page, which can prevent screen-off forever. Ignore those
            # inhibitors for screen-off, but skip while an MPRIS player reports
            # active playback.
            condition_cmd = "! playerctl -a status 2>/dev/null | grep -q '^Playing$'";
            condition_retry = 30;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }
          {
            timeout = cfg.suspendTimeout;
            condition_cmd = "! playerctl -a status 2>/dev/null | grep -q '^Playing$'";
            condition_retry = 30;
            on-timeout = "noctalia msg session lock-and-suspend";
          }
        ];
      };
    };

  };
}
