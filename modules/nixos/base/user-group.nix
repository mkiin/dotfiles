{ pkgs, vars, ... }:
{

  users.mutableUsers = false;
  users.groups = {
    "${vars.username}" = { };
    docker = { };
    plugdev = { };
    uinput = { };
    fileshare = { };
  };

  users.users."${vars.username}" = {
    home = "/home/${vars.username}";
    isNormalUser = true;
    extraGroups = [
      vars.username
      "users"
      "wheel"
      "networkmanager" # for nmtui / nm-connection-editor
      "fileshare"
    ];
  };

  users.defaultUserShell = pkgs.bashInteractive;
  environment.shell = with pkgs; [
    bashInteractive
  ];
}
