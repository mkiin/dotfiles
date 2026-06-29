# hyprlock 画面リファクタ 設計

- 日付: 2026-06-30
- 対象: `home-manager/desktop/hyprland/hyprlock.conf` および関連する matugen テンプレート / 壁紙パイプライン
- hyprlock バージョン: v0.9.5

## 目的

ロック画面のレイアウト・デザインをリファクタする。具体的には:

1. 日付フォーマットを英語表記にする
2. カラートーン・トークンを役割ベースに見直す
3. 背景をぼかし付きスクリーンショットから「専用固定画像（ぼかし無し）」へ変更する
4. ロック画面切り替え時のアニメーション（フェードイン＋入力欄）を追加する

作業は git worktree を切って実施する。

## 現状（調査結果）

- `hyprlock.conf` は `lnk` で `~/.config/hypr/hyprlock.conf` へ配置。先頭で `~/.config/hypr/colors.conf` を `source`。
- 背景は `path = screenshot` + `blur_passes = 3` でロック時スクリーンショットをぼかして使用。
- 色は matugen テンプレート `matugen/templates/hyprlock-colors.conf` → `~/.config/hypr/colors.conf` を **現在の壁紙** から生成。トークンは `$primary_a95` のように「matugen 色名 + アルファ」命名。
- 日付ラベルは `date +"%A, %B %-d"`。ディレクティブは英語だが `LC_TIME=ja_JP.UTF-8`（`nixos/core/locale/default.nix`）のため出力が日本語化する。
- 壁紙パイプライン `home-manager/desktop/hyprland/scripts/wallpaper/apply.sh` が現在の壁紙を `~/.local/state/hypr/last_wallpaper` に保存。
- `colors.conf` を参照しているのは **hyprlock のみ**（Hyprland のボーダー等は `colors.lua` を使用）。よって hyprlock の色源を差し替えても他機能に影響しない。

## 設計判断と背景

背景を「壁紙連動」ではなく「専用固定画像」にすることで、ロック背景が壁紙変更から独立する。一方で現状の色は **現在の壁紙** 由来のため、固定背景とコントラストが合わなくなる懸念がある。これを解消するため、**ロック専用の色は固定画像から matugen で一度だけ生成し、生成物をリポジトリにコミットして静的に使う**。

| 項目           | 決定                                                     |
| -------------- | -------------------------------------------------------- |
| 背景ソース     | 専用固定画像（壁紙と独立）                               |
| 画像管理       | リポジトリ同梱 + `lnk`                                   |
| 可読性担保     | `brightness` で全体を軽く暗く（ぼかし無し）              |
| 日付形式       | `June 30, 2026`（`%B %-d, %Y`）を `LC_ALL=C` で英語強制  |
| 色の基準       | 固定画像から matugen 生成（live colors.conf と切り離し） |
| 生成方式       | 生成→コミット（静的ファイル方式）                        |
| 生成トリガー   | 生成スクリプト同梱・手動実行                             |
| レイアウト     | 時刻・日付を上部、入力欄を下部                           |
| アニメーション | 全体フェードイン/アウト + 入力欄アニメ                   |

## 詳細設計

### 1. 背景画像（ぼかし廃止）

```ini
background {
    monitor =
    path = ~/.config/hypr/lock.png   # リポジトリ同梱画像を lnk
    blur_passes = 0
    brightness = 0.6                 # 軽く暗くして可読性確保（実装時に調整）
    contrast = 1.0
}
```

- 実画像 `home-manager/desktop/hyprland/lock.png` をコミットし、`lnk` で `~/.config/hypr/lock.png` へ配置。
- 実画像ファイルは実装時にユーザーが配置する。

### 2. 日付フォーマット（英語化）

```ini
label {
    monitor =
    text = cmd[update:60000] echo "$(LC_ALL=C date +'%B %-d, %Y')"
    ...
}
```

- `LC_ALL=C` で曜日・月名を英語に強制。
- 時刻ラベルも秒非表示のため `cmd[update:1000]` → `cmd[update:60000]` に緩和。

### 3. レイアウト（時刻上・入力下）

- **上部クラスタ**（`valign=top` アンカー）: 時刻（大フォント）→ 日付。
- **下部クラスタ**（`valign=bottom` アンカー、下から積む）: アバター（`~/.face.icon`）→ 挨拶 → 入力欄 → ヒント。
- ピクセル値（`position` のオフセット）・フォントサイズは実装時に実機で微調整。
- アバターは下部クラスタに残す。不要であれば実装時に外せる。

### 4. カラートークン見直し（役割ベース命名）

hyprlock 専用に「色名そのまま」をやめ、役割ベースのトークンへ再設計する。

