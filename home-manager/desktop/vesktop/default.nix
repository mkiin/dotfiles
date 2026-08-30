_: {
  programs.vesktop = {
    enable = true;
    package = null;

    settings = {
      minimizeToTray = true;
      tray = true;
      checkUpdates = false;
      customTitleBar = false;
      hardwareAcceleration = true;
      # Vesktop は公式のゲーム検出モジュールを持たないので arRPC で代替する
      arRPC = true;
    };
  };
}
