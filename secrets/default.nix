{
  config,
  inputs,
  lib,
  myvars,
  ...
}:
let
  cfg = config.modules.secrets;
in
{
  imports = [ inputs.nix-secrets.nixosModules.default ];

  options.modules.secrets.desktop.enable = lib.mkEnableOption "desktop secrets";

  config.security.nix-secrets = {
    enable = true;
    storage = ./.;
    identityPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # Shared files must keep every authorized host in their recipient list,
    # even when rekeying from another host's configuration.
    recipientAliases = {
      yui = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAzCNRBuxKzxKwXiLagtYVI21a3+vSxY+M7csr2bTEXL";
      yukino = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF71Mzulg4F9wwvfYVlf6r5HcWGFAwyt1ghl1N2p3oQ7";
      iroha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH2zfFjD2OhKxu7xJBYfGl5zkqZg0aLI0aTAqx/iomuR";
      recovery = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEmdC+56O3lS7zmfQXEfFYNbBlQ6GpnxZlC+M6z6SCer";
      desktops = [
        "yui"
        "yukino"
        "recovery"
      ];
      servers = [ "iroha" ];
    };

    secrets = {
      user-password = {
        recipients = [
          "desktops"
          "servers"
        ];
        neededForUsers = true;
        mode = "0400";
      };
      nextcloud-app-password = lib.mkIf cfg.desktop.enable {
        recipients = [ "desktops" ];
        mode = "0400";
        owner = myvars.username;
      };
      "rclone-r2.conf" = lib.mkIf cfg.desktop.enable {
        recipients = [ "desktops" ];
        mode = "0400";
        owner = myvars.username;
      };
    };
  };
}
