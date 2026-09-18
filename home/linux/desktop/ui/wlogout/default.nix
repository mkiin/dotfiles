{
  lib,
  pkgs,
  ...
}:

let
  lockScript = pkgs.writeShellApplication {
    name = "desktop-lock";
    runtimeInputs = [
      pkgs.util-linux # setsid
      pkgs.coreutils # sleep
      pkgs.hyprlock # hyprlock 直接呼ぶ場合
      # pkgs.systemd   # loginctl を呼ぶ場合
    ];
    text = ''
      # wlogout が閉じる入力競合回避のための wait をここに集約
      setsid -f sh -c 'sleep 0.25; hyprlock'

      # ※ loginctl 方式にする場合はこちら:
      # setsid -f sh -c 'sleep 0.25; loginctl lock-session'

      # ※ 将来 quickshell 等に移行する場合はここを差し替えるだけ:
      # quickshell ipc call lock
    '';
  };

  systemctl = "${lib.getExe' pkgs.systemd "systemctl"}";
  uwsm = "${lib.getExe pkgs.uwsm}";
in
{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "${lib.getExe lockScript}";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "suspend";
        action = "${systemctl} suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "reboot";
        action = "${systemctl} reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "${systemctl} poweroff";
        text = "Shutdown";
        keybind = "s";
      }
      {
        label = "logout";
        action = "${uwsm} stop";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "hibernate";
        action = "${systemctl} hibernate";
        text = "Hibernate";
        keybind = "h";
      }
    ];

    # style.css を外部ファイルとして指定
    style = ./style.css;
  };

  xdg.configFile = {
    "wlogout/icons".source = ./icons;
  };
}
