{ lnk, ... }:
{
  home.sessionVariables = {
    XMODIFIERS    = "@im=fcitx";
    INPUT_METHOD  = "fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE  = "fcitx";
  };

  xdg.configFile = {
    "fcitx5/config".source              = lnk ./config;
    "fcitx5/profile".source             = lnk ./profile;
    "fcitx5/conf/classicui.conf".source = lnk ./conf/classicui.conf;
    "fcitx5/conf/keyboard.conf".source  = lnk ./conf/keyboard.conf;
  };
}
