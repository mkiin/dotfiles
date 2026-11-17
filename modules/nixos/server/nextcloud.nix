{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.nextcloud;
in
{
  config = lib.mkIf cfg.enable {
    services.nextcloud = {
      package = pkgs.nextcloud35;
      https = true;
      config.dbtype = "pgsql";
      database.createLocally = true;
      configureRedis = true;
      settings = {
        trusted_proxies = [ "127.0.0.1" ];
        "overwrite.cli.url" = "https://${cfg.hostName}";
      };
    };

    services.nginx.virtualHosts.${cfg.hostName}.listen = [
      {
        addr = "127.0.0.1";
        port = 8080;
      }
    ];

    services.caddy = {
      enable = true;
      virtualHosts.${cfg.hostName}.extraConfig = ''
        tls internal
        reverse_proxy 127.0.0.1:8080
      '';
    };
  };
}
