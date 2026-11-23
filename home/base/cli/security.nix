{ pkgs, myvars, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      base_url = "https://vaultwarden.tailb6cf85.ts.net";
      email = "${myvars.useremail}";
      pinentry = pkgs.pinentry-curses;
    };
  };
  home.packages = [ pkgs.bitwarden-cli ];
}
