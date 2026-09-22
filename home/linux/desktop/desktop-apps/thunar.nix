{ pkgs, ... }:

let
  # プラグインを組み込んだ Thunar パッケージを生成
  thunarWithPlugins = pkgs.thunar.override {
    thunarPlugins = with pkgs; [
      thunar-archive-plugin # zip / tar などの圧縮・解凍
      thunar-volman # USB メディア管理
    ];
  };
in
{
  home.packages = [
    thunarWithPlugins
  ];
  # xfconf.settings.thunar = {
  #   "last-show-hidden" = true; # 隠しファイルをデフォルトで表示
  # };
}
