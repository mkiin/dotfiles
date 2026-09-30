{ pkgs, ... }:
let
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  themeFile = if isDarwin then "themes/wallust.conf" else "themes/noctalia.conf";
in
{
  programs.kitty = {
    enable = true;

    settings = {
      font_family = "JetBrains Mono Nerd Font";
      font_size = 14.0;
      window_margin_width = 21.75;
      background_opacity = 0.9;
      cursor_shape = "beam";
      cursor_trail = 1;
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      scrollback_lines = 20000;
    };

    keybindings = {
      "ctrl+c" = "copy_or_interrupt";

      "page_up" = "scroll_page_up";
      "page_down" = "scroll_page_down";

      "ctrl+plus" = "change_font_size all +1";
      "ctrl+equal" = "change_font_size all +1";
      "ctrl+minus" = "change_font_size all -1";
      "ctrl+0" = "change_font_size all 0";
    };

    extraConfig = ''
      include ${themeFile}
    '';
  };
}
