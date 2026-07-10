# hyprlock デザインリファレンス調査

- 調査日: 2026-07-10
- 対象: 指定された ghq 配下の 91 repo
- 方針: `ghq get` は実行せず、ローカルに存在するファイルだけを読む。hyprlock の設定・テンプレート・関連 script だけを対象にする。
- 検出: hyprlock 関連ファイルあり 82 repo、実 widget 構成を持つ conf あり 79 repo、関連ファイル合計 215 件。
- widgets 列は `background/input/label/image/shape` の順。

## 全体傾向

1. 最も多い型は「blur wallpaper + 中央 input-field + 大時計/日付ラベル」。背景を暗くぼかして、時計を 55-130px 程度で置く構成が主流。
2. `image` widget は avatar や album art に使われることが多い。今回の壁紙は人物が既に主役なので、追加 image は競合しやすい。
3. `shape` を使う repo は少数だが、線・パネル・区切りとして有効。現在の A1 案の短い罫線は hyprlock の実装範囲として妥当。
4. `now playing` 系は情報量が大きく、ロック画面を dashboard 化する。今回の「壁紙主役」からは外れるが、階層化と小さい補助文字の扱いは参考になる。
5. 巨大時計は 140px 以上で画面を支配しやすい。今回の壁紙では 95-112px 程度に収める方が、顔とリボンを邪魔しにくい。

## 今回のロック画面へ使う判断

- 採用する: blur/scrim、少数ラベル、短い shape 罫線、zindex 明示、時計 95-112px 程度。
- 採用しない: avatar 追加、now playing 常時表示、多数のシステムラベル、巨大時計 140px 以上。
- 再検討する: 日付の letter spacing、PM の相対サイズ、罫線の位置。多くの repo は日付を小さくしすぎず、時計の下に近接させている。

## Repo 別サマリ

