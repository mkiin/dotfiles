{ lnk, ... }:
{
  home.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
  };

  # fcitx5 同梱の D-Bus サービスは SystemdService= を持たないため、アプリが
  # org.fcitx.Fcitx5 を呼ぶと dbus-daemon が graphical-session の環境を持たない
  # インスタンスを直接起動して D-Bus 名を奪い、fcitx5.service が起動不能になる。
  # XDG_DATA_HOME 側で上書きして activation を systemd に委譲する。
  xdg.dataFile."dbus-1/services/org.fcitx.Fcitx5.service".text = ''
    [D-BUS Service]
    Name=org.fcitx.Fcitx5
    Exec=/run/current-system/sw/bin/fcitx5
    SystemdService=fcitx5.service
  '';

  xdg.configFile = {
    "fcitx5/config".source = lnk ./config;
    "fcitx5/profile".source = lnk ./profile;
    "fcitx5/conf/classicui.conf".source = lnk ./conf/classicui.conf;
    "fcitx5/conf/keyboard.conf".source = lnk ./conf/keyboard.conf;
  };
}
