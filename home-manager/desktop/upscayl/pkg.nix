{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  vulkan-loader,
}:
let
  version = "2.15.1";
  base = "https://raw.githubusercontent.com/upscayl/upscayl/v${version}";
  # custom-models リポジトリ(コミット固定)。アニメ系 4xHFA2k の取得元
  customModels = "https://raw.githubusercontent.com/upscayl/custom-models/4b6d2cfa59c7442af115dfc6e50fd8d7d40b96ef";

  upscaylBin = fetchurl {
    url = "${base}/resources/linux/bin/upscayl-bin";
    hash = "sha256-p6rR2DHREwdiEBvjy6jO/izrLR0BDM5Nh2z8AiIm2rQ=";
  };

  # モデル: { name(=CLIの-n表記) = { bin; param; }; }
  models = {
    # 既定。イラスト/CG/セル画向き（upscayl 本体同梱）
    "digital-art-4x" = {
      bin = fetchurl {
        url = "${base}/resources/models/digital-art-4x.bin";
        hash = "sha256-/gHCac/RDN744BirZuvnUM95x69NH5wWxzfhKVIpusw=";
      };
      param = fetchurl {
        url = "${base}/resources/models/digital-art-4x.param";
        hash = "sha256-K4+24K5NLYVwTKCMEZovXqQK3U8uzVEut/TNRLYSftQ=";
      };
    };
    # オーソドックスな汎用写真モデル（upscayl 本体同梱）
    "remacri-4x" = {
      bin = fetchurl {
        url = "${base}/resources/models/remacri-4x.bin";
        hash = "sha256-pDvllcDXQzFMMLUP5+8Yi+DGHMVcRs6BrbebpLPD+3o=";
      };
      param = fetchurl {
        url = "${base}/resources/models/remacri-4x.param";
        hash = "sha256-hZ7LpbNZLs8+dsk77WXp9ie1I23WlqrlqE7PjJOrZc4=";
      };
    };
    # アニメイラスト高忠実度（custom-models）
    "4xHFA2k" = {
      bin = fetchurl {
        url = "${customModels}/models/4xHFA2k.bin";
        hash = "sha256-ihNUArTzkoYSG3artHYBpre36NTz6ZmlqqRe0neCT7Q=";
      };
      param = fetchurl {
        url = "${customModels}/models/4xHFA2k.param";
        hash = "sha256-RXbtXC/F+iUNPD1YXvAiSPJqvfwYZwiAePUB/nHl1h4=";
      };
    };
  };

  # 各モデルを $out/share/upscayl/models/<name>.{bin,param} へ配置する install 行
  installModels = builtins.concatStringsSep "\n" (
    builtins.attrValues (
      builtins.mapAttrs (name: m: ''
        install -Dm644 ${m.bin} $out/share/upscayl/models/${name}.bin
        install -Dm644 ${m.param} $out/share/upscayl/models/${name}.param
      '') models
    )
  );

  defaultModel = "digital-art-4x";

  # wrapper.sh の @modelLines@ に埋める、モデル一覧を出す echo 行（1 行 1 モデル）
  modelLines = builtins.concatStringsSep "\n" (
    map (n: "echo '  - ${n}'") (builtins.attrNames models)
  );
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

    ${installModels}

    # GPU ICD(NVIDIA/mesa)は実行時ホストパスから、モデルと既定モデル名は焼き込み
    makeWrapper $out/libexec/upscayl-bin $out/libexec/upscayl-run \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib \
      --add-flags "-m $out/share/upscayl/models" \
      --add-flags "-n ${defaultModel}"

    # help/models のときだけ同梱モデル(-n の候補)を出す薄いラッパを被せる
    mkdir -p $out/bin
    substitute ${./wrapper.sh} $out/bin/upscayl-cli \
      --subst-var-by run "$out/libexec/upscayl-run" \
      --subst-var-by defaultModel "${defaultModel}" \
      --subst-var-by modelLines ${lib.escapeShellArg modelLines}
    chmod +x $out/bin/upscayl-cli

    runHook postInstall
  '';

  meta = {
    description = "Upscayl inference CLI (Real-ESRGAN ncnn-vulkan) without the Electron UI";
    platforms = [ "x86_64-linux" ];
  };
}
