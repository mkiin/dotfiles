{
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "dwproton";
  version = "11.0-12";

  src = fetchurl {
    url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-${version}/dwproton-${version}-x86_64.tar.xz";
    hash = "sha256-+vNm1xJg40be5pYP9CbmkbkS4OwlQXdA6YHIrgWSRjA=";
  };
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a . $out/
    runHook postInstall
  '';

  meta.platforms = [ "x86_64-linux" ];
}
