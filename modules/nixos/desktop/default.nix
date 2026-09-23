{
  config,
  lib,
  myvars,
  mylib,
  ...
}:
let
  cfg = config.modules.desktop.wayland;
  wallpaperDir = "${myvars.linuxhomedir}/${myvars.dotfilesdir}/images/wallpaper";
in
{
  options.modules.desktop.wayland.enable = lib.mkEnableOption "Wayland Display Server";

  imports = mylib.scanPaths ./. ++ [ ../base ];

  config = lib.mkIf cfg.enable {
    services.displayManager.noctalia-greeter = {
      enable = true;
      passwordlessSyncUsers = [ myvars.username ];
      settings = {
        session.default = "Hyprland (uwsm-managed)";
        user.default = myvars.username;
        keyboard.layout = "us";
        output.name = "DP-2";

        appearance.wallpaper = {
          path = "${wallpaperDir}/yukino-yukinoshita-cute-close-up.png";
          fill_mode = "crop";
        };

        appearance.wallpapers."DP-2" = {
          path = "${wallpaperDir}/yukino-yukinoshita-cute-close-up.png";
          fill_mode = "crop";
        };
      };
    };
  };
}
