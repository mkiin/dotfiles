{
  config,
  inputs,
  lib,
  myvars,
  ...
}:
{
  imports = [ inputs.agenix.nixosModules.default ];

  options.modules.secrets.desktop.enable = lib.mkEnableOption "desktop secrets";

  config = {
    age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    age.secrets."user-password" = {
      file = ./user-password.age;
      mode = "0400";
      owner = "root";
    };

    age.secrets."rclone-r2.conf" = lib.mkIf config.modules.secrets.desktop.enable {
      file = ./rclone-r2.conf.age;
      mode = "0400";
      owner = myvars.username;
    };
  };
}
