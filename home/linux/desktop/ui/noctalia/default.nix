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
      bar.default.enabled = false;
      wallpaper = {
        enable = true;
        directory = "${wallpaperDir}";
        default.path = "${wallpaperDir}/yukino-yukinoshita-cute-close-up.png";
        fill_mode = "crop";
        transition = [ "face" ];
        transition_duration = 800;
        transition_on_startup = false;
        automation = {
          enable = true;
          interval_seconds = 3600;
          order = "alphabetical";
        };
      };
    };
  };
}
