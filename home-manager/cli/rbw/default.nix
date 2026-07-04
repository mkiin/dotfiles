{ pkgs, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "blckcaties@gmail.com";
      pinentry = pkgs.pinentry-curses;
    };
  };
}
