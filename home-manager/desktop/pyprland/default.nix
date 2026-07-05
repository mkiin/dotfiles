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

    # scratchpads プラグインは見送り。vesktop(Electron 単一インスタンス)の窓追跡が
    # 安定せず、手動スライドが Hyprland のアニメとも衝突するため。

    # ゲーム class は switch 後に hyprctl clients で採取して追加する(Task 4)。
    [fcitx5_switcher]
    active_classes = ["zen-beta"]
    inactive_classes = ["org.wezfurlong.wezterm"]
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
      # config.toml だけ変わっても unit は不変で switch 時に再起動されないため、
      # 生成した config を再起動トリガに含めて設定変更を確実に反映させる。
      X-Restart-Triggers = [ config.xdg.configFile."pypr/config.toml".source ];
    };
    Service = {
      ExecStart = "${pkgs.pyprland}/bin/pypr";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
