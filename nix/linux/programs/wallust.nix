{ ... }:

{
  xdg.configFile = {
    "wallust/wallust.toml".text = ''
      backend     = "wal"
      color_space = "lab"
      check_contrast = true
      saturation  = 0

      [templates]
      waybar = { template = "waybar.css",        target = "~/.config/waybar/colors-waybar.css" }
      ghostty = { template = "ghostty.conf",     target = "~/.config/ghostty/themes/wallust" }
      wezterm = { template = "wezterm.toml",     target = "~/.config/wezterm/colors/wallust.toml" }
      pywal   = { template = "pywal-colors.json", target = "~/.cache/wal/colors.json" }
    '';

    "wallust/templates/waybar.css".text = ''
      @define-color cursor     {{cursor}};
      @define-color background {{background}};
      @define-color foreground {{foreground}};
      @define-color color0  {{color0 }};
      @define-color color1  {{color1 }};
      @define-color color2  {{color2 }};
      @define-color color3  {{color3 }};
      @define-color color4  {{color4 }};
      @define-color color5  {{color5 }};
      @define-color color6  {{color6 }};
      @define-color color7  {{color7 }};
      @define-color color8  {{color8 }};
      @define-color color9  {{color9 }};
      @define-color color10 {{color10}};
      @define-color color11 {{color11}};
      @define-color color12 {{color12}};
      @define-color color13 {{color13}};
      @define-color color14 {{color14}};
      @define-color color15 {{color15}};
    '';

    "wallust/templates/ghostty.conf".text = ''
      palette = 0={{color0}}
      palette = 1={{color1}}
      palette = 2={{color2}}
      palette = 3={{color3}}
      palette = 4={{color4}}
      palette = 5={{color5}}
      palette = 6={{color6}}
      palette = 7={{color7}}
      palette = 8={{color8}}
      palette = 9={{color9}}
      palette = 10={{color10}}
      palette = 11={{color11}}
      palette = 12={{color12}}
      palette = 13={{color13}}
      palette = 14={{color14}}
      palette = 15={{color15}}

      background    = {{background}}
      foreground    = {{foreground}}
      cursor-color  = {{cursor}}
    '';

    "wallust/templates/wezterm.toml".text = ''
      [colors]
      foreground    = "{{foreground}}"
      background    = "{{background}}"
      cursor_bg     = "{{cursor}}"
      cursor_fg     = "{{background}}"
      cursor_border = "{{cursor}}"
      ansi    = ["{{color0}}", "{{color1}}", "{{color2}}", "{{color3}}", "{{color4}}", "{{color5}}", "{{color6}}", "{{color7}}"]
      brights = ["{{color8}}", "{{color9}}", "{{color10}}", "{{color11}}", "{{color12}}", "{{color13}}", "{{color14}}", "{{color15}}"]

      [metadata]
      name = "Wallust"
    '';

    "wallust/templates/pywal-colors.json".text = ''
      {
        "special": {
          "background": "{{background}}",
          "foreground": "{{foreground}}",
          "cursor":     "{{cursor}}"
        },
        "colors": {
          "color0":  "{{color0}}",
          "color1":  "{{color1}}",
          "color2":  "{{color2}}",
          "color3":  "{{color3}}",
          "color4":  "{{color4}}",
          "color5":  "{{color5}}",
          "color6":  "{{color6}}",
          "color7":  "{{color7}}",
          "color8":  "{{color8}}",
          "color9":  "{{color9}}",
          "color10": "{{color10}}",
          "color11": "{{color11}}",
          "color12": "{{color12}}",
          "color13": "{{color13}}",
          "color14": "{{color14}}",
          "color15": "{{color15}}"
        }
      }
    '';
  };
}
