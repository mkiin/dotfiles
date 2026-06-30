# 壁紙の images/ 集約 + WALLPAPER_DIR env 注入 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 壁紙系画像をトップレベル `images/{lock,login,wallpaper}` に集約し、壁紙ディレクトリのパスを nix の `dotfilesDir` 由来で `WALLPAPER_DIR` env としてスクリプトへ渡す。

**Architecture:** lock/login の固定画像は git 追跡で `images/lock`・`images/login` に移設し、参照する nix（home-manager の `lnk`、greetd の path 補間）を相対パスへ修正する。壁紙プールは `images/wallpaper`（`.gitignore` 除外・`.gitkeep` のみ追跡）を canonical とし、`~/Pictures/wallpaper` を廃止。パスは `lib/default.nix` で算出済みの `dotfilesDir` を `extraSpecialArgs` でモジュールへ渡し、hyprland モジュールの局所 `home.sessionVariables.WALLPAPER_DIR` から壁紙スクリプトへ供給する。

**Tech Stack:** Nix (flake / home-manager / NixOS module)、Bash スクリプト、git。

## Global Constraints

- コミットメッセージは Conventional Commits 形式（例: `refactor(wallpaper): ...`、`fix(greetd): ...`）。スコープは変更対象に合わせる。
- コミット時に treefmt が staged ファイルへ自動実行される（`git commit` 実行時に走る。手動 fmt 不要）。
- nix の相対パス（`../../../images/...`）は必ず flake ソース（リポジトリ）内を指すこと。`lib/default.nix` の `mkLnk` は `lib.removePrefix (toString inputs.self)` でリポジトリ相対に変換するため、リポジトリ外パスは壊れる。
- 評価（eval）の検証コマンドは下記を使う（ビルドはせず eval のみで nix モジュール体系を強制評価し、greetd の画像 path 補間＝store コピーも含めて検証する）:
  `nix eval --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath`
- `images/wallpaper/` 配下の壁紙画像は `.gitignore` で除外する（`.gitkeep` のみ追跡）。R2 同期は本計画のスコープ外。
- `init.sh` の `FALLBACK="${WALLPAPER_DIR}/1297749.jpg"`（実在しないファイル参照）は既存課題のため本計画では変更しない。

---

### Task 1: images/ ディレクトリ構成と .gitignore

**Files:**

- Create: `images/lock/.gitkeep`（一時。Task 3 で lock.jpg を入れたら削除）
- Create: `images/login/.gitkeep`（一時。Task 4 で login.png を入れたら削除）
- Create: `images/wallpaper/.gitkeep`
- Modify: `.gitignore`

**Interfaces:**

- Consumes: なし
- Produces: `images/lock/`・`images/login/`・`images/wallpaper/` の各ディレクトリ。`images/wallpaper/*` は gitignore・`.gitkeep` のみ追跡。

- [ ] **Step 1: 現状の確認（まだ images/ が無いこと）**

Run: `test ! -d images && echo "absent OK"`
Expected: `absent OK`

- [ ] **Step 2: ディレクトリと .gitkeep を作成**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
mkdir -p images/lock images/login images/wallpaper
touch images/lock/.gitkeep images/login/.gitkeep images/wallpaper/.gitkeep
```

- [ ] **Step 3: .gitignore に壁紙プール除外を追記**

`.gitignore` の末尾に以下を追加する（既存の最終行 `.superpowers/` の後）:

```gitignore

