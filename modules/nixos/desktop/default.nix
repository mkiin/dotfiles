{
  config,
  lib,
  myvars,
  mylib,
  ...
}:
let
  cfg = config.modules.desktop.wayland;
  wallpaper = ../../../images/wallpaper/yukino-yukinoshita-cute-close-up.png;
in
{
  options.modules.desktop.wayland.enable = lib.mkEnableOption "Wayland Display Server";

  imports = mylib.scanPaths ./. ++ [ ../base ];

  config = lib.mkIf cfg.enable {
    # services.greetd = {
    #   enable = true;
    #   settings = {
    #     default_session = {
    #       user = myvars.username;
    #       command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd $HOME/.wayland-session";
    #     };
    #   };
    # };
    services.displayManager.noctalia-greeter = {
      enable = true;
      passwordlessSyncUsers = [ myvars.username ];
      settings = {
        session.default = "Hyprland (uwsm-managed)";
        user.default = myvars.username;
        keyboard.layout = "us";
        output.name = "DP-2";

        appearance = {
          hide_logo = true;
          wallpaper = {
            path = "${wallpaper}";
            fill_mode = "crop";
          };
          palette = {
            primary = "#c3c4e2";
            on_primary = "#2c2f46";
            secondary = "#c6c5d2";
            on_secondary = "#2f303a";
            tertiary = "#e1bcd2";
            on_tertiary = "#41293a";
            error = "#ffb4ab";
            on_error = "#690005";
            surface = "#131315";
            on_surface = "#e5e1e4";
            surface_variant = "#46464d";
            on_surface_variant = "#c7c5cd";
            outline = "#919097";
            shadow = "#000000";
            hover = "#e1bcd2";
            on_hover = "#41293a";
          };
        };
      };
    };
  };
}
