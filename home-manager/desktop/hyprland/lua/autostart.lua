hl.on("hyprland.start", function()
  local home = os.getenv("HOME")
  hl.exec_cmd("uwsm app -- fcitx5 -d --replace")
  -- waybar / hypridle / cliphist は home-manager の systemd ユーザーサービスで管理
  -- TODO: wallpaper のロジックはリファクタ予定
  hl.exec_cmd("uwsm app -- " .. home .. "/.config/hypr/scripts/wallpaper/init.sh")
  hl.exec_cmd("uwsm app -- " .. home .. "/.config/hypr/scripts/wallpaper/rotate.sh")
end)
