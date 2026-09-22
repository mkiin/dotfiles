{ pkgs, lib, ... }:
let
  dwproton = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "dwproton";
    version = "11.0-13";

    src = pkgs.fetchurl {
      url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-${version}/dwproton-${version}-x86_64.tar.xz";
      hash = lib.fakeHash;
    };

    dontConfigure = true;
    dontBuild = true;

    dontFixup = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -a ./. "$out/"

      runHook postInstall
    '';

    meta.platforms = [ "x86_64-linux" ];
  };

  nikke = pkgs.writeShellApplication {
    name = "nikke";

    runtimeInputs = with pkgs; [
      umu-launcher
      steam.run
      jq
      procps
      util-linux
      coreutils
    ];

    runtimeEnv = {
      NIKKE_PROTON = "${dwproton}";
      PROTON_NO_FSYNC = "1";
      PROTON_NO_ESYNC = "1";
    };

    text = builtins.readFile scripts/nikke.sh;
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
    icon = "${assets/nikke.png}";
    terminal = false;
    categories = [ "Game" ];
  };
}
