{
  layer = "top";
  margin = "10 10 2 10";
  height = 34;
  reload_style_on_change = true;

  modules-left = [
    "group/launcher#island"
    "hyprland/window#island"
  ];
  modules-center = [
    "group/ws#island"
    "group/datetime#island"
  ];
  modules-right = [
    "group/status#island"
    "group/control-center#island"
  ];

  "group/launcher#island" = {
    orientation = "horizontal";
    modules = [ "custom/nix#accent" ];
  };
  "group/ws#island" = {
    orientation = "horizontal";
    modules = [ "hyprland/workspaces" ];
  };
  "group/datetime#island" = {
    orientation = "horizontal";
    modules = [
      "custom/time"
      "custom/date"
      "custom/weather"
    ];
  };
  # status 島は「情報 (cpu/memory) | 接続と音 | tray」の 3 区画。境界線は CSS 側
  "group/status#island" = {
    orientation = "horizontal";
    modules = [
      "cpu"
      "memory"
      "network"
      "bluetooth"
      "pulseaudio"
      "tray"
    ];
  };
  "group/control-center#island" = {
    orientation = "horizontal";
    modules = [
      "custom/idle_inhibitor"
      "custom/notify"
      "custom/power#accent"
    ];
  };
}
