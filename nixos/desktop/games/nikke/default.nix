_: {
  # wine の同期を fsync(userspace 近似・missed-wakeup レースあり)から
  # ntsync(カーネル実装・Windows と同じ意味論)へ置き換えるための前提。
  # 実際の切り替えは home-manager 側の nikke ラッパーが PROTON_NO_FSYNC/ESYNC で行う。
  boot.kernelModules = [ "ntsync" ];
}
