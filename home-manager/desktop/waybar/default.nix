{
  lnk,
  lib,
  pkgs,
  username,
  ...
}:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [
      (import ./bar.nix // import ./modules.nix { inherit username; })
    ];
  };
  xdg.configFile."waybar/scripts".source = lnk ./scripts;

  # style.css は reload-css.sh が O_TRUNC で書き直して reload_style_on_change を
  # 発火させるため、store への symlink ではなく書き込み可能な実ファイルとして配布する。
  # 情報源は style.nix のまま。switch のたびに上書きされ手編集は残らない。
  home.activation.waybarStyle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/waybar/style.css"
    $DRY_RUN_CMD rm -f "$t"
    $DRY_RUN_CMD install -Dm644 ${pkgs.writeText "waybar-style.css" (import ./style.nix)} "$t"
  '';
}
