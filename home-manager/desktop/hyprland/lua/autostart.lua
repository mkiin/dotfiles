-- waybar / hypridle / cliphist / fcitx5 は systemd ユーザーサービスで管理（宣言的）
-- TODO: wallpaper のロジックはリファクタ予定。それまで exec で起動。
hl.on("hyprland.start", function()
  local home = os.getenv("HOME")
  hl.exec_cmd("uwsm app -- " .. home .. "/.config/hypr/scripts/wallpaper/init.sh")
  hl.exec_cmd("uwsm app -- " .. home .. "/.config/hypr/scripts/wallpaper/rotate.sh")
end)
