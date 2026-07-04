# 壁紙の R2 バックアップと初回ブート成立 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 壁紙を Cloudflare R2 に自動バックアップして復元できるようにし、壁紙未取得でも waybar が起動する初回ブートを成立させる。

**Architecture:** 初回ブート用のフォールバック色を home-manager activation で copy-if-absent 配置する。R2 認証を agenix で暗号化し NixOS で復号する。壁紙は rclone copy でアーカイブ退避し、systemd path unit が追加を検知して自動バックアップ、復元は flake app で手動実行する。

**Tech Stack:** Nix / NixOS / home-manager、agenix、rclone（S3 互換で R2 接続）、systemd user units、Cloudflare R2。

## Global Constraints

- パッケージ本体は集約 `packages.nix` にのみ書く。機能ディレクトリの `default.nix` は `programs.*` / `services.*` / `xdg.configFile` / systemd unit などの設定専用とする。systemd unit 内の `${pkgs.X}/bin/...` 絶対パス参照は宣言ではないため許容。
- コメントは非自明な理由だけを 1 から 2 行で書く。設定項目を日本語で言い換えるだけのコメントは書かない。
- 各タスクの完了前に `nix run .#build` と `nix run .#fmt -- --fail-on-change` を必ず通す。deadnix が未使用 let 束縛を検出する。
- 壁紙のバイナリは git に載せない。`.gitignore` の `/images/wallpaper/*` は変更しない。
- モジュールは specialArgs から `pkgs` `lib` `config` `dotfilesDir` `inputs` を受け取れる。
- 復号鍵は個人 age 鍵をマスターとし、identityPaths は `/home/mkiin/.config/agenix/key.txt`。復号先は `/run/agenix/rclone-r2.conf`。R2 バケット名は固定定数 `dotfiles-wallpaper`、バケット内プレフィックスは `wallpaper/`。rclone remote 名は `r2`。

---

## ファイル構成

作成または変更するファイルと責務。

- `home-manager/desktop/matugen/fallback/colors.css`（作成）：waybar の matugen 色フォールバック実体。
- `home-manager/desktop/matugen/default.nix`（変更）：フォールバック配置の activation を追加。
- `home-manager/desktop/wallust/fallback/colors-waybar.css`（作成）：waybar の wallust 色フォールバック実体。
- `home-manager/desktop/wallust/default.nix`（変更）：フォールバック配置の activation を追加。
- `nixos/core/secrets/secrets.nix`（作成済み）：agenix の暗号化ルール（どの公開鍵でどのファイルを暗号化するか）。agenix 既定名なので CLI の `RULES` 指定は不要。
- `nixos/core/secrets/rclone-r2.conf.age`（作成済み）：暗号化した rclone 設定。
- `nixos/core/secrets/default.nix`（作成）：agenix NixOS モジュールの配線と `age.secrets` 定義。ストア（secrets.nix・.age）と同居。
- `nixos/core/default.nix`（変更）：`./secrets` を imports に追加。
- `home-manager/desktop/packages.nix`（変更）：`rclone` を追加。
- `home-manager/desktop/wallpaper-backup/default.nix`（作成）：on-change バックアップの systemd user path unit と service。
- `home-manager/desktop/default.nix`（変更）：`./wallpaper-backup` を imports に追加。
- `flake.nix`（変更）：`backup-wallpaper` と `restore-wallpaper` の flake app を追加。
- `todo.md`（変更）：stale な notify.sh 項目を削除し初回セットアップ節を更新。

---

## Phase 1: フォールバック色

他フェーズに依存しない。単独で switch でき、初回ブートを成立させる。

### Task 1: waybar のフォールバック色を配置する

matugen と wallust が生成する 2 つの色ファイルが初回ブート時に存在しないと waybar と wlogout が起動できない。
現行の runtime 色は seed 壁紙由来のため、それをスナップショットしてフォールバックにする。

**Files:**

- Create: `home-manager/desktop/matugen/fallback/colors.css`
- Create: `home-manager/desktop/wallust/fallback/colors-waybar.css`
- Modify: `home-manager/desktop/matugen/default.nix`
- Modify: `home-manager/desktop/wallust/default.nix`

**Interfaces:**

- Consumes: なし。
- Produces: activation `fallbackWaybarColors`（matugen）と `fallbackWaybarColorsWallust`（wallust）。後続タスクは参照しない。

- [ ] **Step 1: 現行 runtime 色をフォールバック実体としてコミット対象へコピー**

