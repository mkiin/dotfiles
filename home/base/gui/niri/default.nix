{
  config,
  lib,
  osConfig,
  ...
}:
{
  options.modules.desktop.niri.enable = lib.mkEnableOption "personal niri configuration";
  options.modules.desktop.niri.extraBinds = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Host key bindings inside the shared binds block.";
  };
  options.modules.desktop.niri.extraOutputs = lib.mkOption {
    type = lib.types.lines;
    default = "";
    description = "Host output configuration.";
  };
  config = lib.mkIf config.modules.desktop.niri.enable {
    wayland.windowManager.niri = {
      enable = true;
      # NixOS installs the niri-session units and portal backend.
      systemd.enable = false;
      portalPackage = null;
      checkConfig = true;
      settings.input.keyboard.xkb = {
        layout = osConfig.services.xserver.xkb.layout;
        options = "caps:none";
      };
      extraConfig = ''
        include "${./config.kdl}"
      ''
      + builtins.readFile ./rules.kdl
      + config.modules.desktop.niri.extraOutputs
      + "\nbinds {\n"
      + builtins.readFile ./binds.kdl
      + config.modules.desktop.niri.extraBinds
      + "\n}\n";
    };
  };
}
