{ ... }:
{
  programs.noctalia.settings.shell = {
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
        {
          action = "command";
          label = "Hibernate";
          glyph = "bedtime";
          command = "systemctl hibernate";
        }
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
}
