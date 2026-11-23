{ config, lib, ... }:
let
  cfg = config.services.vaultwarden;
in
{
  options.services.vaultwarden.host = lib.mkOption {
    type = lib.types.str;
    description = "Name of the host running Vaultwarden.";
  };

  config = lib.mkIf cfg.enable {
    services.vaultwarden = {
      backupDir = "/var/backup/vaultwarden";
      config = {
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = 8222;
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = false;
      };
    };
  };
}
