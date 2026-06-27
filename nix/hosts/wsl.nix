{ lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    unzip
    zip
  ];

  programs.zsh = {
    shellAliases = {
      open = "explorer.exe .";
    };

    initContent = lib.mkAfter ''
      if [[ -o interactive && -n "''${WSL_DISTRO_NAME:-}" && "$PWD" == /mnt/[a-zA-Z]/* ]]; then
        cd "$HOME"
      fi
    '';
  };
}
