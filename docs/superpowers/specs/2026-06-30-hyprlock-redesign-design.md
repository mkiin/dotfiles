# hyprlock 画面リファクタ 設計

- 日付: 2026-06-30
- 対象: `home-manager/desktop/hyprland/hyprlock.conf` および関連する matugen テンプレート / 壁紙パイプライン
- hyprlock バージョン: v0.9.5

## 目的

ロック画面のレイアウト・デザインを **Ambient（写真主役）** 方向にリファクタする。具体的には:

1. 日付フォーマットを英語表記にする
2. カラートーン・トークンを役割ベースに見直す
3. 背景をぼかし付きスクリーンショットから「専用固定画像（ぼかし無し）」へ変更する
4. ロック画面切り替え時のアニメーション（フェードイン＋入力欄）を追加する
5. レイアウトを Ambient 方向（写真を主役にした極小 UI・非対称構成）へ再設計する

### デザイン方向: Ambient（写真主役）

固定背景画像を主役に据え、画面上の UI を極限まで削ぎ落とす。時刻・日付は左上に小さく寄せ、入力欄はタイプ時に浮かび上がる（`fade_on_empty`）。可読性は全体を暗く沈めるのではなく、ラベルの text shadow で局所的に担保し、写真の明るさ・雰囲気を保つ。挨拶メッセージは削除し、アバターとヒント文（Type to unlock）のみ残す。

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

| 項目           | 決定                                                                |
| -------------- | ------------------------------------------------------------------- |
| デザイン方向   | Ambient（写真主役・極小 UI・非対称）                                |
| 背景ソース     | 専用固定画像（壁紙と独立）                                          |
| 画像管理       | リポジトリ同梱 + `lnk`                                              |
| 可読性担保     | `brightness` 控えめ（~0.8）+ 左上ラベルの text shadow（ぼかし無し） |
| 日付形式       | `June 30, 2026`（`%B %-d, %Y`）を `LC_ALL=C` で英語強制             |
| 色の基準       | 固定画像から matugen 生成（live colors.conf と切り離し）            |
| 生成方式       | 生成→コミット（静的ファイル方式）                                   |
| 生成トリガー   | 生成スクリプト同梱・手動実行                                        |
| レイアウト     | 時刻・日付を左上、アバター/入力欄/ヒントを中央〜やや下              |
| 残す要素       | アバター・ヒント文（挨拶メッセージは削除）                          |
| 入力欄         | `fade_on_empty = true`（タイプ時に浮かび上がる）                    |
| アニメーション | 全体フェードイン/アウト + 入力欄アニメ                              |

## 詳細設計

### 1. 背景画像（ぼかし廃止）

```ini
background {
    monitor =
    path = ~/.config/hypr/lock.png   # リポジトリ同梱画像を lnk
    blur_passes = 0
    brightness = 0.8                 # 控えめに（写真主役を保つ・実装時に調整）
    contrast = 1.0
}
```

- 実画像 `home-manager/desktop/hyprland/lock.png` をコミットし、`lnk` で `~/.config/hypr/lock.png` へ配置。
- 実画像ファイルは実装時にユーザーが配置する。
- Ambient 方向のため全体を暗く沈めず、可読性は左上ラベルの text shadow（後述）で局所的に担保する。

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

### 3. レイアウト（Ambient・非対称構成）

- **左上クラスタ**（`valign=top, halign=left`、左マージン ~60px）: 時刻（中サイズ ~64px）→ 日付。各ラベルに text shadow を付与し写真の上でも可読。
- **中央〜やや下クラスタ**: アバター（小 ~80px、`~/.face.icon`）→ 入力欄 → ヒント（Type to unlock）を縦に。
- **挨拶メッセージ（Good morning 等）は削除**。
- 入力欄は `fade_on_empty = true` とし、空欄時はフェードアウト → タイプ時に浮かび上がる。
- ピクセル値（`position` のオフセット）・フォントサイズ・shadow パラメータは実装時に実機で微調整。
- 写真を主役にした極小 UI を維持し、要素を増やさない。

### 4. カラートークン見直し（役割ベース命名）

hyprlock 専用に「色名そのまま」をやめ、役割ベースのトークンへ再設計する。

| トークン              | 役割           | matugen ソース（目安）   |
| --------------------- | -------------- | ------------------------ |
| `$lock_clock`         | 時刻           | primary 高アルファ       |
| `$lock_date`          | 日付           | primary_fixed 中アルファ |
| `$lock_shadow`        | 左上ラベル影色 | 固定 暗色 半透明         |
| `$lock_input_outline` | 入力枠         | primary_container        |
| `$lock_input_bg`      | 入力内側       | surface 半透明           |
| `$lock_input_text`    | 入力文字       | on_surface               |
| `$lock_hint`          | ヒント         | on_surface 低アルファ    |
| `$lock_success`       | 認証成功       | 固定 success             |
| `$lock_fail`          | 認証失敗       | 固定 critical            |

- `$lock_greeting` は挨拶メッセージ削除に伴い廃止。`$lock_shadow` を新設し時刻・日付の text shadow に使う。

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
    animation = inputFieldFade,   1, 4, default   # fade_on_empty と連動して滑らかに出現
}
```

- hyprlock v0.9.5 の制約: 要素ごとの translate/スライド登場は非対応。登場演出は **全体フェード** + **入力欄系アニメ** に限られる。速度・bezier は実装時に調整。
- Ambient 方向では `inputFieldFade` を `fade_on_empty = true` と組み合わせ、タイプ開始時に入力欄がふわりと浮かび上がる演出にする。

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

- ロック画面背景が専用固定画像で表示され、ぼかしが無く、写真が主役に見える明るさになっている。
- 日付が英語表記（例: `June 30, 2026`）で表示される。
- 文字・入力欄の色が固定画像由来のパレットで調和し、左上ラベルは text shadow で写真上でも十分なコントラストがある。
- 時刻・日付が左上、アバター/入力欄/ヒントが中央〜やや下の Ambient レイアウトになっている。
- 挨拶メッセージが表示されない（削除済み）。
- 入力欄は空欄時に控えめで、タイプ時にフェードで浮かび上がる。
- ロック画面出現時にフェードイン、解除時にフェードアウトが動作する。
- `gen-lock-colors.sh` を実行すると `lock-colors.conf` が固定画像から再生成される。
- 壁紙を変更しても hyprlock の色・背景が変わらない（壁紙から独立している）。
