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

- ロック画面のデザイン調整 ⚠️ 要再設計（第一稿は不採用レベル）
  - caelestia 風の右上時刻表示を hyprlock（label + shape + Pango マークアップ + `lock-clock.sh`）で実装したが、**実機の見た目が参考デザインを全く再現できていない**。フォント・数値調整以前の、構造・比率・レイアウトの問題。現状のまま実機に残してあるが未完。
  - 実装物: `home-manager/desktop/hyprland/hyprlock.conf`（右上クラスタ）、`scripts/lock-clock.sh`（時刻/日付マークアップ生成）、`lock-colors.conf` / `matugen/templates/lock-colors.conf`（役割ベース色トークン）。設計 `docs/superpowers/specs/2026-07-06-hyprlock-clock-redesign-design.md` / 計画 `docs/superpowers/plans/2026-07-06-hyprlock-clock-redesign.md`。
  - 問題点（再設計時の起点）:
    - 参考（caelestia の `DesktopClock.qml`、ソース: `ghq/github.com/dim-ghub/caelestia-shell`）の見た目を hyprlock の絶対座標 + 個別ラベルで組む方式では、比率・間隔・整列が破綻しやすい。数字/区切り線/日付カラムの相対配置とサイズ比が肝で、px 手調整では追い込めていない。
    - caelestia は QML の RowLayout/ColumnLayout で相対レイアウト＋バリアブルフォント（GoogleSansFlex, 丸み軸 ROND=25）。hyprlock は自動レイアウト無し・フォント軸制御不可のため、そもそも忠実再現に限界がある可能性。**quickshell で自前ウィジェットとして作る／別方式**も含めてアプローチから再検討する。
    - 色は動くが、hour=primary / minute=colon=secondary / day=primary の割り当ての妥当性も要再考。

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

## Cachix による CI ビルドキャッシュの導入 ✅ 完了

Renovate の lock 更新 PR で `build (nixos)` が 30 分タイムアウトしていた真因は、公開キャッシュに無い独自ビルドの Rust パッケージ `herdr` と `anime-games-launcher`（follows で nixpkgs 追従のため lock 更新ごとに再ビルド）。hyprland ではなかった。

対策として public キャッシュ `mkiin-dotfiles.cachix.org` を作成し、CI の `nix-build.yaml` に `cachix/cachix-action` を追加してビルド成果物を push、`flake.nix` の substituter に追加してローカル/CI 両方で substitute する。あわせて `timeout-minutes` を 30→60 に緩和（初回ソースビルドの安全網。public ランナーは無料無制限）。1 回の push は約 42 MB で 5GB 枠に十分収まる。設計は `docs/superpowers/specs/2026-07-06-cachix-ci-build-cache-design.md`。
