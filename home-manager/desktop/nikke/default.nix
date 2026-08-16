_: {
  # rofi(drun)から起動するためのショートカット。実体は packages.nix の nikke ラッパー。
  # アイコンはランチャー exe から抽出した同梱 PNG(store へ焼き込み)。
  xdg.desktopEntries.nikke = {
    name = "NIKKE";
    genericName = "Goddess of Victory: NIKKE";
    exec = "nikke";
    icon = "${./nikke.png}";
    terminal = false;
    categories = [ "Game" ];
  };
}
