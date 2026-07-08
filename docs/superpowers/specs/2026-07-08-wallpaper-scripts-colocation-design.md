# 壁紙ワークフローのコロケーション整理 設計

- 対象: リポジトリ直下 `scripts/`・`home-manager/desktop/hyprland/`・`home-manager/desktop/matugen/`・`images/`
- 前提: hyprlock 時計リデザイン（`2026-07-08-hyprlock-clock-contrast-design.md`）で lock 関連スクリプトが増えた直後の整理

## 背景と問題（コロケーションチェック結果）

hyprlock / 壁紙関連のファイルが 4 ディレクトリに分散し、壁紙変更のワークフローが暗黙知になっている。

1. `matugen/templates/lock-colors.conf` は matugen のランタイム設定（`config.toml`・`default.nix`）から一切参照されない **見せかけの同居**。実際は `gen-lock-colors.sh` 専用のオフラインテンプレート。
2. `hyprland/scripts/` はランタイムスクリプト（hyprlock が呼ぶ `lock-clock.sh`、hyprland の操作系）とリポジトリ専用ツール（`gen-lock-colors.sh` / `gen-lock-scrim.sh` / `lock-preview.sh`）が混在。後者は `~/.config/hypr/scripts` に lnk される必要がない。
3. 壁紙変更手順（lock.jpg 差し替え → 色再生成 → コミット）がどこにも実装・文書化されていない。
4. login 壁紙は regreet（nixos 管轄）のため、hyprland 配下では壁紙ワークフローをコロケーションできない構造的制約がある。

## 設計原則: 2 軸で分ける

- **機能軸（ランタイムに必要なもの）**: 各機能ディレクトリに置く。hyprlock が実行時に読むもの（`hyprlock.conf`・生成物 `lock-colors.conf`・`lock-clock.sh`・`lock-scrim.png`・`lock.jpg`）と regreet のランタイム設定は現状の場所を維持。
- **壁紙ワークフロー軸（オフラインのリポジトリ操作）**: リポジトリ直下 `scripts/wallpaper/` に集約。機能を横断する（hyprlock / regreet）ため機能ディレクトリには置けず、ここが唯一のコロケーション点。`images/` はデータ（store と適用先）、`scripts/wallpaper/` はそれを操作するワークフロー。
- `scripts/` 直下が太らないよう、壁紙系はサブディレクトリ `wallpaper/` に閉じ込める（CLAUDE.md「並列物は 1 つ下の階層」の適用）。既存の bootstrap / agenix 系スクリプトは触らない。

## 変更一覧

| 種別 | 現在                                                                                                   | 変更後                                                    |
| ---- | ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------- |
| 移動 | `home-manager/desktop/hyprland/scripts/lock-preview.sh`                                                | `scripts/wallpaper/lock-preview.sh`                       |
| 移動 | `home-manager/desktop/hyprland/scripts/gen-lock-colors.sh`                                             | `scripts/wallpaper/gen-lock-colors.sh`                    |
| 移動 | `home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh`                                              | `scripts/wallpaper/gen-lock-scrim.sh`                     |
| 移動 | `home-manager/desktop/matugen/templates/lock-colors.conf`                                              | `home-manager/desktop/hyprland/lock-colors.template.conf` |
| 新規 | —                                                                                                      | `scripts/wallpaper/switch-lock.sh`                        |
| 新規 | —                                                                                                      | `scripts/wallpaper/switch-login.sh`                       |
| 維持 | `hyprland/scripts/lock-clock.sh`・`hyprlock.conf`・`lock-colors.conf`・`images/lock/`・`images/login/` | そのまま                                                  |

テンプレートは hyprlock の色トークン（`$lock_*`）定義そのものなので、生成物 `lock-colors.conf`・消費者 `hyprlock.conf` と同じ `hyprland/` に置く（機能軸）。

### 参照の更新

- `gen-lock-colors.sh` の `TEMPLATE` パスを `hyprland/lock-colors.template.conf` へ変更。`gen-lock-scrim.sh` は `git rev-parse` の ROOT 相対パスのみで移動の影響なし（確認はする）。
- `hyprland/default.nix` は変更不要: `hypr/scripts` はディレクトリごと lnk なので、移動したファイルは自然に消える。テンプレートは lnk 対象外（リポジトリ内オフライン専用）。matugen 側も元々未参照で変更不要。
- 過去の spec / plan ドキュメント内の旧パス記述は履歴なので書き換えない。

## 新規スクリプト仕様

### `scripts/wallpaper/switch-lock.sh <画像パス>`

lock 壁紙のワンコマンド切替。将来の quickshell 壁紙選択 UI（desktop / lock / login タブ）はこのスクリプトを呼ぶだけにし、ロジックを二重化しない。

1. 引数の画像を `images/lock/lock.jpg` へコピー。JPEG 以外（PNG 等）は `nix run nixpkgs#imagemagick` で jpg に変換（lnk と `hyprlock.conf` の参照名を `lock.jpg` 固定に保つため）。
2. `gen-lock-colors.sh` を呼び色トークンを再生成。
3. `gen-lock-scrim.sh` を呼び scrim を再生成（壁紙非依存だが冪等で、アセットの存在保証を兼ねる）。
4. 変更ファイル（`git status --short` 相当）を表示し、確認とコミットを促す。
5. 反映は lnk のライブ反映のみで `nix run .#switch` 不要である旨を出力。

### `scripts/wallpaper/switch-login.sh <画像パス>`

login（regreet）壁紙のワンコマンド切替。

1. 引数の画像を `images/login/login.png` へコピー。PNG 以外（JPEG 等）は ImageMagick で png に変換（greetd 設定の参照名 `login.png` 固定のため）。
2. **`nix run .#switch` が必要**である旨を必ず出力する（regreet は `default.nix` の Nix パス補間で画像を /nix/store へ焼き込むため、ファイル差し替えだけでは反映されない）。
3. 色生成は行わない。regreet は現状 Tokyonight 静的テーマで、matugen 由来テーマ生成（todo.md の構想）は将来この関数に追記するスコープ。

### 将来増えるもの / 増えないもの

- 増える: quickshell UI の login タブで matugen テーマ生成が必要になったら `switch-login.sh` を拡張。
- 増えない見込み: `switch-desktop.sh`。デスクトップ壁紙は既存のランタイム機構（`hyprland/scripts/wallpaper/` + pyprland + matugen）が担当し、リポジトリへのコミットを伴わない。

## 受け入れ基準

- `scripts/wallpaper/` に 5 本（switch-lock / switch-login / gen-lock-colors / gen-lock-scrim / lock-preview）が揃い、`hyprland/scripts/` にはランタイムスクリプトのみ残る。
- `~/.config/hypr/scripts/`（lnk）からリポジトリ専用ツールが消えている。
- `matugen/templates/` は matugen ランタイムが使うテンプレートのみになる。
- `switch-lock.sh` を現行の `images/lock/lock.jpg` 自身に対して実行すると冪等に完走する（画像・色・scrim が実質無変化で再生成される）。
- `switch-login.sh` を現行の `images/login/login.png` 自身に対して実行すると冪等に完走し、switch 必要の案内が出る。
- `./scripts/wallpaper/lock-preview.sh` が新パスで動作しスクリーンショットが撮れる。
- `nix run .#build` と `nix run .#fmt -- --fail-on-change` が緑。
