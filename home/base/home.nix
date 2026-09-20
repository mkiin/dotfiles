{ pkgs, myvars, ... }:
{
  home = {
    inherit (myvars) username;
    stateVersion = "25.11";

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      SHELL = "${pkgs.zsh}/bin/zsh";

      DELTA_PAGER = "less -R";
    };
  };
}
