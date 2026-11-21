{ noctaliaWidgetLayout, ... }:
{
  programs.noctalia.settings.desktop_widgets = noctaliaWidgetLayout {
    enabled = true;
    schema_version = 2;
    widget_order = [
      "desktop-widget-0000000000000006"
      "desktop-widget-0000000000000007"
    ];
    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };
    widget = {
      "desktop-widget-0000000000000006" = {
        type = "weather";
        enabled = true;
        cx = 2320.0;
        cy = 192.0;
        rotation = 0.0;
        box_width = 384.0;
        box_height = 192.0;
        placement_width = 2560.0;
        placement_height = 1440.0;
        settings = {
          background = true;
          background_opacity = 0.3;
          background_padding = 10;
          background_radius = 10;
          show_forecast = false;
        };
      };
      "desktop-widget-0000000000000007" = {
        type = "media_player";
        enabled = true;
        cx = 2320.0;
        cy = 416.0;
        rotation = 0.0;
        box_width = 384.0;
        box_height = 192.0;
        placement_width = 2560.0;
        placement_height = 1440.0;
        settings = {
          album_art_background = false;
          audio_visualizer = true;
          background = true;
          background_opacity = 0.3;
          background_padding = 19;
          background_radius = 10;
          hide_when_no_media = true;
          layout = "horizontal";
          shadow = true;
        };
      };
    };
  };
}
