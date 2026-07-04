{
  lib,
  lnk,
  username,
  ...
}:
let
  cfg = lib.importJSON ./config.json;
  waybarSettings = cfg // {
    "custom/nix" = cfg."custom/nix" // {
      format = cfg."custom/nix".format + username;
    };
  };
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [ waybarSettings ];
  };
  xdg.configFile."waybar/style.css".source = lnk ./style.css;
  xdg.configFile."waybar/styles".source = lnk ./styles;
  xdg.configFile."waybar/scripts".source = lnk ./scripts;
}
