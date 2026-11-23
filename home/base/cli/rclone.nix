{ config, osConfig, ... }:
{
  programs.rclone = {
    enable = true;
    remotes.nextcloud = {
      config = {
        type = "webdav";
        vendor = "nextcloud";
        url = "https://nextcloud.tailb6cf85.ts.net/remote.php/dav/files/${config.home.username}/";
        user = config.home.username;
      };
      secrets.pass = osConfig.security.nix-secrets.secrets.nextcloud-app-password.path;
    };
  };
}
