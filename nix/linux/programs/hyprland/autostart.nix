{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "uwsm app -- fcitx5 -d --replace"
      "uwsm app -- waybar"
      "uwsm app -- hypridle"
      "uwsm app -- $HOME/.config/hypr/scripts/wallpaper/init.sh"
      "uwsm app -- $HOME/.config/hypr/scripts/wallpaper/rotate.sh"
      "uwsm app -- wl-paste --type text --watch cliphist store"
      "uwsm app -- wl-paste --type image --watch cliphist store"
    ];
  };
}
