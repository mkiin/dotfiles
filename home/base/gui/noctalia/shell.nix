{ ... }:
{
  programs.noctalia.settings.shell = {
    greeter_sync.auto_sync = true;
    font_family = "Geist";
    settings_window_translucent = true;
    polkit_agent = true;

    screenshot = {
      directory = "~/Pictures/Screenshots";
      save_to_file = true;
    };

    session = {
      show_shortcuts = true;
      actions = [
        {
          action = "lock";
          shortcut = "l";
        }
        {
          action = "logout";
          shortcut = "o";
        }
        {
          action = "lock_and_suspend";
          shortcut = "z";
        }
        {
          action = "command";
          label = "Hibernate";
          shortcut = "h";
          glyph = "bedtime";
          command = "systemctl hibernate";
        }
        {
          action = "reboot";
          shortcut = "r";
        }
        {
          action = "shutdown";
          shortcut = "s";
          variant = "default";
        }
      ];
    };

    panel = {
      transparency_mode = "glass";
      control_center_position = "follow_bar";
      session_position = "center";
      control_center_placement = "floating";
      wallpaper_placement = "floating";
      session_placement = "floating";
    };
  };
}
