{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    general = {
      gaps_in          = 3;
      gaps_out         = 8;
      border_size      = 0;
      layout           = "dwindle";
      resize_on_border = true;
      allow_tearing    = false;
    };

    decoration = {
      rounding = 10;
      shadow = {
        enabled        = true;
        range          = 8;
        render_power   = 3;
        color          = "rgba(00000080)";
        color_inactive = "rgba(00000033)";
      };
      blur = {
        enabled           = true;
        size              = 3;
        passes            = 2;
        new_optimizations = true;
        ignore_opacity    = true;
        xray              = false;
      };
    };

    animations = {
      enabled = true;
      bezier = [
        "wind, 0.05, 0.9, 0.1, 1"
        "winIn, 0.1, 1, 0.1, 1"
        "winOut, 0.3, -0.3, 0, 1"
        "liner, 1, 1, 1, 1"
      ];
      animation = [
        "windows, 1, 6, wind, slide"
        "windowsIn, 1, 6, winIn, slide"
        "windowsOut, 1, 5, winOut, slide"
        "windowsMove, 1, 5, wind, slide"
        "border, 1, 1, liner"
        "borderangle, 1, 30, liner, once"
        "fade, 1, 2, default"
        "workspaces, 1, 5, wind"
      ];
    };

    dwindle = {
      preserve_split = true;
    };

    misc = {
      force_default_wallpaper = 0;
      disable_hyprland_logo   = true;
    };
  };
}
