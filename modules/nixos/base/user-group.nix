{
  pkgs,
  config,
  myvars,
  ...
}:
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
    hashedPasswordFile = config.age.secrets."user-password".path;
    isNormalUser = true;
    openssh.authorizedKeys.keys = myvars.mainSshAuthorizedKeys;

    extraGroups = [
      myvars.username
      "users"
      "wheel"
      "networkmanager" # for nmtui / nm-connection-editor
      "fileshare"
    ];
  };

  users.defaultUserShell = pkgs.bashInteractive;
  environment.shells = [
    pkgs.bashInteractive
    pkgs.zsh
  ];

}
