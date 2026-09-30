{
  lib,
  pkgs,
  ...
}:

{
  systemd.user.services.voicevox-engine = {
    description = "VOICEVOX Engine";

    wantedBy = [ "default.target" ];

    serviceConfig = {
      ExecStart = ''
        ${lib.getExe pkgs.voicevox-engine} \
          --host 127.0.0.1 \
          --port 50021
      '';

      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
