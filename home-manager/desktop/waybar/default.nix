{ lib, lnk, ... }:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;            # サービスをモジュール管理
    settings = [ (lib.importJSON ./config.json) ];
  };

  # style と styles はモジュール管理せず lnk のまま（reload_style_on_change で
  # @import "styles/<theme>.css" の差し替えが switch なしで即反映＝テーマ hot-swap 維持）
  xdg.configFile."waybar/style.css".source = lnk ./style.css;
  xdg.configFile."waybar/styles".source    = lnk ./styles;
  xdg.configFile."waybar/scripts".source   = lnk ./scripts;
}
