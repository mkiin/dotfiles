{ lnk, ... }:
{
  xdg.configFile = {
    "mouse/g703h.sh".source = lnk ./g703h.sh;
    "mouse/m575-profiled.py".source = lnk ./m575-profiled.py;
    "mouse/profiles.toml".source = lnk ./profiles.toml;
  };

  # m575-profiled.service は撤去した。lnk で貼る .py に実行ビットが無く
  # ExecStart が 203/EXEC で即死 → 2 秒ごとに再起動して journal を埋め尽くしていた。
  # 復活させるなら実行ビットか interpreter 経由の起動を先に用意すること。
}
