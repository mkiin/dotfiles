# hyprlock 関連ファイルのコロケーション整理 設計

- 対象: `home-manager/desktop/hyprland/`・`home-manager/desktop/matugen/`
- 前提: hyprlock 時計リデザイン（`2026-07-08-hyprlock-clock-contrast-design.md`）で lock 関連スクリプトが増えた直後の整理
- 改訂: 初稿の「リポジトリ直下 `scripts/wallpaper/` へ集約 + switch スクリプト新設」案は、root `scripts/` の肥大化懸念と「誰が・何を・どうやって使うか」の再分析により破棄。本稿が確定版。

## 背景と問題（コロケーションチェック結果）

1. `matugen/templates/lock-colors.conf` は matugen のランタイム設定（`config.toml`・`default.nix`）から一切参照されない**見せかけの同居**。実際は `gen-lock-colors.sh` 専用のオフラインテンプレートで、定義しているのは hyprlock の色トークン（`$lock_*`）。
2. `hyprland/scripts/` 直下で lock 専用スクリプト 4 本（`lock-clock.sh` / `gen-lock-colors.sh` / `gen-lock-scrim.sh` / `lock-preview.sh`）が hyprland 汎用の操作系（`mode.sh` / `record.sh` / `screenshot.sh` 等）と混在。
3. 壁紙変更のワークフロー（lock.jpg 差し替え → 色再生成 → コミット）がどこにも文書化されていない。

## 利用者分析（誰が・何を・どうやって）

| ファイル                                 | 誰が使う                   | いつ・どうやって                 | 帰結                 |
| ---------------------------------------- | -------------------------- | -------------------------------- | -------------------- |
| `lock-clock.sh`                          | hyprlock                   | 実行時（lnk 経由で cmd 実行）    | 機能側・lnk 必須     |
| `lock-colors.conf`（生成物）             | hyprlock                   | 実行時に source                  | 機能側・lnk 必須     |
| `lock-colors.template.conf`              | `gen-lock-colors.sh`       | オフライン・リポジトリ内参照のみ | 生成物・消費者の隣へ |
| `gen-lock-colors.sh` `gen-lock-scrim.sh` | 人間（壁紙・見た目変更時） | オフライン・リポジトリ内で実行   | lock 専用 → 機能側   |
| `lock-preview.sh`                        | 人間 / AI（開発時）        | 実機セッションで実行             | lock 関連に同居      |
| `switch-lock/login.sh`（構想）           | 将来の quickshell 壁紙 UI  | ユーザーセッションから実行       | **今回は作らない**   |

## 設計

### 1. `hyprland/scripts/lock/` へ lock 系スクリプトを区画整理

既存の `scripts/wallpaper/`・`scripts/waybar/` サブディレクトリの前例に倣い、`hyprland/scripts/lock/` を新設して 4 本を移動する。

- `scripts/lock/lock-clock.sh`（ランタイム。`hyprlock.conf` の cmd パスを `~/.config/hypr/scripts/lock/lock-clock.sh` へ更新）
- `scripts/lock/gen-lock-colors.sh`
- `scripts/lock/gen-lock-scrim.sh`
- `scripts/lock/lock-preview.sh`

`hypr/scripts` はディレクトリごと lnk 済みなので **Nix 側の変更は不要**（サブディレクトリは自動で追従、ライブ反映）。

### 2. 迷子テンプレートの引っ越し

`matugen/templates/lock-colors.conf` → `hyprland/lock-colors.template.conf`。

- トークン定義（テンプレート）・生成物（`lock-colors.conf`）・消費者（`hyprlock.conf`）が同一ディレクトリに揃う。
- `gen-lock-colors.sh` の `TEMPLATE` パスを更新。テンプレートとスクリプトのヘッダコメントの相互参照パスも更新。
- `matugen/templates/` は matugen が実行時に使うテンプレートだけになる。

### 3. 壁紙変更ワークフローの明文化

`gen-lock-colors.sh` のヘッダコメントに手順を明記する:

1. `images/lock/lock.jpg` を差し替える（jpg のまま。参照名は lnk と conf で固定）
2. `./home-manager/desktop/hyprland/scripts/lock/gen-lock-colors.sh` を実行して色トークンを再生成
3. `lock.jpg` と `lock-colors.conf` をコミット（scrim は壁紙非依存なので再生成不要。反映は lnk のライブ反映のみで `nix run .#switch` 不要）

### 4. switch スクリプトは作らない（YAGNI）

`switch-lock.sh` / `switch-login.sh` の主たる利用者は**まだ存在しない quickshell 壁紙選択 UI**（desktop / lock / login の 3 タブ構想、store は `images/wallpaper/`）。呼び出し規約（引数・通知・store 走査）は UI 設計時にしか決められないため、そのときに置き場（UI と同居 or 本 lock/ ディレクトリ）ごと設計する。login（regreet、Nix パス補間のため要 `nix run .#switch`）も同様に保留。

### 変更しないもの

- `images/lock/`・`images/login/`・`images/wallpaper/`（データ置き場。2026-06-30 images 集約設計のまま）
- `hyprland/default.nix`・`matugen/default.nix`（lnk 配線に変更なし）
- regreet（`nixos/desktop/greetd/`）
- 既存の root `scripts/`（bootstrap / agenix 系）

## 受け入れ基準

- `hyprland/scripts/` 直下は hyprland 汎用スクリプトのみ、lock 系 4 本は `scripts/lock/` に揃う。
- `matugen/templates/` に lock 関連が残っていない。
- ロック画面が正常動作する（`lock-preview.sh` のスクリーンショットで時計・日付が描画されている = 新パスの `lock-clock.sh` が呼べている）。
- `gen-lock-colors.sh` が新配置で完走し、生成される `lock-colors.conf` が現行と一致（冪等）。
- `nix run .#build` と `nix run .#fmt -- --fail-on-change` が緑。
