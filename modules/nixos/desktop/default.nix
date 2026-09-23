{
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
    services.displayManager.noctalia-greeter = {
      enable = true;
      settings = {
        session.default = "Hyprland (uwsm-managed)";
        user.default = myvars.username;
        keyboard.layout = "us";
      };
    };
  };
}
