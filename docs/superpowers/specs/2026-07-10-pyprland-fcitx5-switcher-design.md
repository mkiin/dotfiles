# pyprland fcitx5_switcher によるターミナルの IME 自動オフ

## 背景

wezterm と ghostty にフォーカスしたとき、IME が有効なままだとコマンド入力の先頭で意図しない変換が起きる。
ターミナルではデフォルトで IME をオフにしたい。

現在の設定には、この目的を妨げる要因が二つある。

一つは fcitx5 側にある。
`home-manager/desktop/fcitx5/config` の `Behavior` セクションで `ShareInputState=All` が指定されており、IME のオン/オフ状態がシステム全体で一つしか存在しない。
どのウィンドウにフォーカスしていても同じ状態を見ることになる。

もう一つは、ウィンドウのフォーカスに応じて IME を切り替える仕組みが存在しないことである。

## 目標と非目標

ターミナルにフォーカスするたび、IME を無条件でオフにする。
ターミナル内で手動で IME をオンにしても、他のウィンドウを経由して戻ってくれば再びオフになる。
この挙動を採る理由は、ターミナルで日本語を入力する機会がほとんどないからである。

ターミナル以外のアプリケーションの IME 状態には介入しない。
どのアプリケーションで IME を自動的にオンにするかは、今回の検討範囲に含めない。

## 採用する仕組み

pyprland に同梱の `fcitx5_switcher` プラグインを使う。
このプラグインは Hyprland の `activewindowv2` イベントを受け取り、アクティブになったウィンドウの class と title を設定値と突き合わせる。
`inactive_classes` に一致すれば `fcitx5-remote -c` を、`active_classes` に一致すれば `fcitx5-remote -o` を実行する。
一致しなければ何もしない。

あわせて fcitx5 の `ShareInputState` を `No` に変える。
これは IME の状態をプログラムごとに独立して保持する設定である。
この変更がないと、プラグインがターミナルで発行した `fcitx5-remote -c` が唯一のグローバル状態を書き換えてしまい、ターミナルを一瞬覗いただけで他のアプリケーションの IME まで落ちる。

## 変更するファイル

**`home-manager/desktop/fcitx5/config`**：`Behavior` セクションの `ShareInputState` を `All` から `No` に変更する。

**`home-manager/desktop/pyprland/default.nix`**：`xdg.configFile."pypr/config.toml"` の `plugins` に `"fcitx5_switcher"` を追加し、次のセクションを足す。

```toml
[fcitx5_switcher]
inactive_classes = ["org.wezfurlong.wezterm", "com.mitchellh.ghostty"]
```

`active_classes`、`active_titles`、`inactive_titles` は記述しない。
プラグインの既定値である空リストに任せる。

パッケージ宣言の変更は不要である。
`pyprland` は `home-manager/desktop/packages.nix` に、`fcitx5-remote` は `nixos/desktop/fcitx5` の `i18n.inputMethod` 経由で、それぞれ既に PATH 上にある。
プラグインは Hyprland の `execr` ディスパッチャ経由でコマンドを起動するため、セッションの PATH が通っていれば足りる。

pyprland の systemd user service には `X-Restart-Triggers` として `config.toml` が既に登録されている。
`nix run .#switch` を実行すれば、生成された config の変化を検出して daemon が再起動し、新しいプラグインが読み込まれる。
unit 定義に手を入れる必要はない。

## 実行時の挙動

Zen で日本語を入力している最中にターミナルへフォーカスを移すと、ターミナルの IME はオフになる。
fcitx5 が状態をプログラムごとに保持しているため、Zen 側のオン状態は保たれる。
Zen に戻れば日本語入力を続けられる。

ターミナル内で `Alt_R` を押して一時的に IME をオンにすることはできる。
ただし他のウィンドウを経由して戻ってくれば、プラグインが再び `-c` を発行してオフになる。

エラー処理は設けない。
`fcitx5-remote -c` は fcitx5 が停止していれば失敗するが、プラグインは結果を待たずに投げるだけなので、ウィンドウ操作そのものには影響しない。
fcitx5 は `graphical-session.target` に紐づく user service として常時起動しており、停止している状況は実質的に考えなくてよい。

## 検証の手順

二段階に分けて反映する。
fcitx5 の設定変更と pyprland のプラグイン有効化を同時に入れると、期待どおりに動かなかったときにどちらが原因か切り分けられないためである。

### 第一段階：`ShareInputState=No` だけを反映する

確認するのは、fcitx5 が wezterm と ghostty を別プログラムとして識別できているかどうかの一点である。
これが自明でないのは、fcitx5 がフォーカス中のプログラム名を知る経路が Wayland では一本ではないからだ。
GTK や Qt のアプリケーションは IM モジュール経由でプログラム名を渡すが、wezterm と ghostty は Wayland の text-input プロトコルを直接使うため、プログラム名が fcitx5 に届かない可能性がある。

`nix run .#switch` の後、Zen で IME をオンにし、ターミナルにフォーカスを移して引数なしの `fcitx5-remote` を実行する。
このコマンドは現在の IME 状態を数値で返す。
`0` が返れば非アクティブ、つまりターミナルが独立した状態を持っている。
`2` が返れば状態が共有されており、識別が効いていない。

さらに詳しく見るなら、fcitx5 のログを上げて InputContext に紐づく program 名を観察する。

```
systemctl --user stop fcitx5
FCITX_LOG_RULES='default=5' fcitx5 -d --verbose '*=5' 2>&1 | tee /tmp/fcitx5.log
```

program が空文字のままなら、識別できていない。

### 識別が効かなかった場合の対処

`ShareInputState` を `All` に戻し、巻き添えオフを受け入れる。
pyprland 側の設定は変わらない。
ターミナルを覗くと他のアプリケーションの IME も落ちるという副作用は残るが、ターミナルがデフォルトで IME オフになるという目的そのものは達成される。
落ちた IME は `Alt_R` で戻せる。

### 第二段階：プラグインを有効化する

`nix run .#switch` の後、三つを確認する。

ghostty を起動し、`hyprctl clients` の出力で class が `com.mitchellh.ghostty` であること。
異なる場合は実測値に合わせて設定を直す。
wezterm の class が `org.wezfurlong.wezterm` であることは既に実機で確認済みである。

ターミナルにフォーカスした状態で `fcitx5-remote` が `0` を返すこと。

ターミナルで `Alt_R` を押して `2` になった後、他のウィンドウを経由して戻ると `0` に戻ること。

自動テストは書かない。
Hyprland のウィンドウフォーカスと fcitx5 の D-Bus 状態という、実機の対話環境でしか再現しない振る舞いだからである。
上記の手動確認を受け入れ条件とする。
