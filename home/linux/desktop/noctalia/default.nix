{ inputs, pkgs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
    ./bar.nix
    ./plugins.nix
    ./shell.nix
    ./templates.nix
    ./wallpaper.nix
  ];
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      patches = (old.patches or [ ]) ++ [
        ./../../../../patches/noctalia-control-center-video-wallpaper.patch
      ];
    });

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

      hooks.started = [ "noctalia msg greeter-sync" ];

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

      lockscreen = {
        enabled = true;
        lock_before_suspend = true;
        blurred_desktop = false;
        blur_intensity = 0.0;
        allow_empty_password = true;
      };

      desktop_widgets.enabled = true;
      lockscreen_widgets.enabled = true;
    };
  };
}
