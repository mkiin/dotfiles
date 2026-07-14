{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "sddm-star-rail-theme";
  version = "0-unstable-2026-06-05";

  src = fetchFromGitHub {
    owner = "Darkkal44";
    repo = "qylock";
    rev = "db61a972b4b23728d9944a906e70029ca8a5899d";
    hash = "sha256-jVNBiyhdA0lU2CapcgoWO9WlnEF/EBg+JfpPf/G/CzQ=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sddm/themes
    cp -r themes/star-rail $out/share/sddm/themes/star-rail
    runHook postInstall
  '';
}
