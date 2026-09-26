{ ... }:
{
  programs.noctalia.settings.bar.default = {
    enabled = true;
    position = "top";
    margin_edge = 18;
    margin_ends = 14;
    background_opacity = 0.0;

    start = [
      "launcher"
      "weather"
      "clock"
      "active_window"
    ];

    center = [
      "workspaces"
    ];

    end = [
      "tray"
      "volume"
      "bluetooth"
      "network"
      "control-center"
    ];
  };
}
