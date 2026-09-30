{ ... }:
{
  programs.noctalia.settings.desktop_widgets = {
    enabled = true;
    schema_version = 2;
    widget_order = [
      "desktop-widget-0000000000000001"
      "desktop-widget-0000000000000002"
    ];

    grid = {
      cell_size = 16;
      major_interval = 4;
      visible = true;
    };

    widget = {
      desktop-widget-0000000000000001 = {
        type = "audio_visualizer";
        output = "DP-2";
        cx = 1280.0;
        cy = 1296.0;
        box_width = 1328.0;
        box_height = 352.0;
        placement_width = 2560.0;
        placement_height = 1440.0;
        rotation = 3.1415927410125732;
        flip_x = true;
        flip_y = true;

        settings = {
          background = false;
          bands = 70;
          centered = false;
          color_1 = "primary";
          color_2 = "primary";
          mirrored = true;
          reversed = false;
          show_when_idle = false;
        };
      };

      desktop-widget-0000000000000002 = {
        type = "media_player";
        output = "DP-2";
        cx = 248.0;
        cy = 1328.0;
        box_width = 368.0;
        box_height = 160.0;
        placement_width = 2560.0;
        placement_height = 1440.0;
        rotation = -0.0;

        settings = {
          color = "on_surface";
          font_family = "Noto Sans CJK JP";
          hide_when_no_media = true;
          layout = "horizontal";
          shadow = true;
        };
      };
    };
  };
}
