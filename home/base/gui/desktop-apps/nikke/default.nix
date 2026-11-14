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

  umu = pkgs.umu-launcher.override {
    extraPkgs = p: [
      p.getent
      # Preserve the FHS ldconfig wrapper and expose its ELF target for inspection.
      (p.linkFarm "nikke-ldconfig-real" [
        {
          name = "bin/ldconfig.real";
          path = "${p.pkgsi686Linux.glibc.bin}/bin/ldconfig";
        }
      ])
    ];
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

  preLaunchConfig = {
    Type = "exec";
    ExitType = "cgroup";
    KillMode = "control-group";
    TimeoutStopSec = 5;
    Restart = "no";
    WorkingDirectory = config.home.homeDirectory;
    Environment = environment;
    # Force Wine's registry update even when Nix normalizes wine.inf timestamps.
    ExecStartPre = [
      "${pkgs.coreutils}/bin/env PROTON_VERB=run ${exec "wineboot"} -u"
    ];
    StandardOutput = "journal";
    StandardError = "journal";
  };

  exec =
    executable:
    lib.concatStringsSep " " [
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
    Service = preLaunchConfig // {
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
    Service = preLaunchConfig // {
      Environment = environment ++ [ "PROTON_VERB=run" ];
      ExecStartPre = [
        ''${pkgs.coreutils}/bin/test -f "${installer}"''
      ]
      ++ preLaunchConfig.ExecStartPre;
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
