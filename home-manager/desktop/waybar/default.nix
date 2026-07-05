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
      (import ./bar.nix // import ./modules.nix { inherit username; })
    ];
    style = import ./style.nix;
  };
  xdg.configFile."waybar/scripts".source = lnk ./scripts;
}
