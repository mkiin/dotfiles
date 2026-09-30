{ inputs, config, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
    ./bar.nix
    ./lockscreen.nix
    ./plugins.nix
    ./shell.nix
    ./theme.nix
    ./wallpaper.nix
    ./widget.nix
  ];
  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      osd = {
        position = "top_right";
        kinds = {
          volume = false;
          volume_output = false;
          volume_input = false;
          dnd = false;
          keyboard_layout = false;
          media = false;
          keyboard_backlight = false;
        };
      };

      dock = {
        enabled = true;
        layer = "overlay";
      };

      hooks = {
        wallpaper_changed = [
          "${config.xdg.configHome}/desktop-tools/scripts/apply.sh"
        ];
        started = [
          "noctalia msg greeter-sync"
          "${config.xdg.configHome}/desktop-tools/scripts/apply.sh"
        ];
      };

      weather = {
        enabled = true;
        refresh_minutes = 15;
        unit = "celsius";
      };

      location = {
        auto_locate = false;
        address = "Sapporo, Hokkaido, Japan";
        # latitude = 43.0620;
        # longitude = 141.3544;
      };

    };
  };
}
