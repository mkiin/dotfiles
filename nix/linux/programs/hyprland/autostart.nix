{ ... }:

{
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      local home = os.getenv("HOME")
      hl.exec_cmd("uwsm app -- fcitx5 -d --replace")
      hl.exec_cmd("uwsm app -- waybar")
      hl.exec_cmd("uwsm app -- hypridle")
      hl.exec_cmd("uwsm app -- " .. home .. "/.config/hypr/scripts/wallpaper/init.sh")
      hl.exec_cmd("uwsm app -- " .. home .. "/.config/hypr/scripts/wallpaper/rotate.sh")
      hl.exec_cmd("uwsm app -- wl-paste --type text --watch cliphist store")
      hl.exec_cmd("uwsm app -- wl-paste --type image --watch cliphist store")
    end)
  '';
}
