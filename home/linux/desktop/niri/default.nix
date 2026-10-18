{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop.niri;
in
{
  options.modules.desktop.niri = {
    enable = lib.mkEnableOption "personal niri configuration";
    effects.enable = lib.mkEnableOption "niri blur, shadows and animations" // {
      default = true;
    };
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra KDL appended to the generated niri config (e.g. host outputs and workspaces).";
    };
    extraBinds = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra KDL lines injected into the single `binds {}` block (e.g. host keybinds).";
    };
  };

  config = lib.mkIf cfg.enable {
    wayland.windowManager.niri = {
      enable = true;
      package = pkgs.niri;
      portalPackage = null;
      systemd.enable = false;
      checkConfig = true;

      extraConfig =
        builtins.readFile ./config.kdl
        + ''
          binds {
          ${builtins.readFile ./binds.kdl}
          ${cfg.extraBinds}
          }
        ''
        + lib.optionalString (!cfg.effects.enable) ''
          layout {
            shadow {
              off
            }
          }
          blur {
            off
          }
          animations {
            off
          }
        ''
        + cfg.extraConfig;
    };
  };
}
