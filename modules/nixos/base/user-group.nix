{ pkgs, myvars, ... }:
{

  users.mutableUsers = false;
  users.groups = {
    "${myvars.username}" = { };
    docker = { };
    plugdev = { };
    uinput = { };
    fileshare = { };
  };

  users.users."${myvars.username}" = {
    home = "/home/${myvars.username}";
    isNormalUser = true;
    extraGroups = [
      myvars.username
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
