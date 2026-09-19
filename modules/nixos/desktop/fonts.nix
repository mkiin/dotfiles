{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop.fonts;
in
{
  options.modules.desktop.fonts.enable = lib.mkEnableOption "desktop fonts";

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        nerd-fonts.symbols-only
        nerd-fonts.jetbrains-mono

        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji

        udev-gothic-nf
        biz-ud-gothic
      ];

      enableDefaultPackages = false;

      fontconfig = {
        defaultFonts = {
          serif = [
            "Noto Serif CJK JP"
          ];

          sansSerif = [
            "Noto Sans CJK JP"
            "BIZ UDGothic"
          ];

          monospace = [
            "UDEV Gothic NF"
          ];

          emoji = [
            "Noto Color Emoji"
          ];
        };

        antialias = true;
        hinting.enable = false;
        subpixel.rgba = "rgb";
      };
    };
  };
}
