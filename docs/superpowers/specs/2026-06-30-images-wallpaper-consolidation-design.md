# 壁紙の `images/` 集約 設計

- 日付: 2026-06-30
- ステータス: 承認済み（実装計画へ）

## 背景・目的

現状、壁紙系の画像がリポジトリ内外に散在している。

- デスクトップ壁紙: 実行時の `~/Pictures/wallpaper`（リポジトリ外、rotate/pick スクリプトの読み取り元）
- ロック画面壁紙: `home-manager/desktop/hyprland/lock.jpg`（コミット済み、`~/.config/hypr/lock.jpg` にデプロイ）
- ログイン画面(greet)壁紙: `nixos/desktop/greetd/assets/2025068-final.png`（コミット済み、nix store 経由で参照）

「散らばるのが嫌」「将来は壁紙プールから lock/login 用を選びたい」「壁紙プール自体は R2 にバックアップしたい」という要望に基づき、トップレベル `images/` に集約する。

## 方針決定

- **集約**: トップレベル `images/` に統一（既存リポジトリは co-located 方式だが、画像は例外的に集約）。
- **git 扱い**: lock/login の選定済み画像はコミット。壁紙プールは `.gitignore` で除外し R2 をバックアップの正とする（git 肥大化を回避）。
- **canonical 1箇所**: 壁紙プールは `images/wallpaper/` のみを正とし、`~/Pictures/wallpaper` は廃止。
- **R2 同期はスコープ外**: 今回はディレクトリ構成確定・移設・参照パス修正まで。

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

## 参照パス修正

- `home-manager/desktop/hyprland/default.nix`: `lnk ./lock.jpg` → `lnk ../../../images/lock/lock.jpg`
- `nixos/desktop/greetd/default.nix`: `${./assets/2025068-final.png}` → `${../../../images/login/login.png}`
- 壁紙スクリプト `init.sh` / `pick.sh` / `thumb.sh` の `WALLPAPER_DIR`: `~/Pictures/wallpaper` → 絶対パス `/home/mkiin/ghq/github.com/mkiin/dotfiles/images/wallpaper`（個人 dotfiles として ghq パス前提を許容）
- `hyprlock.conf` の `path = ~/.config/hypr/lock.jpg`: 変更なし（デプロイ先不変）

## .gitignore

```
/images/wallpaper/*
!/images/wallpaper/.gitkeep
```

## スコープ外（別タスク）

- R2 同期の仕組み（rclone 等）
- `init.sh` の `FALLBACK="${WALLPAPER_DIR}/1297749.jpg"` は実在しないファイル参照のまま（既存課題。今回は変更しない）

## 確認事項（承認済み）

- `WALLPAPER_DIR` の絶対パス直書き: 承認
- greet 画像の `login.png` へのリネーム: 承認