現行マシンには壁紙適用済みの色ファイルが存在する。これをそのまま実体にする。

```bash
install -Dm644 ~/.config/waybar/colors.css        home-manager/desktop/matugen/fallback/colors.css
install -Dm644 ~/.config/waybar/colors-waybar.css home-manager/desktop/wallust/fallback/colors-waybar.css
```

- [ ] **Step 2: コピーが期待どおりか確認**

Run:

```bash
grep -c '@define-color' home-manager/desktop/matugen/fallback/colors.css
grep -c '@define-color' home-manager/desktop/wallust/fallback/colors-waybar.css
```

Expected: matugen 側は 50 以上（Material Design 3 トークン群 + state\_\*）、wallust 側は 21（cursor/background/foreground/color0..15）。0 なら runtime ファイルが空なので中止し、壁紙を一度適用してから再取得する。

- [ ] **Step 3: matugen の default.nix に activation を追加**

`{ lnk, ... }:` を `{ lnk, lib, ... }:` に変え、末尾に activation を足す。

```nix
{ lnk, lib, ... }:
{
  xdg.configFile = {
    "matugen/config.toml".source = lnk ./config.toml;
    "matugen/templates/hyprland-colors.lua".source = lnk ./templates/hyprland-colors.lua;
    "matugen/templates/waybar-colors.css".source = lnk ./templates/waybar-colors.css;
    "matugen/templates/wlogout-colors.css".source = lnk ./templates/wlogout-colors.css;
    "matugen/templates/quickshell-colors.json".source = lnk ./templates/quickshell-colors.json;
  };

  # 初回ブートでは matugen 未実行で colors.css が無く waybar が @import に失敗する。
  # 壁紙適用で本物が生成されるまでの間だけ seed 由来のフォールバックを置く（存在時は触らない）。
  home.activation.fallbackWaybarColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/waybar/colors.css"
    [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback/colors.css} "$t"
  '';
}
```

- [ ] **Step 4: wallust の default.nix に activation を追加**

`{ lnk, ... }:` を `{ lnk, lib, ... }:` に変え、末尾に activation を足す。

```nix
{ lnk, lib, ... }:
{
  xdg.configFile = {
    "wallust/wallust.toml".source = lnk ./wallust.toml;
    "wallust/templates/waybar.css".source = lnk ./templates/waybar.css;
    "wallust/templates/ghostty.conf".source = lnk ./templates/ghostty.conf;
    "wallust/templates/wezterm.toml".source = lnk ./templates/wezterm.toml;
    "wallust/templates/pywal-colors.json".source = lnk ./templates/pywal-colors.json;
  };

  # colors-waybar.css も同様に初回未生成。waybar と wlogout が共有するため置いておく。
  home.activation.fallbackWaybarColorsWallust = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/waybar/colors-waybar.css"
    [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback/colors-waybar.css} "$t"
  '';
}
```

- [ ] **Step 5: ビルドと整形を確認**

Run:

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

Expected: 両方成功。deadnix エラーなし。

- [ ] **Step 6: 冪等性を確認（本物を上書きしないこと）**

現行の colors.css は既に存在する。switch してもフォールバックで上書きされないことを確かめる。

Run:

```bash
sha256sum ~/.config/waybar/colors.css
nix run .#switch
sha256sum ~/.config/waybar/colors.css
```

Expected: 前後で sha256 が一致（既存ファイルは変更されない）。

- [ ] **Step 7: 欠損時に配置されることを確認**

Run:

```bash
mv ~/.config/waybar/colors.css /tmp/colors.css.bak
nix run .#switch
test -e ~/.config/waybar/colors.css && echo "PLACED"
```

Expected: `PLACED`。確認後に元へ戻す `mv /tmp/colors.css.bak ~/.config/waybar/colors.css`。

- [ ] **Step 8: コミット**

```bash
git add home-manager/desktop/matugen/fallback/colors.css \
        home-manager/desktop/matugen/default.nix \
        home-manager/desktop/wallust/fallback/colors-waybar.css \
        home-manager/desktop/wallust/default.nix
git commit -m "feat(desktop): 初回ブート用フォールバック色を配置(waybar/wlogout)"
```

---

## Phase 2: 手動前提の準備

コード変更を伴わない人手の手順。Cloudflare とローカルで実施する。後続の暗号化とモジュール配線の入力になる。

### Task 2: age 鍵の生成と R2 資格情報の発行

**Files:** なし（マシン上の鍵と Cloudflare 側の設定）。

**Interfaces:**

