# やりたいことリスト

## GitHubActionのPR内容と成功・失敗のディスコード通知

-

## 初回セットアップの自動化

- R2 から壁紙を復元するスクリプトの作成（現状は手動で `images/wallpaper/` に配置する必要がある）
- 初回起動時に `colors.css` / `colors-waybar.css` が存在せず waybar が起動できない問題の恒久対応
  - home-manager activation でフォールバック色ファイルを生成する案（R2 復元前でも waybar が起動できるようにする）
- `~/.config/scripts/notify.sh` が存在せず壁紙適用の最後でエラーになる問題の調査・修正

## pyprlandの導入

### workspace_follow_focus

ワークスペースとモニターを一致する問題を解消でき、1つのモニター内で複数のワークスペースを保持できる

### monitors

ベッドモードとデスクモードを自前スクリプトで管理していたのを、pyprlandのmonitors機能で代替えする。モニタープロファイル機能を提供する。

### scratchpads

### その他

- toggle_special
- lost_windows
- fcitx5_switcher

## 壁紙選択ランチャーの作成

quickshellで作成するが、参考になるデザインがまだみつかっていないため保留。
機能としては、ロック画面およびログイン画面、デスクトップの壁紙を選択でき、ロック、ログイン画面は選択した際にバックグラウンドでmatugen由来のテーマを作成する。

## 壁紙をR2に保存する処理の作成

今後、壁紙が増えていくとgitで管理した際に容量が大きくなるため、images/wallpaperのみcloudflareのR2にバックアップを行う。イベントか定期か保存タイミングについてはR2の課金体型を調べてから決める。

## 他パッケージの追加と設定

- 画面録画 : gpu-screen-recorder(record.sh)を維持。wl-screenrec は NVIDIA proprietary driver だと VA-API 前提で HW エンコードが実質動かないため見送り。Super+R のトグルは実装済み(PIDファイル + SIGINT)。二重録画バグは解消。

- hyprfocus : 導入済み(hyprwm/hyprland-plugins、flash アニメでフォーカス強調)。

- fastfetch : システム情報を表示するCLI。

## 見た目・リファクタリング

- ログイン画面のデザインがひどすぎる
- 画像が低解像度(選択している画像が悪い？)
- sddmに劣るデザイン

- ロック画面のデザイン調整
- 時計と日付のサイズを大きくしたい。

- waybarのリデザイン
- 1つ1つのモジュールにクリックアクションを割り当てすぎ
- quickshellのコントロールセンターなどがあるため、クリック範囲をまとめるか、消すか
  - idle_inhibitor、通知アイコン、等々

- バー全体のデザインをリキッドグラス風のモダンなものにしたい
- 色ベタ塗り感が強め
- もう少し壁紙から浮いている感出したい

## quickshellの大規模リファクタリング

- wallustを使用しているのに、変数名がpywal
- コード量が単純に多いため、スメルコードが大量にあると予想
- bluetoothモジュール・オーディオセレクタポップアップにて、一覧がなにもないときの幅と高さが壊れているのを修正
- ↑のconfigボタンについて、クリックメニューを作っていないため空ナノを解消
- ↑別途仕様作成が必要なので、後回し

## 壁紙ランダムスクリプトのリファクタリング

- pyparlandのwallpapersを利用して、自作を代替えする

## README.mdの改修

- riceを構築している人のREADME.mdを真似して、あわよくばスターを狙いたい。

## miseの自動アップデート

github actionかなんかで、自動でアップデートするようにしたい。

## oil.nvim の gitignore 非表示（保留）

ファイラーを neo-tree から oil.nvim に移行した際の積み残し。

- 「gitignore 対象を常に非表示」にしたいが、oil には native の gitignore フィルタが無い。
- `view_options.is_hidden_file` で `git check-ignore` / `git ls-files` を噛ませれば「hidden 扱い」にはできるが、oil の隠し区分は1種類だけなので `g.`（toggle_hidden）を押すと dotfiles と一緒に必ず出てくる。「トグルでも絶対に出さない」は oil では不可。
- 現状は素の `show_hidden`（dotfiles トグルのみ）で妥協。gitignore 隠しが本当に欲しくなったら公式 recipes の is_hidden_file + git キャッシュ実装（doc/recipes.md）を導入するか検討する。

## パスワードの宣言的管理（agenix）

`mutableUsers`（現状デフォルト true）だと `passwd` で設定したパスワードがクリーンインストールで消えるため、宣言的に固定したい。public リポジトリなのでハッシュ直書きは避け、agenix で暗号化管理する。`agenix` は flake input には入っているが未配線。

### 方針

- root と user（mkiin）の両方のパスワードを管理する。
- ハッシュは `mkpasswd -m yescrypt` で生成し、agenix で暗号化して `.age` を Git にコミットする。
- 復号鍵の構成は未決（個人鍵をマスターにする案を推奨。host key は再インストールで作り直されるため単体だと復元できない）。

### 前提・ブロッカー

- このマシンには SSH host key が無い（openssh 無効、`/etc/ssh` に host key なし）。host key 方式を使うなら `services.openssh.enable = true` 等で先に生成が必要。
- 復号鍵自体のバックアップ運用を決めないと「再インストールでも変わらない」が成立しない。

### 作業

- [ ] 復号鍵の構成を決める（個人鍵マスター + host key 併用 / host key のみ / 個人鍵のみ）
- [ ] `secrets/secrets.nix` を作成し、公開鍵を登録する
- [ ] `secrets/user-password.age` / `secrets/root-password.age` を `agenix -e` で作成する
- [ ] NixOS モジュールで agenix を配線する（`age.secrets.*`）
- [ ] `users.users.mkiin.hashedPasswordFile` と root の `hashedPasswordFile` を設定する
- [ ] `mutableUsers = false` にするか検討する（false にすると passwd 変更が無効になる）
- [ ] `nix run .#build` で検証してから switch する
