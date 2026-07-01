{ pkgs, ... }:
let
  prefix = "$HOME/Games/nikke";

  # GODDESS OF VICTORY: NIKKE を umu-launcher で起動する。
  # GAMEID=umu-nikke は umu 側 protonfixes に NIKKE 用の対策を引かせるための識別子。
  # nikke_launcher がまれに spawn し損ねるため、AGL 同様に検出→再起動のリトライを入れる。
  nikke = pkgs.writeShellApplication {
    name = "nikke";
    runtimeInputs = [
      pkgs.umu-launcher
      pkgs.procps
    ];
    text = ''
      export WINEPREFIX="''${NIKKE_PREFIX:-${prefix}}"
      export GAMEID="umu-nikke"
      export STORE="none"
      export PROTON_USE_WOW64=1

      exe="$WINEPREFIX/drive_c/NIKKE/Launcher/nikke_launcher.exe"
      if [ ! -f "$exe" ]; then
        echo "NIKKE がインストールされていません。先に 'nikke-install' を実行してください。" >&2
        exit 1
      fi

      max_retries=10
      wait_seconds=8
      for attempt in $(seq 1 "$max_retries"); do
        umu-run "$exe" "$@" &
        game_pid=$!
        sleep "$wait_seconds"
        if pgrep -f -- '--ProductName=nikke_launcher' >/dev/null 2>&1; then
          wait "$game_pid"
          exit $?
        fi
        echo "[nikke] attempt $attempt: nikke_launcher を検出できず、再起動します..." >&2
        WINEPREFIX="$WINEPREFIX" umu-run wineserver -k >/dev/null 2>&1 || true
        kill "$game_pid" 2>/dev/null || true
        sleep 3
      done
      echo "[nikke] $max_retries 回試行しましたが起動できませんでした" >&2
      exit 1
    '';
  };

  # 初回セットアップ専用。公式サイトから miniloader を取得して prefix 内で実行する。
  # 引数にローカルのインストーラ .exe を渡せば、そのままそれを実行する（スクレイプ回避用）。
  nikke-install = pkgs.writeShellApplication {
    name = "nikke-install";
    runtimeInputs = [
      pkgs.umu-launcher
      pkgs.curl
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      export WINEPREFIX="''${NIKKE_PREFIX:-${prefix}}"
      export GAMEID="umu-nikke"
      export STORE="none"
      export PROTON_USE_WOW64=1
      mkdir -p "$WINEPREFIX"

      if [ "$#" -ge 1 ] && [ -f "$1" ]; then
        installer="$1"
        echo "ローカルインストーラを使用: $installer"
      else
        base="https://nikke-en.com"
        echo "公式サイトから miniloader のURLを探索中..."
        # トップページから aix-*.js を特定し、その中から miniloader の実体パスを抽出する。
        js_path="$(curl -fsSL "$base" | grep -oE '/assets/aix-[^"]+\.js' | head -1)"
        if [ -z "$js_path" ]; then
          js_path="/assets/aix-18872c9c.js" # フォールバック(AGL integration と同じ既知パス)
        fi
        loader_path="$(curl -fsSL "$base$js_path" | grep -oE '/nikkeminiloader[^"]+\.exe' | head -1)"
        if [ -z "$loader_path" ]; then
          echo "miniloader のURL抽出に失敗しました。公式サイトから手動でインストーラをDLし、" >&2
          echo "  nikke-install /path/to/installer.exe  として渡してください。" >&2
          exit 1
        fi
        installer="$(mktemp -d)/$(basename "$loader_path")"
        echo "ダウンロード中: $base$loader_path"
        curl -fSL "$base$loader_path" -o "$installer"
      fi

      echo "prefix ($WINEPREFIX) 内でインストーラを実行します..."
      umu-run "$installer"
      echo "完了。インストーラ側でゲーム本体のDLを終えたら 'nikke' で起動できます。"
    '';
  };
in
{
  home.packages = [
    pkgs.umu-launcher
    nikke
    nikke-install
  ];

  # ランチャー(qs launcher)や他のメニューからも起動できるようにデスクトップエントリを登録。
  xdg.desktopEntries.nikke = {
    name = "NIKKE";
    comment = "GODDESS OF VICTORY: NIKKE";
    exec = "nikke";
    terminal = false;
    categories = [ "Game" ];
  };
}
