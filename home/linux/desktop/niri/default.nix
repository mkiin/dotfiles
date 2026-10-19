{ config, lib, ... }:
{
  options.modules.desktop.niri.enable = lib.mkEnableOption "personal niri configuration";
  options.modules.desktop.niri.extraBinds = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Host key bindings inside the shared binds block.";
  };
  config = lib.mkIf config.modules.desktop.niri.enable {
    wayland.windowManager.niri = {
      enable = true;
      # NixOS installs the niri-session units and portal backend.
      systemd.enable = false;
      portalPackage = null;
      checkConfig = true;
      extraConfig =
        builtins.readFile ./config.kdl
        + builtins.readFile ./rules.kdl
        + "\nbinds {\n"
        + builtins.readFile ./binds.kdl
        + config.modules.desktop.niri.extraBinds
        + "\n}\n";
    };
  };
}
