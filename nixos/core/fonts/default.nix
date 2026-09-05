{ lib, pkgs, ... }:
{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-serif
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    udev-gothic
    dejavu_fonts
    inter
    material-design-icons
  ];
  fonts.fontconfig.defaultFonts = {
    serif = [
      "Noto Serif CJK JP"
      "Noto Color Emoji"
    ];
    sansSerif = [
      "Noto Sans CJK JP"
      "Noto Color Emoji"
    ];
    monospace = [
      "JetBrainsMono Nerd Font"
      "Noto Color Emoji"
    ];
    emoji = [ "Noto Color Emoji" ];
  };

  # 未インストールの Web 定番フォント名は fontconfig のフォールバックが
  # Noto Sans CJK KR / Noto Sans Arabic UI 等を先頭に返し、Firefox 系で
  # 太字欧文が潰れる(ChatGPT の "Segoe UI" 指定で実害)。明示 alias で流す。
  fonts.fontconfig.localConf = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      ${lib.concatMapStrings
        (family: ''
          <alias>
            <family>${family}</family>
            <prefer>
              <family>Inter</family>
              <family>Noto Sans CJK JP</family>
            </prefer>
          </alias>
        '')
        [
          "Segoe UI"
          "Helvetica Neue"
          "Arial"
          "Roboto"
          "SF Pro Text"
          "SF Pro Display"
        ]
      }
    </fontconfig>
  '';
}
