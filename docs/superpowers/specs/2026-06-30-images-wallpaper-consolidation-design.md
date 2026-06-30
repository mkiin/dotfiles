# 壁紙の `images/` 集約 設計

- 日付: 2026-06-30
- ステータス: 承認済み（実装計画へ）

## 背景・目的

現状、壁紙系の画像がリポジトリ内外に散在している。

- デスクトップ壁紙: 実行時の `~/Pictures/wallpaper`（リポジトリ外、rotate/pick スクリプトの読み取り元）
- ロック画面壁紙: `home-manager/desktop/hyprland/lock.jpg`（コミット済み、`~/.config/hypr/lock.jpg` にデプロイ）
- ログイン画面(greet)壁紙: `nixos/desktop/greetd/assets/2025068-final.png`（コミット済み、nix store 経由で参照）

「散らばるのが嫌」「将来は壁紙プールから lock/login 用を選びたい」「壁紙プール自体は R2 にバックアップしたい」という要望に基づき、トップレベル `images/` に集約する。あわせて、壁紙ディレクトリのパスをスクリプトに直書きしないよう nix から env として渡す。

## 方針決定

- **集約**: トップレベル `images/` に統一（既存リポジトリは co-located 方式だが、画像は例外的に集約）。
- **git 扱い**: lock/login の選定済み画像はコミット。壁紙プールは `.gitignore` で除外し R2 をバックアップの正とする（git 肥大化を回避）。
- **canonical 1箇所**: 壁紙プールは `images/wallpaper/` のみを正とし、`~/Pictures/wallpaper` は廃止。
- **パスの直書き排除**: 壁紙ディレクトリのパスは nix の既存 `dotfilesDir`（`lib/default.nix`）から導出し、hyprland モジュール内の `home.sessionVariables.WALLPAPER_DIR` 経由でスクリプトへ渡す。
- **env 集約モジュールは作らない**: 横断的な env 集約モジュール（EDITOR/VISUAL の移動を含む）は行わない。`WALLPAPER_DIR` は hyprland モジュールに局所定義する。
- **R2 同期はスコープ外**: 今回はディレクトリ構成確定・移設・参照パス修正・env 経由のパス注入まで。

## ディレクトリ構成

```
dotfiles/
  images/
    lock/        # ロック画面用（git 追跡・コミット）
      lock.jpg
    login/       # ログイン画面(greet)用（git 追跡・コミット）
      login.png
    wallpaper/   # デスクトップ壁紙プール（gitignore・R2 バックアップ）
      .gitkeep   # 空でもディレクトリを残す
```

`lock/` `login/` は「プールから選んだ実際に使う1枚」を置く場所。将来 `wallpaper/` から選んだ画像をここへコピーしてコミットする運用を想定。

## ファイル移設

- `home-manager/desktop/hyprland/lock.jpg` → `images/lock/lock.jpg`
- `nixos/desktop/greetd/assets/2025068-final.png` → `images/login/login.png`（安定名へリネーム。差し替え時も参照パス不変）

## 壁紙パスの env 注入（nix → スクリプト）

### `dotfilesDir` の受け渡し

- `lib/default.nix`: 既に算出済みの `dotfilesDir` を両方の `extraSpecialArgs`（home-manager 用・nixos 用）に追加し、モジュールへ渡す。

### hyprland モジュールに局所定義

`home-manager/desktop/hyprland/default.nix` に、`dotfilesDir` 由来の `WALLPAPER_DIR` を `home.sessionVariables` として追加する（横断的な env 集約モジュールは作らない）。

```nix
{ inputs, pkgs, lnk, dotfilesDir, ... }:
{
  home.sessionVariables.WALLPAPER_DIR = "${dotfilesDir}/images/wallpaper";
  # ... 既存設定
}
```

Hyprland は home-manager セッション配下で起動するため、`home.sessionVariables` は壁紙スクリプトへ継承される。

### 据え置き（今回は触らない）

- `home-manager/cli/zsh/default.nix` の `EDITOR`/`VISUAL`: そのまま（移動しない）。
- `home-manager/desktop/fcitx5` の IME 変数: その場に残す。
- `home-manager/desktop/hyprland/lua/env.lua`（NVIDIA/GPU 系・Electron Wayland ヒント）: Hyprland コンポジタが `hl.env` で起動時に設定するレイヤーであり、`home.sessionVariables` とはレイヤーが異なる。起動順 risk と凝集性の観点から移動しない。

## 参照パス修正

- `home-manager/desktop/hyprland/default.nix`: `lnk ./lock.jpg` → `lnk ../../../images/lock/lock.jpg`
- `nixos/desktop/greetd/default.nix`: `${./assets/2025068-final.png}` → `${../../../images/login/login.png}`
- 壁紙スクリプト `init.sh` / `thumb.sh`: 直書きの `WALLPAPER_DIR="${HOME}/Pictures/wallpaper"` を env 参照 `WALLPAPER_DIR="${WALLPAPER_DIR:?WALLPAPER_DIR must be set}"` に変更（`pick.sh` は既に `${WALLPAPER_DIR:-...}` で env override 対応済み）。
- `hyprlock.conf` の `path = ~/.config/hypr/lock.jpg`: 変更なし（デプロイ先不変）。

## .gitignore

```
/images/wallpaper/*
!/images/wallpaper/.gitkeep
```

## スコープ外（別タスク）

- R2 同期の仕組み（rclone 等）。
- `init.sh` の `FALLBACK="${WALLPAPER_DIR}/1297749.jpg"` は実在しないファイル参照のまま（既存課題。今回は変更しない）。

## 確認事項（承認済み）

- 壁紙プールは `.gitignore` 除外・R2 バックアップ、R2 同期は別タスク: 承認
- greet 画像の `login.png` へのリネーム: 承認
- `WALLPAPER_DIR` 直書きを避け nix `dotfilesDir` から導出: 承認
- env 集約モジュールは作らず、`WALLPAPER_DIR` は hyprland モジュールに局所 `home.sessionVariables` で定義: 承認
- EDITOR/VISUAL・fcitx5 IME 変数・env.lua は据え置き: 承認
