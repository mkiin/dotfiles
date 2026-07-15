{ pkgs, config, ... }:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc-ut
      fcitx5-gtk
    ];
  };

  # IME デーモンを宣言的に起動（addons 付きの i18n.inputMethod.package を使用）
  systemd.user.services.fcitx5 = {
    description = "Fcitx5 input method daemon";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${config.i18n.inputMethod.package}/bin/fcitx5";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
