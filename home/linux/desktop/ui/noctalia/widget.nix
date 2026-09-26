{ ... }:
{
  programs.noctalia.settings = {
    widget = {
      launcher = {
        type = "launcher";
      };

      weather = {
        type = "weather";
      };

      clock = {
        type = "clock";
        format = "{:%I:%M %p}";

        actions.left = "panel-toggle control-center calendar";
      };

      active_window = {
        type = "active_window";
      };

      workspaces = {
        type = "workspaces";
      };

      tray = {
        type = "tray";
      };

      volume = {
        type = "volume";
        show_label = true;

        actions = {
          left = "panel-toggle control-center audio";
          right = "volume-mute";
        };
      };

      bluetooth = {
        type = "bluetooth";

        actions.left = "panel-toggle control-center bluetooth";
      };

      network = {
        type = "network";
        show_label = true;

        actions.left = "panel-toggle control-center network";
      };

      control-center = {
        type = "control-center";
      };
    };

    weather = {
      enabled = true;
      refresh_minutes = 15;
      unit = "celsius";
    };
  };
}
