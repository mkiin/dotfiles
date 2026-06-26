{ config, dotfilesDir, ... }:

let
  home = config.home.homeDirectory;
  sym  = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/local/${path}";
in
{
  xdg.desktopEntries = {
    discord = {
      name        = "Discord";
      exec        = "env XMODIFIERS=@im=fcitx GTK_IM_MODULE=fcitx QT_IM_MODULE=fcitx /usr/bin/discord --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime --wayland-text-input-version=3";
      icon        = "discord";
      comment     = "All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.";
      genericName = "Internet Messenger";
      categories  = [ "Network" "InstantMessaging" ];
      settings = {
        StartupWMClass = "discord";
        Path           = "/usr/bin";
      };
    };

    nikke = {
      name       = "NIKKE";
      exec       = "${home}/.local/bin/nikke-launch.sh";
      icon       = "${home}/.local/share/icons/nikke.png";
      comment    = "GODDESS OF VICTORY: NIKKE";
      categories = [ "Game" ];
      settings = {
        Keywords       = "nike;nikke;goddess;victory;gov;勝利の女神;";
        Terminal       = "false";
        StartupWMClass = "nikke_launcher.exe";
      };
    };
  };

  home.file = {
    ".local/bin/nikke-launch.sh".source    = sym "bin/nikke-launch.sh";
    ".local/share/icons/nikke.png".source  = sym "share/icons/nikke.png";
  };
}
