{ pkgs, ... }:

let
  dwproton = pkgs.callPackage ./dwproton.nix { };

  nikke = pkgs.writeShellApplication {
    name = "nikke";

    runtimeInputs = with pkgs; [
      umu-launcher
      steam.run
      procps
      util-linux
      coreutils
    ];

    runtimeEnv = {
      NIKKE_PROTON = "${dwproton}";
      PROTON_NO_FSYNC = "1";
      PROTON_NO_ESYNC = "1";
    };

    text = builtins.readFile ./scripts/nikke.sh;
  };
in
{
  home.packages = [
    nikke
  ];

  xdg.desktopEntries.nikke = {
    name = "NIKKE";
    genericName = "Goddess of Victory: NIKKE";
    exec = "nikke";
    icon = "${./assets/nikke.png}";
    terminal = false;
    categories = [ "Game" ];
  };
}
