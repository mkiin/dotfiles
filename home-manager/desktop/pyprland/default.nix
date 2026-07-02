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
  xdg.configFile."hypr/pyprland.toml".text = ''
    [pyprland]
    plugins = ["wallpapers"]

    [wallpapers]
    path = "${dotfilesDir}/images/wallpaper"
    interval = 30
    extensions = ["jpg", "jpeg", "png", "webp"]
    command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/set.sh [file]"
    post_command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/post.sh [file]"
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
