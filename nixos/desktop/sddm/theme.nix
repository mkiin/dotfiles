{
  stdenvNoCC,
  fetchFromGitHub,
  fetchurl,
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

  # テーマ本来のフォント。upstream が商用フォントの再配布を避けるため
  # b6301e7 で削除したが、Main.qml は font/ を読む前提のまま
  font = fetchurl {
    url = "https://raw.githubusercontent.com/Darkkal44/qylock/784076fdeb6337134e2c37d0546037569b0ef405/themes/star-rail/font/DINNextW1G-Medium.otf";
    hash = "sha256-pMhk1Ef6tL7jfzfAWRKMiIAvnpSaZAbHHs/DhjwWRBs=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/sddm/themes
    cp -r themes/star-rail $out/share/sddm/themes/star-rail
    install -Dm644 $font $out/share/sddm/themes/star-rail/font/DINNextW1G-Medium.otf
    runHook postInstall
  '';
}
