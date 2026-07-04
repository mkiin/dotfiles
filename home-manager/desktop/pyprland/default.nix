{
  config,
  pkgs,
  dotfilesDir,
  ...
}:
{
  # pypr CLI を keybind / 端末から使うため PATH に入れる。
  home.packages = [ pkgs.pyprland ];

  # 宣言的な単一 config。transition 系は runtime 可変にするため state.env 側に置き、
  # ここには持たせない（command が set.sh 経由で都度読む）。interval は宣言的。
  # pyprland 3.x の推奨パスは ~/.config/pypr/config.toml。~/.config/hypr/pyprland.toml は
  # legacy 扱いで起動時に移行警告が出るため新パスに置く。
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
    active_classes = []
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

  # pypr の初回 command(set.sh→awww img) が失敗しないよう awww-daemon 起動後に開始する。
  # ソケット ready までは After/Requires では保証されないため set.sh 側で待つ。
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
