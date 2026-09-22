{ inputs, ... }:
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      # バーは Waybar を使う
      bar.default.enabled = false;

      # 既存の壁紙管理を使う
      wallpaper.enabled = false;
    };
  };
}
