# やりたいことリスト

## GitHubActionのPR内容と成功・失敗のディスコード通知

- 未着手

## 初回セットアップの自動化

- `~/.config/scripts/notify.sh` が存在せず壁紙適用の最後でエラーになる問題の調査・修正

## pyprlandの導入

### scratchpads

見送り。vesktop(Electron 単一インスタンス)の窓追跡が安定せず、pyprland の手動スライドが Hyprland のアニメと衝突するため撤去した。

## 壁紙選択ランチャーの作成

quickshellで作成するが、参考になるデザインがまだみつかっていないため保留。
機能としては、ロック画面およびログイン画面、デスクトップの壁紙を選択でき、ロック、ログイン画面は選択した際にバックグラウンドでmatugen由来のテーマを作成する。

### UI とスクリプトの想定（2026-07-09 時点の設計メモ）

- UI: quickshell 製。desktop / lock / login の 3 タブ。選択元 store は `images/wallpaper/`。
- タブごとに切替時へ呼ぶ処理:
  - **desktop**: 既存のランタイム機構（`hyprland/scripts/wallpaper/` + pyprland + matugen）を呼ぶだけ。リポジトリへのコミットなし。
  - **lock**: `switch-lock` 相当のスクリプトを新設して呼ぶ。中身は store の画像を `images/lock/lock.jpg` へ cp（PNG は jpg 変換）→ `hyprland/scripts/lock/gen-lock-colors.sh` で色トークン再生成 → コミット促し。lnk のライブ反映のみで rebuild 不要。
  - **login**: `switch-login` 相当のスクリプトを新設して呼ぶ。中身は store の画像を `images/login/login.png` へ cp（JPEG は png 変換）→ matugen 由来テーマ生成（regreet 用。未設計）。regreet は `inputs.self` で store に焼き込むため **`nix run .#switch` が必須**。
- switch スクリプトの置き場は UI 実装時に決める（UI と同居 or `hyprland/scripts/lock/`）。呼び出し規約（引数・通知・store 走査）も UI 側の要件が出てから確定する。
- 経緯・コロケーション方針は `docs/superpowers/specs/2026-07-08-wallpaper-scripts-colocation-design.md` を参照。

## 他パッケージの追加と設定

- fastfetch : システム情報を表示するCLI。

## 見た目・リファクタリング

- ログイン画面のデザインがひどすぎる
- 画像が低解像度(選択している画像が悪い？)
- sddmに劣るデザイン

- ロック画面のデザイン調整 ✅ 完了（左下ポスター時計へ再々設計）
  - caelestia 風右上時計（2026-07-06 / 2026-07-08 spec）は不採用とし、左下ポスター型（Anton 極太 2 トーン時刻 + 大文字フルスペル日付 + 左下コーナー減光）で確定。
  - 設計 `docs/superpowers/specs/2026-07-09-hyprlock-poster-clock-design.md` / 計画 `docs/superpowers/plans/2026-07-09-hyprlock-poster-clock.md`。

- waybarのリデザイン ✅ 完了
- 1つ1つのモジュールにクリックアクションを割り当てすぎ
- quickshellのコントロールセンターなどがあるため、クリック範囲をまとめるか、消すか
  - idle_inhibitor、通知アイコン、等々

- バー全体のデザインをリキッドグラス風のモダンなものにしたい ✅ 完了
- 色ベタ塗り感が強め
- もう少し壁紙から浮いている感出したい

## quickshellの大規模リファクタリング ✅ 完了

23,000 行 → 8,000 行。死蔵モジュール（quickshell 製バー/sidebar/dashboard/osd）を削除し、
audio/bluetooth の別 config（shell のほぼ完全コピー ×2）を shell 常駐の popouts + IPC へ統合。
Pywal→Colours 改名と Theme 意味トークンへの参照統一、Appearance 寸法トークンの一本化と
生数値 400+ 箇所の全面置換（caelestia-dots/shell の QML 構造に準拠）。
bluetooth ポップアップの空リスト時に高さが潰れる問題も修正。
スクリーンショット/録画は hyprland/scripts/{screenshot,record}.sh を正とし quickshell 側は呼ぶだけに縮小。
設計 `docs/superpowers/specs/2026-07-12-quickshell-refactor-design.md` /
計画 `docs/superpowers/plans/2026-07-12-quickshell-refactor.md`。

- 残: popouts の config ボタンのクリックメニューが空（別途仕様作成が必要なので後回し）

## 壁紙ランダムスクリプトのリファクタリング

- [x] pyparlandのwallpapersを利用して、自作を代替えする

## README.mdの改修

- riceを構築している人のREADME.mdを真似して、あわよくばスターを狙いたい。

## miseの自動アップデート

github actionかなんかで、自動でアップデートするようにしたい。

## ファイラーの gitignore 非表示 ✅ 完了

oil.nvim では「dotfiles は出すが gitignore 対象は出さない」が実現できなかった。oil の隠し区分は 1 種類しかなく、`g.`（toggle_hidden）で両方が同時に出てくるため。

snacks.explorer への移行で解決した。`hidden`（dotfiles）と `ignored`（gitignore 対象）が独立した設定であり、トグルも `H` と `I` に分かれている。`editor.lua` で `explorer = { hidden = true }` とし、`ignored` は既定の false のままにしてある。

## パスワードの宣言的管理（agenix）✅ 完了

root と mkiin に同一の yescrypt ハッシュを agenix で付与（`nixos/core/secrets/password.age`）。`mutableUsers = false`、両者に `hashedPasswordFile`、username 完全一致アサーション入り。復号鍵は個人 age 鍵マスター、rbw で保管/復元。実機の `sudo`/`su` で動作確認済み。設計・計画は `docs/superpowers/{specs,plans}/2026-07-04-declarative-password-agenix*`。

## Cachix による CI ビルドキャッシュの導入 ✅ 完了

Renovate の lock 更新 PR で `build (nixos)` が 30 分タイムアウトしていた真因は、公開キャッシュに無い独自ビルドの Rust パッケージ `herdr` と `anime-games-launcher`（follows で nixpkgs 追従のため lock 更新ごとに再ビルド）。hyprland ではなかった。

対策として public キャッシュ `mkiin-dotfiles.cachix.org` を作成し、CI の `nix-build.yaml` に `cachix/cachix-action` を追加してビルド成果物を push、`flake.nix` の substituter に追加してローカル/CI 両方で substitute する。あわせて `timeout-minutes` を 30→60 に緩和（初回ソースビルドの安全網。public ランナーは無料無制限）。1 回の push は約 42 MB で 5GB 枠に十分収まる。設計は `docs/superpowers/specs/2026-07-06-cachix-ci-build-cache-design.md`。

## スクリーンショットの画面範囲セレクトをショートカットではなくquikcshellによるUIで選択させる方式にする

- BlackNodeの機能をインスパイア[https://github.com/zhaleff/BlackNode/blob/master/Assets/HyprShot.png]

## アプリランチャーをrofiに変更 ✅ 完了

HynDuf 風 rofi ランチャー(3モード drun/filebrowser/window)に置換。配色は matugen 連動
(surface 階層で凹み/浮きを表現)、検索バー上部は launch.sh が last_wallpaper を読み
-theme-str で現壁紙をプレビュー注入。quickshell ランチャーは撤去。
設計 `docs/superpowers/specs/2026-07-11-rofi-app-launcher-design.md` /
計画 `docs/superpowers/plans/2026-07-11-rofi-app-launcher.md`。

## weztermでclaudecodeの生成終了時に通知を出す

- swayncでできる？
- 設計判断必要
- claude code標準でできるか
