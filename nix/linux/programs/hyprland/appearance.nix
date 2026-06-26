{ ... }:

{
  wayland.windowManager.hyprland.extraConfig = ''
    hl.config({
      general = {
        gaps_in          = 3,
        gaps_out         = 8,
        border_size      = 0,
        layout           = "dwindle",
        resize_on_border = true,
        allow_tearing    = false,
      },
      decoration = {
        rounding = 10,
        shadow = {
          enabled        = true,
          range          = 8,
          render_power   = 3,
          color          = "rgba(00000080)",
          color_inactive = "rgba(00000033)",
        },
        blur = {
          enabled           = true,
          size              = 3,
          passes            = 2,
          new_optimizations = true,
          ignore_opacity    = true,
          xray              = false,
        },
      },
      animations = { enabled = true },
      dwindle    = { preserve_split = true },
      misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
      },
    })

    hl.curve("wind",   { type = "bezier", points = { {0.05,  0.9}, {0.1, 1} } })
    hl.curve("winIn",  { type = "bezier", points = { {0.1,   1  }, {0.1, 1} } })
    hl.curve("winOut", { type = "bezier", points = { {0.3,  -0.3}, {0,   1} } })
    hl.curve("liner",  { type = "bezier", points = { {1,     1  }, {1,   1} } })

    hl.animation({ leaf = "windows",     enabled = true, speed = 6,  bezier = "wind",   style = "slide" })
    hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6,  bezier = "winIn",  style = "slide" })
    hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,  bezier = "winOut", style = "slide" })
    hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,  bezier = "wind",   style = "slide" })
    hl.animation({ leaf = "border",      enabled = true, speed = 1,  bezier = "liner" })
    hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner",  style = "once" })
    hl.animation({ leaf = "fade",        enabled = true, speed = 2,  bezier = "default" })
    hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,  bezier = "wind" })
  '';
}
