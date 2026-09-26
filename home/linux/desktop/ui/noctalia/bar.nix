{ ... }:
{
  programs.noctalia.settings.bar.default = {
    enabled = true;

    position = "top";
    margin_edge = 18;
    margin_ends = 14;

    background_opacity = 0.0;
    widget_spacing = 10;

    capsule = true;

    start = [
      "launcher"
      "weather"
      "active_window"
    ];

    center = [
      "clock"
      "workspaces"
      "notifications"
    ];

    end = [
      "tray"
      "volume"
      "network"
      "group:tools"
      "session"
    ];

    capsule_group = [
      {
        id = "tools";
        members = [
          "clipboard"
          "screenshot"
          "screen-recorder"
        ];
      }
    ];
  };
}
