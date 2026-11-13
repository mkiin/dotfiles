{
  config,
  lib,
  pkgs,
  ...
}:

let
  dwproton = pkgs.callPackage ./dwproton.nix { };
  nikkeHome = "${config.xdg.dataHome}/nikke";
  prefix = "${nikkeHome}/prefix";
  installer = "${nikkeHome}/installer/nikke-installer.exe";
  launcher = "${prefix}/drive_c/NIKKE/Launcher/nikke_launcher.exe";

  ldconfigReal = pkgs.runCommand "nikke-ldconfig-real" { } ''
    mkdir -p "$out/bin"
    ln -s ${lib.getBin pkgs.pkgsi686Linux.glibc}/bin/ldconfig "$out/bin/ldconfig.real"
  '';
  umu = pkgs.umu-launcher.override {
    # Preserve the FHS ldconfig wrapper and let pressure-vessel inspect its ELF target.
    extraProfile = ''
      export PATH="${
        lib.makeBinPath [
          pkgs.getent
          ldconfigReal
        ]
      }:$PATH"
    '';
  };

  environment = [
    "GAMEID=umu-nikke"
    "PROTON_USE_WOW64=1"
    "UMU_RUNTIME_UPDATE=0"
    "PROTONPATH=${dwproton}"
    "WINEPREFIX=${prefix}"
    "PROTON_NO_FSYNC=1"
    "PROTON_NO_ESYNC=1"
  ];

  service = {
    Type = "exec";
    ExitType = "cgroup";
    KillMode = "control-group";
    TimeoutStopSec = 5;
    Restart = "no";
    WorkingDirectory = config.home.homeDirectory;
    Environment = environment;
    StandardOutput = "journal";
    StandardError = "journal";
  };

  exec =
    executable:
    lib.concatStringsSep " " [
      "${pkgs.steam.run}/bin/steam-run"
      "${umu}/bin/umu-run"
      ''"${executable}"''
    ];
in
{
  systemd.user.tmpfiles.rules = [
    "d ${lib.escapeShellArg nikkeHome} 0700 - - -"
    "d ${lib.escapeShellArg "${nikkeHome}/installer"} 0700 - - -"
  ];

  systemd.user.services.nikke = {
    Unit = {
      Description = "Goddess of Victory: NIKKE";
      PartOf = [ "graphical-session.target" ];
      After = [
        "graphical-session.target"
        "nikke-install.service"
      ];
      Conflicts = [ "nikke-install.service" ];
    };
    Service = service // {
      ExecStart = exec launcher;
    };
  };

  systemd.user.services.nikke-install = {
    Unit = {
      Description = "Install the NIKKE launcher";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      Conflicts = [ "nikke.service" ];
    };
    Service = service // {
      Environment = environment ++ [ "PROTON_VERB=run" ];
      ExecStartPre = ''${pkgs.coreutils}/bin/test -f "${installer}"'';
      ExecStart = exec installer;
    };
  };

  xdg.desktopEntries.nikke = {
    name = "NIKKE";
    genericName = "Goddess of Victory: NIKKE";
    exec = "${pkgs.systemd}/bin/systemctl --user start nikke.service";
    icon = "${./assets/nikke.png}";
    terminal = false;
    categories = [ "Game" ];
  };
}