- Produces: `/home/mkiin/.config/agenix/key.txt`（age 秘密鍵）、その公開鍵文字列 `age1...`、R2 の access key と secret、R2 アカウント ID。

- [ ] **Step 1: 個人 age 鍵を生成**

```bash
mkdir -p ~/.config/agenix
nix shell nixpkgs#age -c age-keygen -o ~/.config/agenix/key.txt
chmod 600 ~/.config/agenix/key.txt
```

Expected: `Public key: age1...` が表示される。この公開鍵文字列を控える。

- [ ] **Step 2: 秘密鍵をオフライン退避**

`~/.config/agenix/key.txt` の内容（`AGE-SECRET-KEY-...`）をパスワードマネージャ等へ保存する。
これがフレッシュインストール時に手で運ぶ唯一の起点になる。

- [ ] **Step 3: R2 バケットと API トークンを用意**

Cloudflare ダッシュボードまたは wrangler で次を用意する。

- バケット `dotfiles-wallpaper` を作成する。
- R2 の S3 API トークン（Object Read & Write）を発行し、access key と secret を控える。
- R2 アカウント ID を控える（エンドポイント `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` に使う）。

Expected: access key、secret、account ID の 3 値が手元にある。

---

## Phase 3: agenix による認証情報の暗号化と配線

Task 2 の成果物に依存する。`.age` を作ってから NixOS モジュールを配線する。順序を守る（モジュールは `.age` が無いと `nix build` が失敗する）。

### Task 3: rclone 設定を agenix で暗号化する

ストアは `nixos/core/secrets/` に集約する（配線モジュールとコロケーション）。ルールは agenix 既定名 `secrets.nix`（配線用に `default.nix` を空けるため）。

**Files:**

- Create: `nixos/core/secrets/secrets.nix`（作成済み・移動済み）
- Create: `nixos/core/secrets/rclone-r2.conf.age`（作成済み・移動済み）

**Interfaces:**

- Consumes: age 公開鍵、R2 の 3 値。
- Produces: `nixos/core/secrets/rclone-r2.conf.age`。後続タスクの `age.secrets."rclone-r2.conf".file = ./rclone-r2.conf.age` が参照する。

このタスクは実施済み。`secrets.nix`（公開鍵ルール）と暗号化済み `.age` は既に存在する。以下は再作成や検証時の参照手順。

- [x] **Step 1: secrets.nix（ルール）**

```nix
let
  mkiin = "age1jsh6xwxl7gckzcc002feuzy2j4rtt635257gwkqd3c5pcv0yksxq7stjy8";
in
{
  "rclone-r2.conf.age".publicKeys = [ mkiin ];
}
```

- [x] **Step 2: 暗号化ファイルを作成（再暗号化する場合）**

`nixos/core/secrets/` 内で実行するとエディタが開く。既定名 `secrets.nix` があるため `RULES` 指定は不要。

```bash
cd nixos/core/secrets
EDITOR=nvim nix run github:ryantm/agenix -- -e rclone-r2.conf.age -i ~/.config/agenix/key.txt
```

入力する内容（`<...>` を実値に置換）:

