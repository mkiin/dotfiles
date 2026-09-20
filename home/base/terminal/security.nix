{ pkgs, myvars, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "${myvars.useremail}";
      pinentry = pkgs.pinentry-curses;
    };
  };
}
