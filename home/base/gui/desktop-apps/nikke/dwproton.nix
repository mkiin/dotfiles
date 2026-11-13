{
  stdenvNoCC,
  fetchurl,
}:
let
  version = "11.0-16";
in
stdenvNoCC.mkDerivation {
  pname = "dwproton";
  inherit version;

  src = fetchurl {
    url = "https://git.dawn.wine/dawn-winery/dwproton/releases/download/dwproton-${version}/dwproton-${version}-x86_64.tar.xz";
    hash = "sha256-ZXsOZu+wqYJCFbwIh6aPdYNVUXzE6qsxZMAZu2y5Umg=";
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