```ini
[r2]
type = s3
provider = Cloudflare
access_key_id = <ACCESS_KEY>
secret_access_key = <SECRET_KEY>
endpoint = https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

- [x] **Step 3: 暗号化されたことを確認**

```bash
head -c 21 nixos/core/secrets/rclone-r2.conf.age; echo
```

Expected: `age-encryption.org/v1` で始まる（平文の `access_key_id` が見えてはならない）。

- [ ] **Step 4: コミット（配線 Task 4 とまとめてでよい）**

```bash
git add nixos/core/secrets/secrets.nix nixos/core/secrets/rclone-r2.conf.age
git commit -m "feat(secrets): R2 の rclone 設定を agenix で暗号化"
```

### Task 4: agenix を NixOS に配線する

**Files:**

- Create: `nixos/core/secrets/default.nix`
- Modify: `nixos/core/default.nix`

**Interfaces:**

- Consumes: `nixos/core/secrets/rclone-r2.conf.age`（同一ディレクトリ）、`inputs.agenix.nixosModules.default`。
- Produces: 復号済み `/run/agenix/rclone-r2.conf`（owner mkiin, mode 0400）。後続タスクの rclone がこれを `--config` で読む。

- [ ] **Step 1: secrets モジュールを作成**

`.age` と同居するため `file` は同一ディレクトリの相対パスでよい。

```nix
{ inputs, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  # SSH host key を持たないため個人 age 鍵を復号鍵にする。activation(root) から読める。
  age.identityPaths = [ "/home/mkiin/.config/agenix/key.txt" ];

  # ユーザーの rclone user service と flake app から読めるよう owner を mkiin にする。
  age.secrets."rclone-r2.conf" = {
    file = ./rclone-r2.conf.age;
    path = "/run/agenix/rclone-r2.conf";
    owner = "mkiin";
    mode = "0400";
  };
}
```

- [ ] **Step 2: core の imports に追加**

`nixos/core/default.nix` の imports リストへ `./secrets` を足す。

```nix
{ ... }:
{
  imports = [
    ./boot
    ./nix
    ./packages
    ./users
    ./locale
    ./time
    ./network
    ./nix-ld
    ./fonts
    ./secrets
  ];
}
```

- [ ] **Step 3: ビルドと整形を確認**

Run:

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

Expected: 成功。失敗する場合 `.age` の相対パス（`./rclone-r2.conf.age`）か公開鍵の不一致を疑う。

- [ ] **Step 4: switch して復号先を確認**

Run:

```bash
nix run .#switch
sudo test -e /run/agenix/rclone-r2.conf && echo "DECRYPTED"
stat -c '%U %a' /run/agenix/rclone-r2.conf
```

Expected: `DECRYPTED`、所有者 `mkiin`、mode `400`。

- [ ] **Step 5: コミット**

```bash
git add nixos/core/secrets/default.nix nixos/core/default.nix
git commit -m "feat(nixos): agenix を配線し R2 認証を復号"
```

---

## Phase 4: rclone によるバックアップと復元

Task 4 の復号先に依存する。

### Task 5: rclone パッケージと on-change バックアップ

**Files:**

- Modify: `home-manager/desktop/packages.nix`
- Create: `home-manager/desktop/wallpaper-backup/default.nix`
- Modify: `home-manager/desktop/default.nix`

**Interfaces:**

- Consumes: `/run/agenix/rclone-r2.conf`、`dotfilesDir`、`pkgs.rclone`。
- Produces: systemd user path unit `wallpaper-backup` と同名 oneshot service。

- [ ] **Step 1: packages.nix に rclone を追加**

`# color / wallpaper pipeline` ブロックへ `rclone` を足す。

```nix
    # color / wallpaper pipeline
    matugen
    wallust
    awww
    rclone
```

- [ ] **Step 2: wallpaper-backup モジュールを作成**

```nix
{ pkgs, dotfilesDir, ... }:
let
  dir = "${dotfilesDir}/images/wallpaper";
  # copy は追加のみ。ローカル削除を R2 へ伝播させず、一度上げた壁紙を失わない。
  backup = "${pkgs.rclone}/bin/rclone copy ${dir} r2:dotfiles-wallpaper/wallpaper --config /run/agenix/rclone-r2.conf";
in
{
  systemd.user.paths.wallpaper-backup = {
    Unit.Description = "Watch wallpaper dir and trigger R2 backup";
    Path.PathModified = dir;
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.wallpaper-backup = {
    Unit.Description = "Back up wallpapers to R2 (rclone copy, additive)";
    Service = {
      Type = "oneshot";
      ExecStart = backup;
    };
  };
}
```

- [ ] **Step 3: desktop の imports に追加**

`home-manager/desktop/default.nix` の imports へ `./wallpaper-backup` を足す（`./wallust` の隣が自然）。

```nix
    ./matugen
    ./wallust
    ./wallpaper-backup
```

- [ ] **Step 4: ビルドと整形を確認**

Run:

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

Expected: 成功。

- [ ] **Step 5: switch して path unit の稼働を確認**

Run:

```bash
nix run .#switch
systemctl --user status wallpaper-backup.path --no-pager
```

Expected: `Active: active (waiting)`。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/packages.nix \
        home-manager/desktop/wallpaper-backup/default.nix \
        home-manager/desktop/default.nix
git commit -m "feat(desktop): 壁紙の on-change R2 バックアップ(rclone copy)"
```

### Task 6: 復元と初回アップロードの flake app

**Files:**

- Modify: `flake.nix`

**Interfaces:**

- Consumes: `pkgs.rclone`、`/run/agenix/rclone-r2.conf`。
- Produces: flake app `backup-wallpaper` と `restore-wallpaper`。

- [ ] **Step 1: apps に 2 つの app を追加**

`flake.nix` の `apps.${system}` 内、`switch` の後へ足す。

```nix
        backup-wallpaper = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "backup-wallpaper" ''
              set -eo pipefail
              ${pkgs.rclone}/bin/rclone copy images/wallpaper \
                r2:dotfiles-wallpaper/wallpaper --config /run/agenix/rclone-r2.conf --progress
              echo "Backed up wallpapers to R2."
            ''
          );
        };

        restore-wallpaper = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "restore-wallpaper" ''
              set -eo pipefail
              ${pkgs.rclone}/bin/rclone copy \
                r2:dotfiles-wallpaper/wallpaper images/wallpaper --config /run/agenix/rclone-r2.conf --progress
              echo "Restored wallpapers from R2."
            ''
          );
        };
