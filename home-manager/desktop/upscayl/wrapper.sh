#!/bin/sh
# 素の upscayl-bin は -h に -n の候補を出さないので、help/models のときだけ
# 同梱モデル一覧を追記する薄いラッパ。@..@ は pkg.nix の substitute で焼き込む。
print_models() {
  echo '同梱モデル (-n で指定, 既定=@defaultModel@):'
  @modelLines@
}
case "$1" in
models | --list-models)
  print_models
  exit 0
  ;;
-h | --help | "")
  @run@ -h
  echo
  print_models
  exit 0
  ;;
esac
exec @run@ "$@"
