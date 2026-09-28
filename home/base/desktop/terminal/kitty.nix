{ ... }:
{
  programs.kitty = {
    enable = true;

    # Fastfetch専用で使うので、zsh全体にはKitty integrationを入れない
    shellIntegration.mode = null;
  };

  xdg.configFile."kitty/fastfetch.conf".text = ''
    # font
    font_family JetBrainsMono Nerd Font
    font_size 14

    # spacing
    window_padding_width 18

    # window
    hide_window_decorations yes
    tab_bar_style hidden

    # background
    background_opacity 0.88

    # cursor
    cursor_shape block
    cursor_blink_interval 0

    # misc
    enable_audio_bell no
    confirm_os_window_close 0
    scrollback_lines 2000
  '';
}
