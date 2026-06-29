{ pkgs, username, ... }:
{
  programs.zsh.enable = true;
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
  };
}
