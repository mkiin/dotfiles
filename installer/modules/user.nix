{ lib, ... }:
let
  hashFile = ../initial-password-hash;
  hash =
    if builtins.pathExists hashFile then lib.removeSuffix "\n" (builtins.readFile hashFile) else "!";
in
{
  assertions = [
    {
      assertion = lib.hasPrefix "$y$" hash || lib.hasPrefix "$6$" hash;
      message = "Create installer/initial-password-hash with mkpasswd before building the installer; git add it when using a Git flake.";
    }
  ];
  users.mutableUsers = false;
  users.users.mkiin = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/mkiin";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    initialHashedPassword = hash;
  };
}
