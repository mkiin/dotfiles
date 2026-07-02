_: {
  services.cliphist.enable = true;
  services.cliphist.allowImages = true;
  # コピー元プロセスが死んでもクリップボードを保持する。
  # 無いと screenshot の wl-copy 常駐が消えて貼付時に画像が失われる。
  services.wl-clip-persist.enable = true;
}
