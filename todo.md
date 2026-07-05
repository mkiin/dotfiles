# やりたいことリスト

## GitHubActionのPR内容と成功・失敗のディスコード通知

-

## 初回セットアップの自動化

- `~/.config/scripts/notify.sh` が存在せず壁紙適用の最後でエラーになる問題の調査・修正

## pyprlandの導入

### scratchpads

見送り。vesktop(Electron 単一インスタンス)の窓追跡が安定せず、pyprland の手動スライドが Hyprland のアニメと衝突するため撤去した。

## 壁紙選択ランチャーの作成

quickshellで作成するが、参考になるデザインがまだみつかっていないため保留。
機能としては、ロック画面およびログイン画面、デスクトップの壁紙を選択でき、ロック、ログイン画面は選択した際にバックグラウンドでmatugen由来のテーマを作成する。

## 他パッケージの追加と設定

- fastfetch : システム情報を表示するCLI。

## 見た目・リファクタリング

- ログイン画面のデザインがひどすぎる
- 画像が低解像度(選択している画像が悪い？)
- sddmに劣るデザイン

- ロック画面のデザイン調整
  - 時計と日付のサイズを大きくしたい。下参考例 リンク:https://www.reddit.com/r/hyprland/comments/1ubib86/bad_caelestia_apple/
    AM |JUNE
    12:12 |21
    |Sunday

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
- スクリーンショット系をquickshellで自前で持っている。screen.shを統合する

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

## パスワードの宣言的管理（agenix）✅ 完了

root と mkiin に同一の yescrypt ハッシュを agenix で付与（`nixos/core/secrets/password.age`）。`mutableUsers = false`、両者に `hashedPasswordFile`、username 完全一致アサーション入り。復号鍵は個人 age 鍵マスター、rbw で保管/復元。実機の `sudo`/`su` で動作確認済み。設計・計画は `docs/superpowers/{specs,plans}/2026-07-04-declarative-password-agenix*`。

## Cachix による CI ビルドキャッシュの導入

`nix build`（特に nixos toplevel、CI で 1 回約 28 分）を短縮するため、自前 Cachix を CI に組み込む。Renovate 移行が落ち着いてから着手する。

- OSS/public は 5GB 無料枠。private 化しない前提なので、この枠に収まる範囲でやりくりする。
- 既存の `cache-nix-action`（GH Actions cache に `/nix/store`）と `hyprland.cachix.org` substituter に加え、自前 Cachix を substituter + push 先にする。一度ビルドした成果物を CI 間で substitute して再ビルドを避けるのが狙い。
- 必要作業: cachix アカウントとキャッシュ作成、`CACHIX_AUTH_TOKEN` を secret 登録、`setup-nix` か `nix-build` に `cachix/cachix-action` を追加。
- これは料金削減ではなく待ち時間の短縮（public なので Actions 自体は無料）。効果が薄ければ `lockFileMaintenance` の週次化で代替する。
