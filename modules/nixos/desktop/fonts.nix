{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.desktop.fonts;

  sfProDmg = pkgs.requireFile {
    name = "SF-Pro.dmg";

    hash = "sha256-loqzuLH5LC2K9h6waA9cIiTE541ZuYa/AEUCp/wBKRg=";

    message = ''
      SF Pro is not distributed by this configuration.

      Download SF-Pro.dmg from:
        https://developer.apple.com/fonts/

      Then add it to the Nix store with:
        nix-store --add-fixed sha256 ~/.local/share/fonts/SF-Pro.dmg
    '';
  };

  sf-pro = pkgs.stdenvNoCC.mkDerivation {
    pname = "sf-pro";
    version = "local";

    src = sfProDmg;

    nativeBuildInputs = with pkgs; [
      p7zip
      cpio
    ];

    dontUnpack = true;

    installPhase = ''
      runHook preInstall

      workdir="$TMPDIR/sf-pro"
      mkdir -p "$workdir"
      cd "$workdir"

      7z x "$src"

      test -f 'Payload~'

      mkdir payload
      cd payload

      cpio -id \
        './Library/Fonts/SF-Pro-Text-*.otf' \
        < ../'Payload~'

      mkdir -p "$out/share/fonts/opentype"

      cp ./Library/Fonts/SF-Pro-Text-*.otf \
        "$out/share/fonts/opentype/"

      runHook postInstall
    '';
  };
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

        inter
        geist-font
        source-sans

        sf-pro
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
