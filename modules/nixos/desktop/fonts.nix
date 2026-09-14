{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop;
in
{
  options.modules.desktop.fonts.enable = lib.mkEnableOption "desktop fonts";

  config.fonts.packages =
    with pkgs;
    lib.mkIf cfg.fonts.enable [
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono

      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji

      udev-gothic-nf

      biz-ud-gothic
    ];
  fonts = {
    enableDefaultFonts = false;

    fontconfig = {
      defaultFonts = {
        serif = [
          "Noto Serif CJK JP"
        ];

        sansSerif = [
          "BIZ UDGothic"
          "Noto Sans CJK JP"
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
      subpixel.rgba = "rbg";
    };
  };
}
