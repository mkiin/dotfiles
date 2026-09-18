{
  lib,
  pkgs,
  dotfilesDir,
  wallpaperApply,
  ...
}:
let
  tomlFormat = pkgs.formats.toml { };
in
{
  xdg.configFile."pypr/config.toml".source = tomlFormat.generate "pypr-config" {
    pyprland.plugins = [
      "scratchpads"
      "wallpapers"
      "toggle_special"
      "lost_windows"
      "fcitx5_switcher"
    ];

    wallpapers = {
      path = "${dotfilesDir}/images/wallpaper";
      interval = 30;
      extensions = [
        "jpg"
        "jpeg"
        "png"
        "webp"
      ];
      # ※ 先ほどのリファクタリングに合わせてパスを調整
      command = "${lib.getExe wallpaperApply} [file]";
    };

    toggle_special.name = "stash";

    fcitx5_switcher.inactive_classes = [
      "org.wezfurlong.wezterm"
      "com.mitchellh.ghostty"
    ];

    scratchpads.fetch = {
      command = "wezterm start --class fetch-scratch -- sh -c 'fastfetch; exec $SHELL'";
      class = "fetch-scratch";
      size = "50% 55%";
      position = "25% 22%";
      animation = "fromTop";
      lazy = true;
      unfocus = "hide";
    };
  };

  # ... (systemd サービスはそのまま)
}
