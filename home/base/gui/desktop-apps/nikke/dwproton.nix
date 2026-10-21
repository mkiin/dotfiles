{
  stdenvNoCC,
  fetchurl,
}:
let
  version = "11.0-13";
in
stdenvNoCC.mkDerivation {
  pname = "dwproton";
  inherit version;

  src = fetchurl {
    url = "https://git.dawn.wine/dawn-winery/dwproton/releases/download/dwproton-${version}/dwproton-${version}-x86_64.tar.xz";
    hash = "sha256-lMkSsyBeH5o7lmFOo9w5+jVCETIB4G44LbD3w8XSQfQ=";
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
}
