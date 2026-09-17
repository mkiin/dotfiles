# 自作の未署名 content-script 拡張を home-manager の firefox 系
# extensions.packages が期待する形に組む:
#   $out/share/mozilla/extensions/{ec8030f7-...}/<addonId>.xpi
#   passthru.addonId = <gecko id>  ← module がファイル名/有効化キーに使う
{ pkgs }:
let
  addonId = "missav-keep-playing@local";
  firefoxAppId = "{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";
in
pkgs.runCommandLocal "missav-keep-playing"
  {
    passthru = { inherit addonId; };
    nativeBuildInputs = [ pkgs.zip ];
  }
  ''
    dst=$out/share/mozilla/extensions/${firefoxAppId}
    mkdir -p "$dst"
    cd ${./.}
    # -X: 拡張属性/タイムスタンプを含めず再現ビルドにする
    zip -r -X "$dst/${addonId}.xpi" manifest.json content.js
  ''
