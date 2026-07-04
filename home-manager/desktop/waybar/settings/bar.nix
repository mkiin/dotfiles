{
  layer = "top";
  margin = "10 8 2 8";
  reload_style_on_change = true;

  modules-left = [
    "group/launcher#island"
    "hyprland/window"
  ];
  modules-center = [
    "group/workspaces#island"
    "group/datetime#island"
  ];
  modules-right = [
    "group/sysstats#island"
    "group/status#island"
    "group/control-center#island"
  ];

  "group/launcher#island" = {
    orientation = "horizontal";
    modules = [ "custom/nix" ];
  };
  "group/workspaces#island" = {
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
  "group/sysstats#island" = {
    orientation = "horizontal";
    drawer = {
      transition-duration = 500;
      children-class = "not-cpu";
      transition-left-to-right = false;
    };
    modules = [
      "cpu"
      "temperature"
      "memory"
    ];
  };
  "group/status#island" = {
    orientation = "horizontal";
    modules = [
      "network"
      "bluetooth"
      "pulseaudio"
      "privacy"
      "tray"
    ];
  };
  "group/control-center#island" = {
    orientation = "horizontal";
    modules = [
      "custom/idle_inhibitor"
      "custom/control-center"
      "custom/power"
    ];
  };
}
