{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nautilus
    ffmpegthumbnailer
  ];

  dconf.settings = {
    "org/gnome/nautilus/window-state".maximized = false;
    "org/gnome/nautilus/compression"."default-compression-format" = "zip";
    "org/gnome/nautilus/preferences" = {
      "fts-enabled" = false;
      "show-delete-permanently" = true;
      "show-image-thumbnails" = "local-only";
    };
  };
}