| トークン              | 役割     | matugen ソース（目安）   |
| --------------------- | -------- | ------------------------ |
| `$lock_clock`         | 時刻     | primary 高アルファ       |
| `$lock_date`          | 日付     | primary_fixed 中アルファ |
| `$lock_greeting`      | 挨拶     | tertiary                 |
| `$lock_input_outline` | 入力枠   | primary_container        |
| `$lock_input_bg`      | 入力内側 | surface 半透明           |
| `$lock_input_text`    | 入力文字 | on_surface               |
| `$lock_hint`          | ヒント   | on_surface 低アルファ    |
| `$lock_success`       | 認証成功 | 固定 success             |
| `$lock_fail`          | 認証失敗 | 固定 critical            |

### 5. パレット生成パイプライン

- 新テンプレート `matugen/templates/lock-colors.conf`（上記役割ベーストークンを定義、matugen のカラー変数を参照）。
- 生成スクリプト `home-manager/desktop/hyprland/scripts/gen-lock-colors.sh`:
  - リポジトリルートを解決し、固定画像 `lock.png` に matugen を適用。
  - lock 専用テンプレートのみを持つ一時 / 専用 matugen 設定を用い、出力先を **リポジトリ内 `home-manager/desktop/hyprland/lock-colors.conf`** に指定して上書き生成。
  - ユーザーが差分を確認しコミットする運用。手動実行。
- 生成物 `home-manager/desktop/hyprland/lock-colors.conf` を `lnk` で `~/.config/hypr/lock-colors.conf` へ配置。
- `hyprlock.conf` 先頭の `source` を `~/.config/hypr/lock-colors.conf` に変更。

#### クリーンアップ

- `colors.conf` は hyprlock 専用と確認済みのため:
  - `matugen/config.toml` から `[templates.hyprlock]` を削除（壁紙変更毎の無駄な再生成を撤廃）。
  - 旧テンプレート `matugen/templates/hyprlock-colors.conf` を削除（lock-colors テンプレートへ統合）。
  - `matugen/default.nix` の対応する `xdg.configFile` エントリを更新。

### 6. アニメーション（フェードイン + 入力欄）

```ini
animations {
    enabled = true
    bezier = lockEase, 0.25, 1, 0.5, 1
    animation = fadeIn,  1, 5, lockEase   # 出現フェードイン
    animation = fadeOut, 1, 4, lockEase   # 解除フェードアウト
    animation = inputFieldDots,   1, 3, default
    animation = inputFieldColors, 1, 4, default
}
```

- hyprlock v0.9.5 の制約: 要素ごとの translate/スライド登場は非対応。登場演出は **全体フェード** + **入力欄系アニメ** に限られる。速度・bezier は実装時に調整。

## 変更ファイル一覧

- 改修:
  - `home-manager/desktop/hyprland/hyprlock.conf`（レイアウト・背景・日付・source・animations）
  - `home-manager/desktop/hyprland/default.nix`（`lock.png` / `lock-colors.conf` / 生成スクリプトの `lnk` 追加）
  - `home-manager/desktop/matugen/config.toml`（`[templates.hyprlock]` 削除）
  - `home-manager/desktop/matugen/default.nix`（テンプレート差し替え）
- 新規:
  - `home-manager/desktop/hyprland/lock.png`（固定背景画像、実装時に配置）
  - `home-manager/desktop/hyprland/lock-colors.conf`（matugen 生成物、コミット）
  - `home-manager/desktop/matugen/templates/lock-colors.conf`（役割ベーストークンのテンプレート）
  - `home-manager/desktop/hyprland/scripts/gen-lock-colors.sh`（手動実行の生成スクリプト）
- 削除:
  - `home-manager/desktop/matugen/templates/hyprlock-colors.conf`（lock-colors テンプレートへ統合）

## 作業方法

- git worktree を切って作業する（例: dotfiles リポジトリから `git worktree add` で専用ブランチの作業ツリーを作成）。
- 実装フェーズで worktree を作成し、その中で変更・ビルド確認を行う。

## 受け入れ基準

- ロック画面背景が専用固定画像で表示され、ぼかしが無い。
- 日付が英語表記（例: `June 30, 2026`）で表示される。
- 文字・入力欄の色が固定画像由来のパレットで調和し、十分なコントラストがある。
- 時刻・日付が上部、入力欄が下部のレイアウトになっている。
- ロック画面出現時にフェードイン、解除時にフェードアウトが動作する。
- `gen-lock-colors.sh` を実行すると `lock-colors.conf` が固定画像から再生成される。
- 壁紙を変更しても hyprlock の色・背景が変わらない（壁紙から独立している）。
