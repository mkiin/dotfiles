{ pkgs, vars, ... }:
{
  programs.rbw.rbw = {
    enable = true;
    settings = {
      email = "${vars.useremail}";
      pinentry = pkgs.pinentry-curses;
    };
  };
}
