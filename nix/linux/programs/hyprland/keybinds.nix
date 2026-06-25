{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    bind = [
      # モニターモード切替
      "$mainMod SHIFT, D, exec, ~/.config/hypr/scripts/mode.sh desk"
      "$mainMod SHIFT, B, exec, ~/.config/hypr/scripts/mode.sh bed"
      # アプリ起動
      "$mainMod, G, exec, $terminal"
      "$mainMod, C, killactive,"
      "$mainMod, E, exec, $fileManager"
      "$mainMod, B, exec, $browser"
      "$mainMod, A, exec, qs -c shell ipc call launcher toggle"
      "$mainMod, N, exec, qs -c shell ipc call cc toggle"
      "$mainMod, Q, exec, pkill -x wlogout || wlogout"
      # スクリーンショット
      "$mainMod, P, exec, ~/.config/hypr/scripts/screenshot.sh region"
      "$mainMod SHIFT, P, exec, ~/.config/hypr/scripts/screenshot.sh window"
      "$mainMod CTRL, P, exec, ~/.config/hypr/scripts/screenshot.sh output"
      # 画面録画
      "$mainMod, R, exec, ~/.config/hypr/scripts/record.sh"
      "$mainMod CTRL, R, exec, ~/.config/hypr/scripts/record.sh ~/personal/tools/facefusion/media/target"
      # ウインドウ操作
      "$mainMod, V, togglefloating,"
      "$mainMod, F, fullscreen, 0"
      "$mainMod, T, layoutmsg, togglesplit"
      # フォーカス移動
      "$mainMod, H, movefocus, l"
      "$mainMod, J, movefocus, d"
      "$mainMod, K, movefocus, u"
      "$mainMod, L, movefocus, r"
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"
      # ウインドウ移動
      "$mainMod SHIFT, H, movewindow, l"
      "$mainMod SHIFT, J, movewindow, d"
      "$mainMod SHIFT, K, movewindow, u"
      "$mainMod SHIFT, L, movewindow, r"
      # ワークスペース前後移動
      "$mainMod, I, workspace, e-1"
      "$mainMod, O, workspace, e+1"
      "$mainMod SHIFT, I, movetoworkspace, e-1"
      "$mainMod SHIFT, O, movetoworkspace, e+1"
      # ワークスペース切替
      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"
      # ウインドウをワークスペースに移動
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"
      # スペシャルワークスペース
      "$mainMod, S, togglespecialworkspace, magic"
      "$mainMod SHIFT, S, movetoworkspace, special:magic"
      # マウス
      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"
    ];

    binde = [
      # ウインドウリサイズ
      "$mainMod CTRL, H, resizeactive, -30 0"
      "$mainMod CTRL, J, resizeactive, 0 30"
      "$mainMod CTRL, K, resizeactive, 0 -30"
      "$mainMod CTRL, L, resizeactive, 30 0"
    ];

    bindel = [
      # メディアキー
      ", XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ", XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
      ", XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
    ];

    bindl = [
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
    ];

    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];
  };
}
