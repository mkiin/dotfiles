{
  config,
  pkgs,
  dotfilesDir,
  ...
}:
{
  xdg.configFile."pypr/config.toml".text = ''
    [pyprland]
    plugins = [
      "wallpapers",
      "workspaces_follow_focus",
      "scratchpads",
      "toggle_special",
      "lost_windows",
      "fcitx5_switcher",
    ]

    [wallpapers]
    path = "${dotfilesDir}/images/wallpaper"
    interval = 30
    extensions = ["jpg", "jpeg", "png", "webp"]
    command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/set.sh [file]"
    post_command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/post.sh [file]"

    # WS は 1..10 運用なので巡回上限を合わせる。
    [workspaces_follow_focus]
    max_workspaces = 10

    # native special:magic と衝突しない退避先。
    [toggle_special]
    name = "stash"

    # match_by="class": wezterm は mux 接続で PID 追跡が外れうるため class 一致で追う。
    [scratchpads.term]
    command = "wezterm start --class scratch-term"
    class = "scratch-term"
    match_by = "class"
    size = "60% 60%"
    position = "20% 5%"
    lazy = true

    [scratchpads.btop]
    command = "wezterm start --class scratch-btop -- btop"
    class = "scratch-btop"
    match_by = "class"
    size = "70% 70%"
    position = "15% 5%"
    lazy = true

    [scratchpads.vesktop]
    command = "vesktop"
    class = "vesktop"
    match_by = "class"
    size = "60% 70%"
    position = "20% 5%"
    lazy = true

    # ゲーム class は switch 後に hyprctl clients で採取して追加する(Task 4)。
    [fcitx5_switcher]
    active_classes = ["zen-beta"]
    inactive_classes = ["scratch-term", "scratch-btop", "org.wezfurlong.wezterm"]
    active_titles = []
    inactive_titles = []
  '';

  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.pyprland = {
    Unit = {
      Description = "pyprland daemon (wallpapers plugin)";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "awww-daemon.service"
      ];
      Requires = [ "awww-daemon.service" ];
    };
    Service = {
      ExecStart = "${pkgs.pyprland}/bin/pypr";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
