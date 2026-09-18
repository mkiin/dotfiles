{
  pkgs,
  config,
  lib,
  myvars,
  mylib,
  ...
}:
let
  cfg = config.modules.desktop.wayland;
in
{
  options.modules.desktop.wayland.enable = lib.mkEnableOption "Wayland Display Server";
  imports = mylib.scanPaths ./. ++ [ ../base ];

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          user = myvars.username;
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd $HOME/.wayland-session";
        };
      };
    };
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };
  };

}
