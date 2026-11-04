{ ... }:
{
  programs.noctalia.settings.desktop_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [
      "desktop-widget-0000000000000004"
      "desktop-widget-0000000000000005"
    ];
    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };
    widget = {
      "desktop-widget-0000000000000004" = {
        type = "media_player";
        output = "DP-1";
        cx = 264.0;
        cy = 220.0;
        scale = 1.0;
        rotation = 0.0;
        box_width = 400.0;
        box_height = 176.0;
        placement_width = 1920.0;
        placement_height = 1080.0;
        settings = {
          album_art_background = false;
          album_art_blur = 24;
          audio_visualizer = true;
          background = true;
          background_color = "surface";
          background_opacity = 0.8;
          background_padding = 14;
          background_radius = 12;
          color = "on_surface";
          font_family = "";
          hide_when_no_media = true;
          layout = "horizontal";
          shadow = true;
        };
      };
      "desktop-widget-0000000000000005" = {
        type = "clock";
        output = "DP-1";
        cx = 288.0;
        cy = 460.0;
        scale = 1.0;
        rotation = 0.0;
        box_width = 528.0;
        box_height = 240.0;
        placement_width = 1920.0;
        placement_height = 1080.0;
        settings = {
          background = false;
          center_text = true;
          color = "primary";
          font_family = "Geist";
        };
      };
    };
  };
}