| Repo | 代表ファイル | 型 | widgets | デザインの形 | 今回への示唆 |
|---|---|---|---:|---|---|
| zDyant/HyprNova | .config/hypr/hyprlock.conf | 複数ラベル + 大時計 | 1/1/5/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| vyrx-dev/symphony | .config/hypr/hyprlock.conf | 生体認証 + avatar/アート + 最小ラベル + 中時計 | 1/1/2/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計中心の少数ラベル。時計は中サイズで控えめ。fingerprint/howdy など認証状態の文言がある。 | 壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| LierB/dotfiles | .config/hypr/hyprlock.conf | 複数ラベル + 中時計 | 1/1/3/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。 |
| LoneWolf4713/seraphic.dotfiles | dotfiles/hypr/hyprlock.conf | 複数ラベル + 大時計 | 1/1/6/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| shell-ninja/hyprconf-install | - | hyprlock 設定検出なし | - | ローカルには hyprlock 設定ファイルを検出できなかった。 | 直接の layout 参考度は低い。 |
| mahaveergurjar/Hyprlock-Dots | .config/hyprlock/layouts/hyprlock.conf | テーマパック + 複数ラベル + 巨大時計 | 1/1/4/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計はかなり強い主役。 | 要素構成の比較対象。 |
| xeji01/hyprstellar | .config/hypr/hyprlock.conf | shape 装飾 + avatar/アート + 情報ダッシュボード + 中時計 | 1/1/13/6/8 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。shape で線・パネル・区切りを作る。時計以外にシステム情報を多数載せる。時計は中サイズで控えめ。 | shape の zindex/線/パネル利用を参考にできる。現方針には情報量が多すぎるが、余白と階層化は参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| catppuccin/hyprlock | hyprlock.conf | 生体認証 + avatar/アート + 複数ラベル + 中時計 + Catppuccin | 1/1/4/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。fingerprint/howdy など認証状態の文言がある。 | 時計サイズの上限感が参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| SherLock707/hyprland_dot_yadm | - | 未取得 | - | ローカルには hyprlock 設定ファイルを検出できなかった。 | 直接の layout 参考度は低い。 |
| Thunder-Blaze/BlazinLock | hyprlock/blazinscripts.sh | README/補助実装のみ | 0/0/0/0/0 | README や generator/script が中心で、直接流用できる widget 構成は薄い。 | 直接の layout 参考度は低い。 |
| auralisx/dotfiles_old | .config/hypr/hyprlock.conf | avatar/アート + 情報ダッシュボード + 巨大時計 | 1/1/9/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計以外にシステム情報を多数載せる。時計はかなり強い主役。 | 現方針には情報量が多すぎるが、余白と階層化は参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| OldJobobo/theme-manager-plus | rust/src/hyprlock.rs | README/補助実装のみ | 0/0/0/0/0 | README や generator/script が中心で、直接流用できる widget 構成は薄い。 | 直接の layout 参考度は低い。 |
| jazz1n/dotfiles | .config/hypr/hyprlock.conf | avatar/アート + 複数ラベル + 中時計 + Catppuccin | 1/1/3/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| logicalman3812/hyprdots | .config/hypr/hyprlock.conf | 再生情報 + avatar/アート + 複数ラベル + 中時計 | 1/1/3/2/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。MPRIS/playerctl で再生情報を出す。 | 現方針には情報量が多すぎるが、余白と階層化は参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| fk2731/FixiBar | config/.config/hypr/hyprlock.conf | 複数ラベル + 大時計 | 1/1/5/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| develcooking/hyprland-dotfiles | .config/hypr/hyprlock.conf | 最小ラベル + 小時計 | 1/1/1/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。 | 壁紙主役のまま情報量を抑える参考になる。 |
| zhaleff/hyprdots | configs/config/hypr/hyprlock.conf | 再生情報 + 複数ラベル + 大時計 | 1/1/6/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。MPRIS/playerctl で再生情報を出す。 | 時計サイズの上限感が参考になる。現方針には情報量が多すぎるが、余白と階層化は参考になる。 |
| SherLock707/hyprland_dots | - | 未取得 | - | ローカルには hyprlock 設定ファイルを検出できなかった。 | 直接の layout 参考度は低い。 |
| ufuayk/hyprconf-gen | - | hyprlock 設定検出なし | - | ローカルには hyprlock 設定ファイルを検出できなかった。 | 直接の layout 参考度は低い。 |
| tuconnaisyouknow/HyprPunk | hyprlock-desktop/.config/hypr/hyprlock.conf | avatar/アート + 複数ラベル + 中時計 + Catppuccin | 1/1/5/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| divy-03/dotfiles | hyprland/.config/hypr/hyprlock.conf | 複数ラベル + 大時計 + Catppuccin | 1/1/5/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| dangooddd/.dotfiles-hyprland | .config/hypr/hyprlock.conf | 最小ラベル + 小時計 | 1/1/1/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。 | 壁紙主役のまま情報量を抑える参考になる。 |
| LordWorm1996/Wildberries-Ports | Source/hyprlock.conf | 複数ラベル + 巨大時計 | 2/1/3/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計はかなり強い主役。 | 壁紙主役のまま情報量を抑える参考になる。 |
| ozhangebesoglu/kishi-dots | Config/hypr/hyprlock.conf | avatar/アート + 情報ダッシュボード + 中時計 | 1/1/11/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計以外にシステム情報を多数載せる。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。現方針には情報量が多すぎるが、余白と階層化は参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| ezerfrlux/omarchy-config | hyprlock/layouts/hyprlock.conf | テーマパック + 複数ラベル + 巨大時計 | 1/1/4/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計はかなり強い主役。 | 要素構成の比較対象。 |
| AT0117/dots | hypr/hyprlock.conf | shape 装飾 + 複数ラベル + 巨大時計 | 1/1/4/0/1 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。shape で線・パネル・区切りを作る。時計・日付・補助テキストを分離して配置する。時計はかなり強い主役。 | shape の zindex/線/パネル利用を参考にできる。 |
| Harsh-bin/hyprlock-nowplaying | hyprlock.conf | avatar/アート + 複数ラベル + 中時計 | 1/1/4/2/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| LongYinStudio/dotfiles | wayland/hypr/hyprlock.conf | avatar/アート + 最小ラベル + 中時計 | 1/1/2/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| wafzynothinIV/wafzy-useless-config | hyprlock/hypr/hyprlock.conf | avatar/アート + 複数ラベル + 中時計 | 1/1/6/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| xeji01/neulock | hyprlock/themes/aberdeen.conf | テーマパック + avatar/アート + 情報ダッシュボード + 中時計 | 1/1/20/6/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計以外にシステム情報を多数載せる。時計は中サイズで控えめ。 | 現方針には情報量が多すぎるが、余白と階層化は参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| ultimateBroK/brokies_land | .config/hypr/hyprlock.conf | avatar/アート + 最小ラベル + 中時計 | 1/1/2/1/0 | 入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| darwin-garcia/Arch-Linux-Hyprland-v2 | hypr/hyprlock.conf | 生体認証 + 情報ダッシュボード + 大時計 | 1/1/9/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計以外にシステム情報を多数載せる。時計は主役だが周辺要素と併存。fingerprint/howdy など認証状態の文言がある。 | 時計サイズの上限感が参考になる。現方針には情報量が多すぎるが、余白と階層化は参考になる。 |
| SeakMengs/dotfiles | .config/hypr/hyprlock.conf | 複数ラベル + 大時計 | 1/1/5/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| jude7733/hypr | hyprlock.conf | 複数ラベル + 大時計 | 1/1/6/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| mhkarimi1383/hypr | hyprlock.conf | avatar/アート + 複数ラベル + 中時計 + Catppuccin | 1/1/3/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| dark-orchid/hyprlock | README.md | README/補助実装のみ | 0/0/0/0/0 | README や generator/script が中心で、直接流用できる widget 構成は薄い。 | 直接の layout 参考度は低い。 |
| shantanubaddar/Alphonso--A-Complete-MangoWC-setup-files | Hyprlock/Alphonso/hyprlock.conf | 再生情報 + avatar/アート + 情報ダッシュボード + 大時計 | 1/1/8/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計以外にシステム情報を多数載せる。時計は主役だが周辺要素と併存。MPRIS/playerctl で再生情報を出す。 | 時計サイズの上限感が参考になる。現方針には情報量が多すぎるが、余白と階層化は参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| chadnpc/dotfiles | .config/hypr/hyprlock.conf | avatar/アート + 最小ラベル + 中時計 | 1/1/2/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| nedorazrab0/arch39 | cfg/etc/xdg/hypr/hyprlock.conf | 最小ラベル + 大時計 | 1/1/2/0/0 | 入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。 |
| pmpinto/hyprlock-omarchy | hypr/hyprlock.conf | 生体認証 + shape 装飾 + 複数ラベル + 小時計 | 1/1/5/0/1 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。shape で線・パネル・区切りを作る。時計・日付・補助テキストを分離して配置する。fingerprint/howdy など認証状態の文言がある。 | shape の zindex/線/パネル利用を参考にできる。 |
| Momen-Hamed/Arch-ZEM | .config/hypr/hyprlock.conf | 複数ラベル + 巨大時計 | 1/1/4/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計はかなり強い主役。 | 要素構成の比較対象。 |
| MKKHLIF/.dotfiles | .nixos (deprecated)/modules/home/_config/hypr/hyprlock.conf | avatar/アート + 最小ラベル + 中時計 + Catppuccin | 1/1/2/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計中心の少数ラベル。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| Jxt-Eli/Hypr | hyprlock.conf | 再生情報 + 生体認証 + 複数ラベル + 巨大時計 | 1/1/5/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計はかなり強い主役。MPRIS/playerctl で再生情報を出す。fingerprint/howdy など認証状態の文言がある。 | 現方針には情報量が多すぎるが、余白と階層化は参考になる。 |
| h3bzzz/h3bzzz-dotfiles | config/hypr/hyprlock.conf | 複数ラベル + 中時計 | 2/1/6/0/0 | 入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 要素構成の比較対象。 |
| lenarus/simpleStylishHyprlock | hyprlock.conf | 最小ラベル + 大時計 | 1/1/2/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。 |
| Candys2000/Themeswitcher-hyprland | config/hypr/hyprlock.conf | 最小ラベル + 中時計 | 1/1/1/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。 |
| kyojin22/dotfiles | hypr/hyprlock.conf | 最小ラベル + 中時計 | 1/1/2/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。 |
| Gren-95/hyprland-dots | hypr/hyprlock.conf | 再生情報 + avatar/アート + 情報ダッシュボード + 大時計 | 1/1/8/2/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計以外にシステム情報を多数載せる。時計は主役だが周辺要素と併存。MPRIS/playerctl で再生情報を出す。 | 時計サイズの上限感が参考になる。現方針には情報量が多すぎるが、余白と階層化は参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| lukaszkowalik2/dotfiles | - | hyprlock 設定検出なし | - | ローカルには hyprlock 設定ファイルを検出できなかった。 | 直接の layout 参考度は低い。 |
| yashjodon/YashJodon-Dots | - | hyprlock 設定検出なし | - | ローカルには hyprlock 設定ファイルを検出できなかった。 | 直接の layout 参考度は低い。 |
| ChitranshAherwar/nyx-hyprland | hypr/hyprlock.conf | avatar/アート + 複数ラベル + 大時計 | 1/1/3/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| markart25/markdots | .config/hypr/hyprlock.conf | 複数ラベル + 大時計 | 1/1/3/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。 |
| nithitsuki/dotfiles | hypr/.config/hypr/hyprlock.conf | 複数ラベル + 巨大時計 | 1/1/4/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計はかなり強い主役。 | 要素構成の比較対象。 |
| hollowillow/hyprland | hyprlock.conf | 最小ラベル + 中時計 | 1/1/2/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。 |
| AlguienSasaki/new-dots | hypr/hyprlock.conf | avatar/アート + 複数ラベル + 大時計 | 1/1/6/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| Mimic890/HyprArch | configs/hypr/hyprlock.conf | 最小ラベル + 中時計 | 1/1/2/0/0 | 入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。 |
| nilsojunior/dotfiles | .config/hypr/hyprlock.conf | avatar/アート + 最小ラベル + 小時計 + Catppuccin | 1/1/2/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計中心の少数ラベル。 | 壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| stauersbol/dotfiles | hypr/.config/hypr/hyprlock.conf | 複数ラベル + 中時計 | 1/1/3/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。 |
| fxhxyz4/dotfiles | configs/hypr/hyprlock/SF Pro.conf | shape 装飾 + avatar/アート + 複数ラベル + 中時計 | 1/1/6/1/1 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。shape で線・パネル・区切りを作る。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | shape の zindex/線/パネル利用を参考にできる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| thenullstackdeveloper/hypr-themes | skeleton/hypr/hyprlock.conf | 最小ラベル + 中時計 | 1/1/2/0/0 | 入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。 |
| crqch/go-hyprlock | hyprlock.conf | 最小ラベル + 小時計 | 2/1/1/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。 | 壁紙主役のまま情報量を抑える参考になる。 |
| abhix079/dotfiles | hypr/hyprlock.conf | 複数ラベル + 中時計 | 1/1/4/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。 |
| offyotto/howdy-surface | - | hyprlock 設定検出なし | - | ローカルには hyprlock 設定ファイルを検出できなかった。 | 直接の layout 参考度は低い。 |
| Seliphais/hyprlock-matrix | hyprlock.conf | 複数ラベル + 大時計 | 1/1/4/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| VisdethSara/dotfiles | .config/hypr/hyprlock.conf | 生体認証 + 複数ラベル + 小時計 | 1/1/4/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。fingerprint/howdy など認証状態の文言がある。 | 要素構成の比較対象。 |
| joannescode/hyprland-black-theme | .configs/hypr/hyprlock.conf | 複数ラベル + 小時計 | 1/1/3/0/0 | 入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。 | 壁紙主役のまま情報量を抑える参考になる。 |
| MagicExist/archlinux-dotfiles | .config/hypr/hyprlock/layout9.conf | 再生情報 + shape 装飾 + avatar/アート + 複数ラベル + 中時計 | 1/1/7/1/2 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。shape で線・パネル・区切りを作る。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。MPRIS/playerctl で再生情報を出す。 | shape の zindex/線/パネル利用を参考にできる。現方針には情報量が多すぎるが、余白と階層化は参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| elmaleek03/hyprlock-howdy | config/hyprlock-face-unlock.conf | 最小ラベル + 小時計 | 0/0/2/0/0 | 入力欄を隠す/別 UI に寄せる構成。時計中心の少数ラベル。 | 壁紙主役のまま情報量を抑える参考になる。 |
| lootmancerstudios/suminami | config/hypr/hyprlock.conf | 複数ラベル + 小時計 | 1/1/3/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。 | 壁紙主役のまま情報量を抑える参考になる。 |
| TristanDefachel/hyprland-dot-files | hypr/hyprlock.conf | 最小ラベル + 中時計 | 1/1/2/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。 |
| Ctmax-ui/dotfiles | hyprland/.config/hypr/hyprlock.conf | テーマパック + 再生情報 + shape 装飾 + 情報ダッシュボード + 巨大時計 | 1/1/16/0/4 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。shape で線・パネル・区切りを作る。時計以外にシステム情報を多数載せる。時計はかなり強い主役。MPRIS/playerctl で再生情報を出す。 | shape の zindex/線/パネル利用を参考にできる。現方針には情報量が多すぎるが、余白と階層化は参考になる。 |
| Reentryti/Wayland-Dotfiles | - | hyprlock 設定検出なし | - | ローカルには hyprlock 設定ファイルを検出できなかった。 | 直接の layout 参考度は低い。 |
| mem101296/hyprland-dotfile | hypr/hyprlock.conf | シンプル | 1/1/0/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。 | 壁紙主役のまま情報量を抑える参考になる。 |
| VoidedKN0X/VK-Dotfiles | Asus Laptop/.config/hypr/hyprlock.conf | 複数ラベル + 大時計 | 1/0/5/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄を隠す/別 UI に寄せる構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| Noxmor/.dotfiles | hyprlock/.config/hypr/hyprlock.conf | 最小ラベル + 中時計 | 1/1/2/0/0 | 入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。 |
| lievin-christopher/wl-4rch | .config/hypr/hyprlock.conf | 最小ラベル + 小時計 | 1/0/2/0/0 | 入力欄を隠す/別 UI に寄せる構成。時計中心の少数ラベル。 | 壁紙主役のまま情報量を抑える参考になる。 |
| totoluto/hyprland-dotfiles | hypr/hyprlock.conf | 複数ラベル + 大時計 | 1/1/5/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| KeanBP36/KeanBP36-Arch-Hyprland-Config | hypr/hyprlock.conf | 最小ラベル + 中時計 | 1/1/1/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。 |
| ierturk/nixos-config | common/dotfiles/config/hypr/hyprlock.conf | avatar/アート + 最小ラベル + 中時計 + Catppuccin | 1/1/2/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計中心の少数ラベル。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| b2-3c/dotfiles | .config/hypr/hyprlock.conf | avatar/アート + 複数ラベル + 中時計 | 1/1/4/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| RomeoCavazza/hyprland-config | hyprlock.conf | 最小ラベル + 中時計 | 1/1/2/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。 |
| nerdkill/dotfiles | hypr/.config/hypr/hyprlock.conf | 生体認証 | 1/1/0/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。fingerprint/howdy など認証状態の文言がある。 | 壁紙主役のまま情報量を抑える参考になる。 |
| hashdefault/hypreww | .config/hypr/hyprlock.conf | avatar/アート + 最小ラベル + 中時計 | 1/1/2/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| gamesofcactio-source/Hyprland-dotfiles | hypr/hyprlock.conf | 最小ラベル + 中時計 | 1/1/1/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計中心の少数ラベル。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。壁紙主役のまま情報量を抑える参考になる。 |
| Edoko193/dotfiles | .config/hypr/hyprlock.conf | shape 装飾 + avatar/アート + 複数ラベル + 中時計 | 1/1/5/1/1 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。shape で線・パネル・区切りを作る。時計・日付・補助テキストを分離して配置する。時計は中サイズで控えめ。 | shape の zindex/線/パネル利用を参考にできる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| RenderHam/hyprdots | config/hyprlock/layouts/hyprlock.conf | テーマパック + 複数ラベル + 大時計 | 1/1/4/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。 | 時計サイズの上限感が参考になる。 |
| turbomaster95/dotfiles | .config/hypr/hyprlock.conf | avatar/アート + 最小ラベル + 中時計 | 1/1/2/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計中心の少数ラベル。時計は中サイズで控えめ。 | 壁紙主役のまま情報量を抑える参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |
| vargalott/dotfiles | .config/hypr/hyprlock.conf | 複数ラベル + 巨大時計 | 1/1/3/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計はかなり強い主役。 | 壁紙主役のまま情報量を抑える参考になる。 |
| patricks-js/dotfiles | - | hyprlock 設定検出なし | - | ローカルには hyprlock 設定ファイルを検出できなかった。 | 直接の layout 参考度は低い。 |
| molsousa/hyprland-dotfiles | .config/hypr/hyprlock.conf | 再生情報 + 複数ラベル + 大時計 | 1/1/5/0/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。時計・日付・補助テキストを分離して配置する。時計は主役だが周辺要素と併存。MPRIS/playerctl で再生情報を出す。 | 時計サイズの上限感が参考になる。現方針には情報量が多すぎるが、余白と階層化は参考になる。 |
| zeroxanant/kishi-dots | Config/hypr/hyprlock.conf | avatar/アート + 情報ダッシュボード + 中時計 | 1/1/11/1/0 | 背景は壁紙/スクリーンショットを blur・暗色化して文字を読ませる。入力欄は中央付近の標準構成。avatar/album art/アイコンを視線の支点にする。時計以外にシステム情報を多数載せる。時計は中サイズで控えめ。 | 時計サイズの上限感が参考になる。現方針には情報量が多すぎるが、余白と階層化は参考になる。顔/アートを置く設計は今回の壁紙では競合しやすい。 |

## 検出できなかった repo

- shell-ninja/hyprconf-install
- SherLock707/hyprland_dot_yadm
- SherLock707/hyprland_dots
- ufuayk/hyprconf-gen
- lukaszkowalik2/dotfiles
- yashjodon/YashJodon-Dots
- offyotto/howdy-surface
- Reentryti/Wayland-Dotfiles
- patricks-js/dotfiles

## 参考度が高い候補

- `AT0117/dots`: 大時計 + shape 罫線。今回の短い罫線の技術比較に向く。
- `MagicExist/archlinux-dotfiles`: image + shape + now playing の複合。情報量は多いが、shape の重ね方は参考になる。
- `Edoko193/dotfiles`: avatar/image と shape を併用。今回とは逆に「支点を追加する」設計なので、避ける判断材料になる。
- `zDyant/HyprNova`, `SeakMengs/dotfiles`, `jude7733/hypr`: 大時計を中央寄せで扱う系。時計サイズの上限感を見る比較対象。
- `xeji01/neulock`, `mahaveergurjar/Hyprlock-Dots`, `ezerfrlux/omarchy-config`: テーマパック。個別の完成形より、レイアウトバリエーションの棚卸しに向く。
