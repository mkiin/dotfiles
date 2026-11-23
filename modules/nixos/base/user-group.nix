{
  pkgs,
  config,
  myvars,
  options,
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
    hashedPasswordFile =
      if options.security ? nix-secrets then
        config.security.nix-secrets.secrets.user-password.path
      else
        null;
    isNormalUser = true;

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
