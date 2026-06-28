{ lib, pkgs, ... }:
{
  imports = [ ../../home-manager ];

  home.packages = with pkgs; [ unzip zip ];

  programs.zsh.shellAliases.open = "explorer.exe .";
  programs.zsh.initContent = lib.mkAfter ''
    if [[ -o interactive && -n "''${WSL_DISTRO_NAME:-}" && "$PWD" == /mnt/[a-zA-Z]/* ]]; then
      cd "$HOME"
    fi
  '';
}
