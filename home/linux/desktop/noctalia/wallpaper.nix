{ config, myvars, ... }:
let
  wallpaperDir = "${config.home.homeDirectory}/${myvars.dotfilesdir}/images";
in
{
  programs.noctalia.settings.wallpaper = {
    enabled = true;
    directory = wallpaperDir;
    default.path = "${wallpaperDir}/yukino-yukinoshita-cute-close-up.png";
    fill_mode = "crop";
    transition = [
      "fade"
      # "disc"
      # "stripes"
    ];
    transition_duration = 800;
    transition_on_startup = false;
    automation = {
      # enabled = true;
      interval_seconds = 3600;
      order = "alphabetical";
    };
  };
}
