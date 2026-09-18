{
  pkgs,
  ...
}:

let
  dateCmd = "${pkgs.coreutils}/bin/date";
in
{
  programs.hyprlock = {
    enable = true;

    extraConfig = ''
      # ============================================================
      # Colors (wallust / matugen 配線先、またはフォールバック)
      # ============================================================
      source = ~/.config/hyprlock/colors.conf

      $font = JetBrainsMono Nerd Font

      general {
          hide_cursor = true
          grace = 0
          ignore_empty_input = true
      }

      # ============================================================
      # Background (動的生成confを廃止し、固定のキャッシュパスを参照)
      # ============================================================
      background {
          monitor =
          path = ~/.cache/current_wallpaper
          blur_passes = 0
      }

      # ============================================================
      # Widgets
      # ============================================================
      # Clock
      label {
          monitor =
          text = $TIME
          color = $lock_accent
          font_size = 90
          font_family = $font
          position = 56, -110
          halign = left
          valign = top
          zindex = 10
          shadow_passes = 2
          shadow_size = 3
          shadow_color = rgba(0, 0, 0, 0.45)
      }

      # Divider
      shape {
          monitor =
          size = 340, 2
          color = $lock_rule
          rounding = 0
          border_size = 0
          position = 56, -265
          halign = left
          valign = top
          zindex = 10
      }

      # Date
      label {
          monitor =
          text = cmd[update:60000] echo "<b>$(${dateCmd} +'%A, %B %-d')</b>"
          color = $lock_date
          font_size = 20
          font_family = JetBrainsMono Nerd Font Propo
          position = 56, -295
          halign = left
          valign = top
          zindex = 10
          shadow_passes = 1
          shadow_size = 2
          shadow_color = rgba(0, 0, 0, 0.45)
      }

      # Input field
      input-field {
          monitor =
          size = 260, 44
          outline_thickness = 1
          dots_size = 0.25
          dots_spacing = 0.3
          dots_center = true
          rounding = 22
          outer_color = $lock_accent
          inner_color = rgba(0, 0, 0, 0.35)
          font_color = $lock_input_text
          fade_on_empty = true
          fade_timeout = 1000
          font_family = $font
          placeholder_text = <i>Enter password...</i>
          hide_input = false
          check_color = $lock_accent
          fail_color = $lock_fail
          fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
          position = 0, -40
          halign = center
          valign = center
          zindex = 20
      }
    '';
  };

  # hypr ではなく hyprlock ディレクトリにフォールバック色を配置
  xdg.configFile."hyprlock/colors.conf".source = ./colors.conf;
}