```

- [ ] **Step 2: 整形を確認**

Run:

```bash
nix run .#fmt -- --fail-on-change
```

Expected: 成功。

- [ ] **Step 3: 初回アップロードを実行（R2 を seed）**

リポジトリ直下で実行する。既存の `2026799-final.png` を R2 へ上げる。

```bash
nix run .#backup-wallpaper
```

Expected: 転送ログの後 `Backed up wallpapers to R2.`。

- [ ] **Step 4: 復元を検証**

一時ディレクトリへ復元して往復を確かめる（本物の壁紙ディレクトリは触らない）。
Task 5 の switch で `rclone` は PATH にある。

```bash
tmp=$(mktemp -d)
rclone copy r2:dotfiles-wallpaper/wallpaper "$tmp" --config /run/agenix/rclone-r2.conf
ls "$tmp"
```

Expected: `2026799-final.png` が `$tmp` に現れる。確認後 `rm -rf "$tmp"`。

- [ ] **Step 5: コミット**

```bash
git add flake.nix
git commit -m "feat(flake): 壁紙の R2 backup/restore app を追加"
```

---

## Phase 5: stale 整理

### Task 7: todo.md を更新する

**Files:**

- Modify: `todo.md`

**Interfaces:**

- Consumes: なし。
- Produces: なし。

- [ ] **Step 1: notify.sh 項目を削除**

`todo.md` の「初回セットアップの自動化」節から次の行を削除する。post.sh は `notify_downstream()` にリファクタ済みで外部 notify.sh を呼ばないため陳腐化している。

```
- `~/.config/scripts/notify.sh` が存在せず壁紙適用の最後でエラーになる問題の調査・修正
```

- [ ] **Step 2: 初回セットアップ節を実装済み前提へ更新**

「初回セットアップの自動化」節の残り 2 項目を、本計画で解決した内容に置き換える。R2 復元とフォールバック色は実装済みになるため、運用手順の記述に改める。

```markdown
## 初回セットアップの自動化

- 壁紙は R2 に自動バックアップ（on-change, rclone copy）。フレッシュインストールでは `nix run .#restore-wallpaper` で復元する。
- 復号鍵（`~/.config/agenix/key.txt`）はフレッシュインストール時に手動配置が必要（唯一の手運び起点）。
- フォールバック色は home-manager activation で配置済み。R2 復元前でも waybar / wlogout が起動する。
```

- [ ] **Step 3: コミット**

```bash
git add todo.md
git commit -m "docs(todo): 初回セットアップ節を実装反映で更新、stale項目を削除"
```

---

## フレッシュインストール手順（完成後の運用メモ）

1. リポジトリを clone する。
2. 退避しておいた age 秘密鍵を `~/.config/agenix/key.txt` に置き `chmod 600` する。
3. `nix run .#switch` で反映する。agenix が復号し、フォールバック色が置かれ、waybar と wlogout が起動する。壁紙はまだ無い。
4. `nix run .#restore-wallpaper` で R2 から壁紙を取得する。pyprland が表示し matugen と wallust が本物の色を再生成する。

---

## Self-Review 結果

- **Spec coverage:** フォールバック色(Task 1)、認証の agenix 管理(Task 3,4)、rclone アーカイブ・on-change バックアップ(Task 5)、手動復元(Task 6)、初期アップロード(Task 6 Step 3)、人手手順(Task 2)、stale 整理(Task 7)。spec の各節に対応タスクがある。
- **依存順:** `.age` 不在で `nix build` が失敗するため、暗号化(Task 3)→配線(Task 4)→rclone(Task 5,6)の順に固定した。フォールバック色(Task 1)は独立で先行可能。
- **型・名称の一貫性:** remote 名 `r2`、バケット `dotfiles-wallpaper`、プレフィックス `wallpaper/`、復号先 `/run/agenix/rclone-r2.conf`、identity `/home/mkiin/.config/agenix/key.txt` を全タスクで統一。
