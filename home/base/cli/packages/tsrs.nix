{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  versionCheckHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tsrs";
  version = "7.1.0-beta.tsrs3";

  src = fetchurl {
    url = "https://registry.npmjs.org/@tsrs/linux-x64-gnu/-/linux-x64-gnu-${finalAttrs.version}.tgz";
    hash = "sha512-erepwUH0NoRDjLeHEEEruh0Gd2/t0n2PHfJwXNlgSNbGM94+nNNZop0sYmjAtx63MadiC9YQXO6blTEQDVpDOg==";
  };

  sourceRoot = "package";
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # tsrs loads the bundled TypeScript libraries from its executable directory.
    mkdir -p "$out/bin" "$out/lib/tsrs"
    cp -a ./. "$out/lib/tsrs/"
    ln -s "$out/lib/tsrs/tsrs" "$out/bin/tsrs"

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Rust implementation of the TypeScript 7 compiler and language server";
    homepage = "https://github.com/oxc-project/tsrs";
    license = lib.licenses.asl20;
    mainProgram = "tsrs";
    platforms = [ "x86_64-linux" ];
  };
})
