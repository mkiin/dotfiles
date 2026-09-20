{ pkgs, ... }:
{
  home.pointerCursor = {
    enable = true;

    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 24;

    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;

    font = {
      name = "Noto Sans";
      package = pkgs.noto-fonts;
      size = 11;
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };

    colorScheme = "dark";
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };
}
