{
  config,
  # myvars,
  # lib,
  pkgs,
  # wallpaperApply,
  ...
}:
let
  # inherit (myvars) dotfilesdir;
  tomlFormat = pkgs.formats.toml { };
in
{
  home.packages = [ pkgs.pyprland ];

  xdg.configFile."pypr/config.toml".source = tomlFormat.generate "pypr-config" {
    pyprland.plugins = [
      "scratchpads"
      # "wallpapers"
      "toggle_special"
      "lost_windows"
      "fcitx5_switcher"
    ];

    toggle_special.name = "stash";

    fcitx5_switcher.inactive_classes = [
      "org.wezfurlong.wezterm"
      "com.mitchellh.ghostty"
    ];

    scratchpads.fetch = {
      command = "ghostty --class=fetch-scratch -e sh -c 'fastfetch; exec $SHELL'";
      class = "fetch-scratch";
      size = "50% 55%";
      position = "25% 22%";
      animation = "fromTop";
      lazy = true;
      unfocus = "hide";
    };
  };

  systemd.user.services.pyprland = {
    Unit = {
      Description = "pyprland daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
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
