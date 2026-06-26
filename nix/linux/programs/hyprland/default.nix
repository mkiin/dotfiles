{ ... }:

{
  imports = [
    ./appearance.nix
    ./input.nix
    ./autostart.nix
    ./keybinds.nix
    ./rules.nix
    ./monitors.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    xwayland.enable = true;
    systemd.enable = false;
    configType = "lua";

    settings = {
      terminal    = { _var = "wezterm"; };
      fileManager = { _var = "wezterm start -- yazi"; };
      browser     = { _var = "zen-browser"; };
      mainMod     = { _var = "SUPER"; };
    };

    # colors.conf の代替: matugen が colors.lua を生成、これが require する
    # extraLuaFiles に autoLoad = true エントリを置くと home-manager が
    # package.path を自動設定するため、他 extraConfig 内の require() も動く
    extraLuaFiles = {
      "color-scheme" = {
        autoLoad = true;
        content = ''
          local ok, colors = pcall(require, "colors")
          if not ok then return end

          hl.config({
            general = {
              ["col.active_border"]   = { colors = { colors.primary, colors.tertiary }, angle = 45 },
              ["col.inactive_border"] = colors.outline_variant,
            },
            group = {
              ["col.border_active"]         = { colors = { colors.primary, colors.tertiary }, angle = 45 },
              ["col.border_inactive"]        = colors.outline_variant,
              ["col.border_locked_active"]   = { colors = { colors.primary, colors.tertiary }, angle = 45 },
              ["col.border_locked_inactive"] = colors.outline_variant,
            },
          })
        '';
      };
    };

    # monitors.lua は mode.sh が動的生成。package.path は上の extraLuaFiles が設定済み
    extraConfig = ''
      pcall(require, "monitors")
    '';
  };
}
