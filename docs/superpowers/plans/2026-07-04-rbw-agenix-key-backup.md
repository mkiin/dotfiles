# rbw による agenix マスター鍵の CLI 保管/復元 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** agenix の復号鍵を Bitwarden へ CLI で保管し、フレッシュインストール時に CLI 一貫で復元できるようにする。

**Architecture:** home-manager の `programs.rbw` で rbw を宣言的に導入し、`backup-agenix-key` と `restore-agenix-key` の 2 つの flake app で鍵の保管と復元を行う。保管は rbw の editor に `cp` を見せかけて秘密鍵行を流し込み、復元は switch より前に単独で走らせて `~/.config/agenix/key.txt` を配置する。

**Tech Stack:** Nix / home-manager、rbw（非公式 Bitwarden CLI）、pinentry-curses、flake apps（`pkgs.writeShellScript`）。

## Global Constraints

- パッケージ本体は集約 `packages.nix` にのみ書く。`programs.<foo>.enable` は正しい設定機構であり直書きに当たらない。flake app 内の `${pkgs.X}/bin/...` 絶対パス参照も宣言ではないため許容。
- コメントは非自明な理由だけを 1 から 2 行で書く。
- 各タスクの完了前に `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。deadnix が未使用 let 束縛を検出する。
- rbw エントリ名は `agenix-age-key`。保管するのは `AGE-SECRET-KEY-` で始まる 1 行だけ。復号鍵の配置先は `~/.config/agenix/key.txt`（mode 0400）。
- email は公開情報として app に定数で埋める（`blckcaties@gmail.com`）。pinentry は `pkgs.pinentry-curses`。
- `programs.rbw.settings.pinentry` は package を取る（例 `pkgs.pinentry-gnome3`）。

---

## ファイル構成

- `home-manager/cli/rbw/default.nix`（作成）：`programs.rbw` の宣言的設定（email, pinentry）。
- `home-manager/cli/default.nix`（変更）：imports に `./rbw` を追加。
- `flake.nix`（変更）：`apps.${system}` に `backup-agenix-key` と `restore-agenix-key` を追加。

---

## Task 1: rbw を宣言的に導入する

**Files:**

- Create: `home-manager/cli/rbw/default.nix`
- Modify: `home-manager/cli/default.nix`

**Interfaces:**

- Consumes: なし。
- Produces: `rbw` を PATH に載せ、`~/.config/rbw/config.json` に email と pinentry を設定する。後続の flake app が `rbw` を使う。

- [ ] **Step 1: rbw モジュールを作成**

```nix
{ pkgs, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "blckcaties@gmail.com";
      # 端末内で解錠が完結する curses 版。GUI 解錠が要るなら pinentry-gnome3 に替える。
      pinentry = pkgs.pinentry-curses;
    };
  };
}
```

- [ ] **Step 2: cli の imports に追加**

`home-manager/cli/default.nix` の imports リストへ `./rbw` を足す。

```nix
{ ... }:
{
  imports = [
    ./packages.nix
    ./zsh
    ./git
    ./mise
    ./lazygit
    ./starship
    ./sheldon
    ./yazi
    ./goclipboard
    ./python
    ./rbw
  ];
}
```

- [ ] **Step 3: ビルドと整形を確認**

Run:

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

Expected: 両方成功。deadnix エラーなし。

- [ ] **Step 4: switch して rbw が入るか確認**

Run:

```bash
nix run .#switch
command -v rbw && rbw --version
test -e ~/.config/rbw/config.json && grep -o '"email":"[^"]*"' ~/.config/rbw/config.json
```

Expected: `rbw` のパスとバージョンが出る。config.json に email が入っている。

- [ ] **Step 5: コミット**

```bash
git add home-manager/cli/rbw/default.nix home-manager/cli/default.nix
git commit -m "feat(cli): rbw を宣言的に導入(programs.rbw, pinentry-curses)"
```

---

## Task 2: 鍵を保管する flake app

**Files:**

- Modify: `flake.nix`

**Interfaces:**

- Consumes: `~/.config/agenix/key.txt`、`pkgs.rbw`。rbw が unlock 済みであること。
- Produces: flake app `backup-agenix-key`。Bitwarden にエントリ `agenix-age-key` を作る/更新する。

- [ ] **Step 1: backup-agenix-key を追加**

`flake.nix` の `apps.${system}` 内、`switch` ブロックの後へ足す。

```nix
        backup-agenix-key = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "backup-agenix-key" ''
              set -eo pipefail
              rbw="${pkgs.rbw}/bin/rbw"
              key="$HOME/.config/agenix/key.txt"

              [ -e "$key" ] || { echo "no key at $key" >&2; exit 1; }
              "$rbw" unlocked || { echo "rbw is locked. run: rbw unlock" >&2; exit 1; }

              tmp=$(mktemp)
              trap 'rm -f "$tmp"' EXIT
              grep '^AGE-SECRET-KEY-' "$key" > "$tmp"
              [ -s "$tmp" ] || { echo "no AGE-SECRET-KEY line in $key" >&2; exit 1; }

              # rbw は $EDITOR に一時ファイルを渡す。cp を editor に見せかけ内容を流し込む。
              # 既存エントリに add すると重複するため、有無で add/edit を分ける。
              if "$rbw" get agenix-age-key >/dev/null 2>&1; then
                EDITOR="cp $tmp" "$rbw" edit agenix-age-key
              else
                EDITOR="cp $tmp" "$rbw" add agenix-age-key
              fi
              echo "Stored age key to Bitwarden entry 'agenix-age-key'."
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

