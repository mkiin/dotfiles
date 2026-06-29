{ lib, lnk, username, ... }:
let
  # config.json は静的 JSON。custom/nix の format に username を連結して
  # ハードコードを排除する (アイコンは config.json 側、ユーザー名は変数)。
  cfg = lib.importJSON ./config.json;
  waybarSettings = cfg // {
    "custom/nix" = cfg."custom/nix" // {
      format = cfg."custom/nix".format + username;
    };
  };
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;            # サービスをモジュール管理
    settings = [ waybarSettings ];
  };

  # style と styles はモジュール管理せず lnk のまま（reload_style_on_change で
  # @import "styles/<theme>.css" の差し替えが switch なしで即反映＝テーマ hot-swap 維持）
  xdg.configFile."waybar/style.css".source = lnk ./style.css;
  xdg.configFile."waybar/styles".source    = lnk ./styles;
  xdg.configFile."waybar/scripts".source   = lnk ./scripts;
}
