{ username }:
{
  "custom/nix#accent" = {
    format = "  ${username}";
    tooltip = false;
    on-click = "$HOME/.config/rofi/launch.sh";
  };
  "hyprland/window#island" = {
    format = "{}";
    separate-outputs = true;
    max-length = 40;
  };

  "hyprland/workspaces" = {
    format = "{icon}";
    # waybar は旧構文 `dispatch workspace N` を IPC に直書きするため、hyprland 側が
    # configType = "lua" の本環境ではクリックでの WS 切替は機能しない(move-to-monitor も同様)。
    # 切替は SUPER+N / SUPER+I,O に一本化し、waybar は表示専用。
    on-click = "activate";
    show-special = true;
    special-visible-only = true;
    # 運用する 1..5 全部に必要。持たない番号は空文字になり番号を出せない。
    format-icons = {
      "1" = "1";
      "2" = "2";
      "3" = "3";
      "4" = "4";
      "5" = "5";
      special = " ";
    };
    # persistent-workspaces は置かない。WS の所属が固定される運用では、各バーは
    # 自分のモニターに実在する WS だけを出せばよく、他モニターの WS を空ドットで
    # 並べても「存在しない WS」と区別が付かないノイズにしかならない。
  };
  "custom/time" = {
    format = "󰥔 {}";
    exec = "date '+%H:%M'";
    interval = 60;
    tooltip = false;
  };
  "custom/date" = {
    format = "󰸗 {}";
    exec = "date '+%m/%d'";
    interval = 3600;
    tooltip = false;
  };
  "custom/weather" = {
    format = "{}";
    tooltip = true;
    return-type = "json";
    exec = "~/.config/waybar/scripts/weather/weather.sh";
    interval = 900;
  };

  cpu = {
    interval = 10;
    format = "󰻠 {usage}%";
    tooltip = true;
    tooltip-format = "CPU {usage}%  Load {load}";
  };
  memory = {
    interval = 30;
    format = "󰍛 {}%";
    tooltip-format = "{used:0.1f}G/{total:0.1f}G";
  };

  network = {
    format = "{ifname}";
    format-wifi = "󰖩";
    format-ethernet = "󰈀";
    format-disconnected = "";
    tooltip-format = "{ifname} via {gwaddr} 󰌘";
    tooltip-format-wifi = "{essid} ({signalStrength}%) ";
    tooltip-format-ethernet = "{ifname} ";
    tooltip-format-disconnected = "Disconnected";
    max-length = 50;
  };
  bluetooth = {
    format = "{icon}";
    format-icons = {
      enabled = "󰂯";
      off = "󰂲";
      disabled = "󰂲";
    };
    tooltip-format = "{device_alias}";
    on-click = "qs -c shell ipc call bluetooth toggle";
  };
  pulseaudio = {
    format = "{icon} {volume}% {format_source}";
    format-bluetooth = "{icon} 󰂰 {volume}% {format_source}";
    format-muted = "󰝟 {volume}% {format_source}";
    format-source = "󰍬 {volume}%";
    format-source-muted = "󰍭";
    format-icons = {
      headphone = "󰋋";
      hands-free = "󰜟";
      headset = "󰋎";
      default = [
        "󰕿"
        "󰖀"
        "󰕾"
      ];
    };
    on-click = "qs -c shell ipc call audio toggle";
    on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
    scroll-step = 0;
    ignored-sinks = [ "Easy Effects Sink" ];
  };
  tray = {
    icon-size = 21;
    spacing = 10;
    icons = {
      blueman = "bluetooth";
      TelegramDesktop = "$HOME/.local/share/icons/hicolor/16x16/apps/telegram.png";
    };
  };
  "custom/idle_inhibitor" = {
    format = "{}";
    return-type = "json";
    # quickshell 側(shell.qml)が状態変化時に SIGRTMIN+1 を撃つ。ポーリングだと
    # 2 秒ごとに qs を起動して 1 回 88MB 積むため signal 駆動にしている。
    interval = "once";
    signal = 1;
    exec-if = "which qs";
    exec = "qs -c shell ipc call idle status";
    on-click = "qs -c shell ipc call cc toggle";
  };
  "custom/notify" = {
    tooltip = true;
    format = "{icon}";
    format-icons = {
      notification = "󱅫";
      none = "󰂜";
      dnd-notification = "󰂠";
      dnd-none = "󰪓";
    };
    return-type = "json";
    interval = "once";
    signal = 2;
    exec-if = "which qs";
    exec = "qs -c shell ipc call cc status";
    on-click = "qs -c shell ipc call cc toggle";
    escape = true;
  };
  "custom/power#accent" = {
    format = "󰐥";
    tooltip = false;
    on-click = "qs -c shell ipc call cc toggle";
  };
}