# 壁紙プールは R2 バックアップ管理。ディレクトリだけ .gitkeep で残す。
/images/wallpaper/*
!/images/wallpaper/.gitkeep
```

- [ ] **Step 4: gitignore の効きを検証**

Run: `touch images/wallpaper/dummy.png && git status --porcelain images/wallpaper/`
Expected: 出力に `images/wallpaper/.gitkeep` は現れるが `dummy.png` は現れない（ignore されている）。

- [ ] **Step 5: ダミーを削除**

Run: `rm images/wallpaper/dummy.png`
Expected: 出力なし。

- [ ] **Step 6: コミット**

```bash
git add .gitignore images/lock/.gitkeep images/login/.gitkeep images/wallpaper/.gitkeep
git commit -m "feat(images): scaffold images/{lock,login,wallpaper} with wallpaper pool gitignored"
```

---

### Task 2: dotfilesDir を extraSpecialArgs でモジュールへ渡す

**Files:**

- Modify: `lib/default.nix`（home-manager 用 `extraSpecialArgs` と nixos 用 `home-manager.extraSpecialArgs` の2箇所）

**Interfaces:**

- Consumes: `lib/default.nix` の `let` で算出済みの `dotfilesDir`（`makeHomeManagerConfig` 内・`makeNixosConfig` 内それぞれにある）。
- Produces: home-manager モジュールの引数として `dotfilesDir`（文字列、例 `/home/mkiin/ghq/github.com/mkiin/dotfiles`）を利用可能にする。Task 3 が消費する。

- [ ] **Step 1: 現状確認（dotfilesDir がまだ渡っていない）**

Run: `grep -n "dotfilesDir" lib/default.nix`
Expected: 出力は `dotfilesDirOf` 定義（L9-10）、`dotfilesDir = dotfilesDirOf ...`（L72, L99）、`mkLnk pkgs dotfilesDir`（L84, L131）のみ。`extraSpecialArgs` の `inherit` 内には現れない。

- [ ] **Step 2: home-manager 用 extraSpecialArgs に dotfilesDir を追加**

`lib/default.nix` の `makeHomeManagerConfig` 内、`extraSpecialArgs` の `inherit` ブロックを次のように変更する:

```nix
      extraSpecialArgs = {
        inherit
          inputs
          system
          username
          pkgs-stable
          dotfilesDir
          ;
        homeDirectory = homeDirOf system username;
        lnk = mkLnk pkgs dotfilesDir;
      };
```

- [ ] **Step 3: nixos 用 home-manager.extraSpecialArgs に dotfilesDir を追加**

`lib/default.nix` の `makeNixosConfig` 内、`home-manager.extraSpecialArgs` の `inherit` ブロックを次のように変更する:

```nix
          home-manager.extraSpecialArgs = {
            inherit
              inputs
              system
              username
              pkgs-stable
              dotfilesDir
              ;
            homeDirectory = homeDirOf system username;
            lnk = mkLnk pkgs dotfilesDir;
          };
```

- [ ] **Step 4: 両 config が eval できることを検証**

Run: `nix eval --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath >/dev/null && echo "nixos eval OK"`
Expected: `nixos eval OK`（未使用の specialArg 追加なのでエラーにならない）。

Run: `nix eval --raw .#homeConfigurations."mkiin@wsl".activationPackage.drvPath >/dev/null && echo "wsl eval OK"`
Expected: `wsl eval OK`

- [ ] **Step 5: コミット**

```bash
git add lib/default.nix
git commit -m "refactor(lib): pass dotfilesDir to home-manager/nixos modules via extraSpecialArgs"
```

---

### Task 3: lock 画像移設・hyprland 参照修正・WALLPAPER_DIR 注入

**Files:**

- Move: `home-manager/desktop/hyprland/lock.jpg` → `images/lock/lock.jpg`
- Delete: `images/lock/.gitkeep`
- Modify: `home-manager/desktop/hyprland/default.nix`

**Interfaces:**

- Consumes: Task 2 が渡す `dotfilesDir`。
- Produces: `~/.config/hypr/lock.jpg`（デプロイ先は不変）。`home.sessionVariables.WALLPAPER_DIR = "<dotfilesDir>/images/wallpaper"` を Hyprland セッション配下のプロセスへ供給。Task 5 のスクリプトが消費。

- [ ] **Step 1: 現状確認（旧参照が存在する）**

Run: `grep -n "lock.jpg" home-manager/desktop/hyprland/default.nix`
Expected: `"hypr/lock.jpg".source = lnk ./lock.jpg;` の行が出る。

- [ ] **Step 2: lock.jpg を images/lock/ へ移動**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
git mv home-manager/desktop/hyprland/lock.jpg images/lock/lock.jpg
git rm images/lock/.gitkeep
```

- [ ] **Step 3: hyprland モジュールの引数に dotfilesDir を追加**

`home-manager/desktop/hyprland/default.nix` の先頭の関数引数を次のように変更する:

```nix
{
  inputs,
  pkgs,
  lnk,
  dotfilesDir,
  ...
}:
```

- [ ] **Step 4: WALLPAPER_DIR の sessionVariable を追加**

`home-manager/desktop/hyprland/default.nix` の本体（`{` 直後、`imports = [ ./monitor.nix ];` の前）に次を追加する:

```nix
  # 壁紙プールの canonical パス。壁紙スクリプト(init/pick/thumb)が WALLPAPER_DIR として参照する。
  # コンポジタ/GPU 系の env は ./lua/env.lua にある（レイヤーが異なるため分離）。
  home.sessionVariables.WALLPAPER_DIR = "${dotfilesDir}/images/wallpaper";
```

- [ ] **Step 5: lock.jpg の参照パスを修正**

`home-manager/desktop/hyprland/default.nix` の `xdg.configFile` 内、lock.jpg の行を次のように変更する:

```nix
    "hypr/lock.jpg".source = lnk ../../../images/lock/lock.jpg;
```

- [ ] **Step 6: eval 検証（参照解決と sessionVariable）**

Run: `nix eval --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath >/dev/null && echo "eval OK"`
Expected: `eval OK`

Run: `nix eval --raw '.#nixosConfigurations.nixos.config.home-manager.users.mkiin.home.sessionVariables.WALLPAPER_DIR'`
Expected: `/home/mkiin/ghq/github.com/mkiin/dotfiles/images/wallpaper`

- [ ] **Step 7: コミット**

```bash
git add home-manager/desktop/hyprland/default.nix images/lock/lock.jpg
git commit -m "refactor(hyprland): move lock.jpg to images/lock and inject WALLPAPER_DIR"
```

---

### Task 4: greet 画像移設・greetd 参照修正

**Files:**

- Move: `nixos/desktop/greetd/assets/2025068-final.png` → `images/login/login.png`
- Delete: `images/login/.gitkeep`
- Modify: `nixos/desktop/greetd/default.nix:35`

**Interfaces:**

- Consumes: なし（nix の path 補間で store にコピーされる）。
- Produces: greetd の背景画像参照を `images/login/login.png` に切り替え。

- [ ] **Step 1: 現状確認（旧参照が存在する）**

Run: `grep -n "2025068-final.png" nixos/desktop/greetd/default.nix`
Expected: `path = "${./assets/2025068-final.png}";` の行が出る。

- [ ] **Step 2: 画像を images/login/login.png へ移動（安定名へリネーム）**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
git mv nixos/desktop/greetd/assets/2025068-final.png images/login/login.png
git rm images/login/.gitkeep
```

- [ ] **Step 3: greetd の background path を修正**

`nixos/desktop/greetd/default.nix` の background ブロックを次のように変更する:

```nix
      background = {
        path = "${../../../images/login/login.png}";
        fit = "Cover";
      };
```

- [ ] **Step 4: eval 検証（画像 path 補間が解決する）**

Run: `nix eval --raw .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath >/dev/null && echo "eval OK"`
Expected: `eval OK`（移動先 `images/login/login.png` が存在し store へコピーできる）。

- [ ] **Step 5: 旧 assets ディレクトリが消えたことを確認**

Run: `test ! -e nixos/desktop/greetd/assets && echo "assets dir gone OK"`
Expected: `assets dir gone OK`（唯一のファイルを移動したため git 上は消える。空ディレクトリが残っていれば `rmdir nixos/desktop/greetd/assets` で削除）。

- [ ] **Step 6: コミット**

```bash
git add nixos/desktop/greetd/default.nix images/login/login.png
git commit -m "refactor(greetd): move greeter background to images/login/login.png"
```

---

### Task 5: 壁紙スクリプトを WALLPAPER_DIR env 参照へ

**Files:**

- Modify: `home-manager/desktop/hyprland/scripts/wallpaper/init.sh:17`
- Modify: `home-manager/desktop/hyprland/scripts/wallpaper/thumb.sh:4`
- Modify: `home-manager/desktop/hyprland/scripts/wallpaper/pick.sh:7`

**Interfaces:**

- Consumes: Task 3 が供給する `WALLPAPER_DIR` env。
- Produces: 3スクリプトとも `~/Pictures/wallpaper` 直書き・フォールバックを排除し、env 必須化。

- [ ] **Step 1: 現状確認（旧パスが残っている）**

Run: `grep -rn "Pictures/wallpaper" home-manager/desktop/hyprland/scripts/wallpaper/`
Expected: `init.sh`・`thumb.sh`・`pick.sh` の3箇所で `~/Pictures/wallpaper` または `${HOME}/Pictures/wallpaper` が出る。

- [ ] **Step 2: init.sh を env 参照へ変更**

`home-manager/desktop/hyprland/scripts/wallpaper/init.sh` の該当行を変更する:

```bash
WALLPAPER_DIR="${WALLPAPER_DIR:?WALLPAPER_DIR must be set}"
```

（直前の行の `WALLPAPER_RANDOM_ON_STARTUP=...` と直後の `FALLBACK="${WALLPAPER_DIR}/1297749.jpg"` はそのまま。）

- [ ] **Step 3: thumb.sh を env 参照へ変更**

`home-manager/desktop/hyprland/scripts/wallpaper/thumb.sh` の該当行を変更する:

```bash
SRC="${WALLPAPER_DIR:?WALLPAPER_DIR must be set}"
```

- [ ] **Step 4: pick.sh のフォールバックを env 必須化**

`home-manager/desktop/hyprland/scripts/wallpaper/pick.sh` の該当行を変更する（旧フォールバック `~/Pictures/wallpaper` を排除）:

```bash
WALLPAPER_DIR="${WALLPAPER_DIR:?WALLPAPER_DIR must be set}"
```

- [ ] **Step 5: bash 構文チェック**

Run: `for f in init pick thumb; do bash -n home-manager/desktop/hyprland/scripts/wallpaper/$f.sh && echo "$f OK"; done`
Expected: `init OK` / `pick OK` / `thumb OK`

- [ ] **Step 6: 旧パスが完全に消えたことを検証**

Run: `grep -rn "Pictures/wallpaper" home-manager/desktop/hyprland/scripts/wallpaper/ || echo "no stale path OK"`
Expected: `no stale path OK`

- [ ] **Step 7: WALLPAPER_DIR 未設定時に即時失敗することを確認**

Run: `env -u WALLPAPER_DIR bash -c 'set -euo pipefail; WALLPAPER_DIR="${WALLPAPER_DIR:?WALLPAPER_DIR must be set}"' ; echo "exit=$?"`
Expected: `WALLPAPER_DIR: WALLPAPER_DIR must be set` のエラーが出て `exit=1`（非ゼロ）。

- [ ] **Step 8: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/wallpaper/init.sh home-manager/desktop/hyprland/scripts/wallpaper/thumb.sh home-manager/desktop/hyprland/scripts/wallpaper/pick.sh
git commit -m "refactor(wallpaper): require WALLPAPER_DIR env, drop ~/Pictures/wallpaper"
```

---

### Task 6: 実行時壁紙の移行と最終適用

**Files:**

- なし（実行時ファイル移動と適用。リポジトリへのコミットは発生しない＝壁紙は gitignore 済み）

**Interfaces:**

- Consumes: Task 1〜5 の全変更。
- Produces: 実機の壁紙プールを `images/wallpaper/` に集約し、設定を適用した状態。

- [ ] **Step 1: 既存の実行時壁紙を images/wallpaper/ へ移動**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
shopt -s nullglob
for f in "$HOME"/Pictures/wallpaper/*.{jpg,jpeg,png,webp}; do
  mv -v "$f" images/wallpaper/
done
shopt -u nullglob
```

Expected: `~/Pictures/wallpaper` 内の画像（例 `1362745.png`）が `images/wallpaper/` へ移動。`placeholder.png` 等の不要ファイルは任意で削除してよい。

- [ ] **Step 2: 壁紙プールが空でないことを確認**

Run: `ls -1 images/wallpaper/ | grep -vE '^\.gitkeep$' | head; echo "count=$(ls -1 images/wallpaper/ | grep -vcE '^\.gitkeep$')"`
Expected: 1枚以上の画像が並び `count` が 1 以上。

- [ ] **Step 3: 旧ディレクトリを廃止**

Run: `rmdir "$HOME/Pictures/wallpaper" 2>/dev/null && echo "old dir removed" || echo "(残置: 不要ファイルがあれば手動で確認)"`
Expected: `old dir removed`（空なら削除）か、残ファイルの確認案内。

- [ ] **Step 4: nixos 設定を適用**

これはユーザー権限が必要。セッションのプロンプトで次を実行する（`!` プレフィックスでこのセッションから実行可）:

```
! sudo nixos-rebuild switch --flake .#nixos
```

Expected: ビルド成功・activation 完了。エラーが出た場合は該当タスクへ戻る。

- [ ] **Step 5: 適用後の動作確認（手動）**

- 新しいログインシェルで `echo $WALLPAPER_DIR` が `/home/mkiin/ghq/github.com/mkiin/dotfiles/images/wallpaper` を返す。
- 壁紙ローテーション（`~/.config/hypr/scripts/wallpaper/pick.sh`）が `images/wallpaper/` から壁紙を選べる。
- ロック（hyprlock）の背景が表示される（`~/.config/hypr/lock.jpg` 経由）。
- greet ログイン画面の背景が表示される。

---

## Self-Review

**1. Spec coverage（spec の各項目に対応タスクがあるか）:**

- ディレクトリ構成 `images/{lock,login,wallpaper}` + `.gitkeep` → Task 1 ✓
- 壁紙プール gitignore（`.gitkeep` のみ追跡） → Task 1 ✓
- lock.jpg 移設 + hyprland 参照修正 → Task 3 ✓
- greet 画像 `login.png` リネーム移設 + greetd 参照修正 → Task 4 ✓
- `dotfilesDir` を `extraSpecialArgs` で渡す → Task 2 ✓
- hyprland 局所 `home.sessionVariables.WALLPAPER_DIR`（集約モジュールは作らない） → Task 3 ✓
- 壁紙スクリプトの env 化（init/thumb/pick） → Task 5 ✓
- `~/Pictures/wallpaper` 廃止・canonical 一本化 → Task 5（コード）+ Task 6（実機） ✓
- `hyprlock.conf` は変更なし → 全タスクで非対象（明示） ✓
- env.lua・fcitx5・EDITOR/VISUAL 据え置き → 全タスクで非対象（明示） ✓
- R2 同期はスコープ外 → 計画に含めず（Global Constraints に明記） ✓
- `init.sh` FALLBACK 既存課題は不変 → Task 5 Step 2 補足＋Global Constraints ✓

**2. Placeholder scan:** プレースホルダなし。各ステップに実コード・実コマンド・期待値を記載済み。

**3. Type consistency:** env 変数名は全タスクで `WALLPAPER_DIR` に統一。nix 引数名は `dotfilesDir` で Task 2（提供）と Task 3（消費）が一致。画像ファイル名は `images/lock/lock.jpg`・`images/login/login.png` で参照修正タスクと移設タスクが一致。
