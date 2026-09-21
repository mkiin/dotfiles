{ pkgs, ... }:
{
  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim --clean";
  };

  environment.systemPackages = with pkgs; [
    git
    neovim
    curl
    file
    openssh
    duf
    dust
    btop
    dig
    trash-cli
    zip
    unzip
  ];
}
