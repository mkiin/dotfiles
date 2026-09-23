{
  inputs,
  config,
  myvars,
  ...
}:
let
  wallpaperDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}/images/wallpaper";
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      shell.greeter_sync.auto_sync = true;
      bar.default.enabled = false;

      wallpaper = {
        enabled = true;
        directory = "${wallpaperDir}";
        default.path = "${wallpaperDir}/yukino-yukinoshita-cute-close-up.png";
        fill_mode = "crop";
        transition = [
          "fade"
          "disc"
          "stripes"
        ];
        transition_duration = 800;
        transition_on_startup = false;
        automation = {
          enabled = true;
          interval_seconds = 3600;
          order = "alphabetical";
        };
      };

      theme = {
        source = "wallpaper";
        wallpaper_scheme = "m3-content";
      };

      osd = {
        kinds = {
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

      lockscreen = {
        enabled = true;
        lock_before_suspend = true;
      };

      hooks = {
        wallpaper_changed = "${config.xdg.configHome}/waybar/scripts/reload-css.sh";
        started = ''
          noctalia msg greeter-sync
          ${config.xdg.configHome}/waybar/scripts/reload-css.sh
        '';
      };
    };
  };
}
