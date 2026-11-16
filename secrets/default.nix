{
  config,
  inputs,
  lib,
  myvars,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  cfg = config.modules.secrets;
in
{
  imports = [ inputs.agenix.nixosModules.default ];

  options.modules.secrets.desktop.enable = lib.mkEnableOption "desktop secrets";

  config = mkMerge [
    {
      age.identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      age.secrets."user-password" = {
        file = ./user-password.age;
        mode = "0400";
        owner = "root";
      };
    }

    (mkIf cfg.desktop.enable {
      age.secrets = {
        "rclone-r2.conf" = {
          file = ./rclone-r2.conf.age;
          mode = "0400";
          owner = myvars.username;
        };
      };
    })
  ];
}
