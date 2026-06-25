{ pkgs, ... }:

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
    package = pkgs.hyprland;
    xwayland.enable = true;
    systemd.enable = false;
    configType = "hyprlang";

    settings = {
      "$terminal"    = "wezterm";
      "$fileManager" = "wezterm start -- yazi";
      "$browser"     = "zen-browser";
      "$mainMod"     = "SUPER";
    };

    # colors.conf は wallust が動的生成、monitors.conf は mode.sh が動的切替
    # カラートークン ($primary 等) を使う設定は source の後に書く必要があるためここで上書き
    extraConfig = ''
      source = ~/.config/hypr/colors.conf
      source = ~/.config/hypr/monitors.conf

      general {
        col.active_border = $primary $tertiary 45deg
        col.inactive_border = $outline_variant
      }

      group {
        col.border_active = $primary $tertiary 45deg
        col.border_inactive = $outline_variant
        col.border_locked_active = $primary $tertiary 45deg
        col.border_locked_inactive = $outline_variant
      }
    '';
  };
}
