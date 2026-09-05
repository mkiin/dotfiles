{
  lnk,
  lib,
  ...
}:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  xdg.configFile."waybar/config.jsonc".source = lnk ./config.jsonc;
  xdg.configFile."waybar/scripts".source = lnk ./scripts;

  # reload-css.sh が O_TRUNC で書き直すため symlink ではなく実ファイルで配る
  home.activation.waybarStyle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/waybar/style.css"
    $DRY_RUN_CMD rm -f "$t"
    $DRY_RUN_CMD install -Dm644 ${./style.css} "$t"
  '';
}
