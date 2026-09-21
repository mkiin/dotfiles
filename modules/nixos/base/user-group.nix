{
  pkgs,
  config,
  myvars,
  ...
}:
{
  programs.zsh.enable = true;
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
    shell = pkgs.zsh;
    hashedPasswordFile = config.age.secrets."user-password".path;
    isNormalUser = true;
    openssh.authorizedKeys.keys = myvars.mainSshAuthorizedKeys;

    extraGroups = [
      myvars.username
      "users"
      "wheel"
      "networkmanager" # for nmtui / nm-connection-editor
      "fileshare"
      "dialout"
    ];
  };

  environment.shells = [
    pkgs.bashInteractive
    pkgs.zsh
  ];

}
