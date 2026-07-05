{ username }:
{
  "custom/nix#accent" = {
    format = "  ${username}";
    tooltip = false;
    on-click = "qs -c shell ipc call launcher toggle";
  };
  "hyprland/window#island" = {
    format = "{}";
    separate-outputs = true;
    max-length = 40;
  };

  "hyprland/workspaces" = {
    format = "{icon}";
    on-click = "activate";
    show-special = true;
    special-visible-only = true;
    format-icons = {
      "1" = "1";
      "2" = "2";
      "3" = "3";
      "4" = "4";
      "5" = "5";
      special = " ";
    };
    persistent-workspaces = {
      "*" = [
        1
        2
        3
        4
        5
      ];
    };
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
      disabled = "󰂲";
    };
    tooltip-format = "{device_alias}";
    on-click = "qs -c bluetooth -n";
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
    on-click = "qs -c audio -n";
    # クリックはセレクタ起動に一本化し、スクロール音量変更は無効化
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
    interval = 2;
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
      inhibited-notification = "󰂛";
      inhibited-none = "󰪑";
      dnd-inhibited-notification = "󰂛";
      dnd-inhibited-none = "󰪑";
    };
    return-type = "json";
    interval = 2;
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
