{ pkgs, myvars, ... }:
{
  programs.rbw.rbw = {
    enable = true;
    settings = {
      email = "${myvars.useremail}";
      pinentry = pkgs.pinentry-curses;
    };
  };
}
