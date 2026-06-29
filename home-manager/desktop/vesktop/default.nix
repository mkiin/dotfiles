_:
{
  # vesktop 本体は nixos/desktop/vesktop で system パッケージとして導入済み。
  # ここでは package = null としてパッケージの二重導入を避け、設定ファイルのみ生成する。
  programs.vesktop = {
    enable = true;
    package = null;

    # Vesktop 本体設定 -> ~/.config/vesktop/settings.json
    settings = {
      minimizeToTray = true; # ウィンドウを閉じてもトレイに常駐
      tray = true; # トレイアイコンを表示
      checkUpdates = false; # 更新は Nix で管理するためアプリ内チェックを無効化
      customTitleBar = false; # タイトルバーは Hyprland 側に委ねる
      hardwareAcceleration = true; # GPU アクセラレーションを明示的に有効化
    };
  };
}
