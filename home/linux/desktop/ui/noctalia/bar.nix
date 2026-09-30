{ ... }:
{
  programs.noctalia.settings.bar.default = {
    enabled = true;

    position = "top";
    margin_edge = 18;
    margin_ends = 14;

    background_opacity = 0.0;
    widget_spacing = 10;

    thickness = 44;
    scale = 1.10;
    font_scale = 1.10;

    capsule = true;
    capsule_thickness = 0.90;
    capsule_padding = 10.00;
    capsule_border = "outline";

    start = [
      "control-center"
      "weather"
      "taskbar"
    ];

    center = [
      "clock"
      "workspaces"
      "group:player"
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
          "notifications"
          "wallpaper"
          "clipboard"
          "screenshot"
          "screen-recorder"
          "desktop-widgets"
        ];
        padding = 10;
        widget_spacing = 15;
        border = "outline";
      }
      {
        id = "player";
        members = [
          "media"
          "audio-vis"
        ];
        padding = 7;
        widget_spacing = 4;
        border = "outline";
      }
    ];
  };
}
