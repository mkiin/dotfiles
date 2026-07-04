{
  lnk,
  username,
  ...
}:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [
      (import ./settings/bar.nix // import ./settings/modules.nix { inherit username; })
    ];
  };
  xdg.configFile."waybar/style.css".source = lnk ./style.css;
  xdg.configFile."waybar/styles".source = lnk ./styles;
  xdg.configFile."waybar/scripts".source = lnk ./scripts;
}
