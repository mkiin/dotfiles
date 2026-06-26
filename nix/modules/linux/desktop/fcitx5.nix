{ config, dotfilesDir, ... }:

let
  sym = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/fcitx5/${path}";
in
{
  home.sessionVariables = {
    XMODIFIERS    = "@im=fcitx";
    INPUT_METHOD  = "fcitx";
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE  = "fcitx";
  };

  xdg.configFile = {
    "fcitx5/config".source              = sym "config";
    "fcitx5/profile".source              = sym "profile";
    "fcitx5/conf/classicui.conf".source = sym "conf/classicui.conf";
    "fcitx5/conf/keyboard.conf".source  = sym "conf/keyboard.conf";
  };
}
