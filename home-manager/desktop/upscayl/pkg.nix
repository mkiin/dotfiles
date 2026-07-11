{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  vulkan-loader,
}:
let
  version = "2.15.1";
  base = "https://raw.githubusercontent.com/upscayl/upscayl/v${version}";

  upscaylBin = fetchurl {
    url = "${base}/resources/linux/bin/upscayl-bin";
    hash = "sha256-p6rR2DHREwdiEBvjy6jO/izrLR0BDM5Nh2z8AiIm2rQ=";
  };
  modelBin = fetchurl {
    url = "${base}/resources/models/digital-art-4x.bin";
    hash = "sha256-/gHCac/RDN744BirZuvnUM95x69NH5wWxzfhKVIpusw=";
  };
  modelParam = fetchurl {
    url = "${base}/resources/models/digital-art-4x.param";
    hash = "sha256-K4+24K5NLYVwTKCMEZovXqQK3U8uzVEut/TNRLYSftQ=";
  };
in
stdenv.mkDerivation {
  pname = "upscayl-cli";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  # libvulkan.so.1 と libgomp.so.1(=stdenv.cc.cc.lib) を rpath に注入
  buildInputs = [
    vulkan-loader
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${upscaylBin} $out/libexec/upscayl-bin
    install -Dm644 ${modelBin} $out/share/upscayl/models/digital-art-4x.bin
    install -Dm644 ${modelParam} $out/share/upscayl/models/digital-art-4x.param

    # GPU ICD(NVIDIA/mesa)は実行時ホストパスから、モデルと既定モデル名は焼き込み
    makeWrapper $out/libexec/upscayl-bin $out/bin/upscayl-cli \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib \
      --add-flags "-m $out/share/upscayl/models" \
      --add-flags "-n digital-art-4x"

    runHook postInstall
  '';

  meta = {
    description = "Upscayl inference CLI (Real-ESRGAN ncnn-vulkan) without the Electron UI";
    platforms = [ "x86_64-linux" ];
  };
}
