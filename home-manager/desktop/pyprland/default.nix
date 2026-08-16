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
      "scratchpads",
      "wallpapers",
      "workspaces_follow_focus",
      "toggle_special",
      "lost_windows",
      "fcitx5_switcher",
    ]

    [wallpapers]
    path = "${dotfilesDir}/images/wallpaper"
    interval = 30
    extensions = ["jpg", "jpeg", "png", "webp"]
    command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/apply.sh [file]"

    # WS は 1..10 運用なので巡回上限を合わせる。
    [workspaces_follow_focus]
    max_workspaces = 10

    # native special:magic と衝突しない退避先。SHIFT+S の退避/復帰(往復)に使う。
    [toggle_special]
    name = "stash"

    [fcitx5_switcher]
    inactive_classes = ["org.wezfurlong.wezterm", "com.mitchellh.ghostty"]

    # fetch 用は行儀のよい単一 wezterm ウィンドウなので scratchpads を採用。
    # vesktop(Electron 単一インスタンス)は窓追跡が不安定なため引き続き除外。
    [scratchpads.fetch]
    command = "wezterm start --class fetch-scratch -- sh -c 'fastfetch; exec $SHELL'"
    class = "fetch-scratch"
    size = "50% 55%"
    position = "25% 22%"
    animation = "fromTop"
    lazy = true
    unfocus = "hide"
  '';

  systemd.user.services.awww-daemon = {
    Unit = {
      Description = "awww wallpaper daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # キャッシュ復元は apply.sh を通らない隠れた書き手になるため無効化。
      # 起動時の壁紙は pyprland のランダム1枚が正(spec 参照)。
      ExecStart = "${pkgs.awww}/bin/awww-daemon --no-cache";
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
