{
  inputs,
  pkgs,
  myvars,
  ...
}:
let
  cfg = inputs.self.lib.vaultwarden;
in
{
  programs.rbw = {
    enable = true;
    settings = {
      base_url = "https://${cfg.domain}";
      email = "${myvars.useremail}";
      pinentry = pkgs.pinentry-curses;
    };
  };
  home.packages = [ pkgs.bitwarden-cli ];
}
