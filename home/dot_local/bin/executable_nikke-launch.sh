#!/usr/bin/env bash
# NIKKE 起動スクリプト
# - 引数あり: anime-games-launcher の Command wrapper として呼ばれた想定。
#             GIO TLS バックエンドのパスを補ってから渡された exec をそのまま実行。
# - 引数なし: rofi / 直接実行。launcher を介さず env を整えて起動チェーンを呼ぶ。
#
# GIO_MODULE_DIR は Steam Runtime Sniper 内で glib が libgiognutls.so を見つけられず
# HTTPS ストリーミングムービー (MFCreateSourceReaderFromURL → 0xc00d36bb) が落ちる
# 問題の回避に必須。
#
# trap EXIT で wineserver -k を呼ぶ。explorer.exe /desktop など Wine 常駐プロセスが
# NIKKE 終了後も wineserver の自動停止を阻害して残り続けるのを防ぐため。

set -eu

ROOT="$HOME/.local/share/anime-games-launcher/packages/persistent/447618380df295a-goddess_of_victory_nikke"
NIKKE_WINEPREFIX="$ROOT/prefix/nikke/pfx"
WINESERVER="$ROOT/proton/dwproton-10.0-22/files/bin/wineserver"

export GIO_MODULE_DIR="/usr/lib/x86_64-linux-gnu/gio/modules"
export GIO_EXTRA_MODULES="/usr/lib/x86_64-linux-gnu/gio/modules:/usr/lib/i386-linux-gnu/gio/modules"
export GIO_USE_TLS=gnutls

cleanup() {
  WINEPREFIX="$NIKKE_WINEPREFIX" "$WINESERVER" -k 2>/dev/null || true
}
trap cleanup EXIT

if [ $# -gt 0 ]; then
  # Command wrapper モード（exec しない: trap を効かせるため）
  "$@"
  exit $?
fi

# Standalone モード (rofi 等)
if pgrep -f "$NIKKE_WINEPREFIX/drive_c/NIKKE/Launcher/nikke_launcher.exe" >/dev/null 2>&1; then
  echo "NIKKE は既に起動中です。二重起動を中止します。" >&2
  trap - EXIT  # cleanup の wineserver -k が起動中インスタンスを巻き込むのを防ぐ
  exit 0
fi

export WINEPREFIX="$NIKKE_WINEPREFIX"
export PROTONPATH="$ROOT/proton/dwproton-10.0-22"
export GAMEID=umu-nikke
export PROTON_USE_WOW64=1
export WINEDEBUG=""
# 起動毎の steamrt3 更新 DL で起動が詰まるため更新を無効化
export UMU_RUNTIME_UPDATE=0

"$ROOT/umu-run" "$NIKKE_WINEPREFIX/drive_c/NIKKE/Launcher/nikke_launcher.exe"