- [ ] **Step 3: rbw を unlock して保管を実行**

Run:

```bash
rbw unlock
nix run .#backup-agenix-key
```

Expected: `Stored age key to Bitwarden entry 'agenix-age-key'.`
（rbw 未ログインなら先に `rbw login`。2FA 等で拒否される場合は `rbw register` を挟む。）

- [ ] **Step 4: 保管内容を検証**

Run:

```bash
rbw sync
diff <(rbw get agenix-age-key) <(grep '^AGE-SECRET-KEY-' ~/.config/agenix/key.txt) && echo MATCH
```

Expected: `MATCH`（Bitwarden の値とローカルの秘密鍵行が一致）。

- [ ] **Step 5: コミット**

```bash
git add flake.nix
git commit -m "feat(flake): agenix 鍵を Bitwarden に保管する backup-agenix-key app"
```

---

## Task 3: 鍵を復元する flake app

**Files:**

- Modify: `flake.nix`

**Interfaces:**

- Consumes: `pkgs.rbw`、`pkgs.pinentry-curses`。Bitwarden のエントリ `agenix-age-key`。
- Produces: flake app `restore-agenix-key`。`~/.config/agenix/key.txt` を配置する。

- [ ] **Step 1: restore-agenix-key を追加**

`flake.nix` の `apps.${system}` 内、`backup-agenix-key` の後へ足す。

```nix
        restore-agenix-key = {
          type = "app";
          program = toString (
            pkgs.writeShellScript "restore-agenix-key" ''
              set -eo pipefail
              # home-manager 適用前でも動くよう rbw と pinentry を nix から供給する。
              export PATH="${pkgs.pinentry-curses}/bin:$PATH"
              rbw="${pkgs.rbw}/bin/rbw"
              key="$HOME/.config/agenix/key.txt"

              if [ -e "$key" ]; then
                echo "key already exists at $key (refusing to overwrite)" >&2
                exit 1
              fi

              "$rbw" config set email blckcaties@gmail.com
              "$rbw" config set pinentry pinentry-curses

              # 既に unlock 済みなら login/unlock を飛ばす。マスターパスワードの手入力が唯一の起点。
              if ! "$rbw" unlocked 2>/dev/null; then
                "$rbw" login
                "$rbw" unlock
              fi

              mkdir -p "$(dirname "$key")"
              "$rbw" get agenix-age-key > "$key"
              chmod 600 "$key"
              echo "Restored age key to $key."
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

- [ ] **Step 3: ラウンドトリップを検証（本物の鍵は消さない）**

`restore-agenix-key` は `key.txt` が既存だと拒否するため、検証は一時パスへ手動で行う。

Run:

```bash
export PATH="$(nix build --no-link --print-out-paths nixpkgs#pinentry-curses)/bin:$PATH"
rbw unlock
tmp=$(mktemp)
rbw get agenix-age-key > "$tmp"
diff "$tmp" <(grep '^AGE-SECRET-KEY-' ~/.config/agenix/key.txt) && echo ROUNDTRIP_OK
rm -f "$tmp"
```

Expected: `ROUNDTRIP_OK`（Bitwarden から取得した内容が現在の秘密鍵行と一致）。

- [ ] **Step 4: 既存拒否の動作を確認**

Run:

```bash
nix run .#restore-agenix-key
```

Expected: `key already exists at ...（refusing to overwrite）` で終了コード 1。既存の鍵を壊さないこと。

- [ ] **Step 5: コミット**

```bash
git add flake.nix
git commit -m "feat(flake): agenix 鍵を Bitwarden から復元する restore-agenix-key app"
```

---

## フレッシュインストール手順（完成後の運用メモ）

1. リポジトリを clone する。
2. `nix run .#restore-agenix-key` を実行する（`rbw login` でマスターパスワードを手入力 → `key.txt` 配置）。
3. `nix run .#switch` を実行する（agenix が復号）。
4. 壁紙などの復元コマンドを実行する。

---

## Self-Review 結果

- **Spec coverage:** rbw 宣言導入(Task 1)、保管フロー(Task 2)、復元フロー(Task 3)、保管内容=秘密鍵1行(Task 2 Step 1)、既存エントリの edit 分岐(Task 2)、既存 key.txt の上書き拒否(Task 3)、fresh install の並び（運用メモ）。spec の各節に対応がある。
- **Placeholder scan:** email は実値 `blckcaties@gmail.com`、エントリ名 `agenix-age-key`、pinentry は `pkgs.pinentry-curses` で統一。TBD なし。
- **型・名称の一貫性:** エントリ名 `agenix-age-key`、鍵パス `~/.config/agenix/key.txt`、`grep '^AGE-SECRET-KEY-'` を全タスクで統一。`programs.rbw.settings.pinentry` は package を渡す（実物確認済み）。
