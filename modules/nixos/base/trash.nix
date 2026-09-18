{
  config,
  myvars,
  pkgs,
  ...
}:
let
  retentionDays = 30;
  username = myvars.username;
  homeDirectory = config.users.users.${username}.home;
in
{
  systemd.services.trash-empty = {
    description = "Purge trash items older than ${toString retentionDays} days";

    after = [ "local-fs.target" ];
    requiresMountsFor = [ homeDirectory ];

    environment = {
      HOME = homeDirectory;
      XDG_DATA_HOME = "${homeDirectory}/.local/share";
    };

    serviceConfig = {
      Type = "oneshot";
      User = username;
      ExecStart = "${pkgs.trash-cli}/bin/trash-empty ${toString retentionDays} -f";
    };
  };

  systemd.timers.trash-empty = {
    description = "Daily trash retention cleanup";
    wantedBy = [ "timers.target" ];

    timerConfig = {
      OnCalendar = "daily";
      RandomizedDelaySec = "15min";
      Persistent = true;
    };
  };
}
