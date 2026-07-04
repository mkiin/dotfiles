# root と user パスワードの宣言的統一管理（agenix） 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** root と mkiin に同一パスワードを agenix で宣言的に与え、クリーンインストールでも常に同じにする。

**Architecture:** yescrypt ハッシュ 1 つを agenix で暗号化し、root と mkiin の `hashedPasswordFile` を同じ復号先へ向ける。`mutableUsers = false` で宣言値を唯一の真実にし、username 不一致は build 時のアサーションで弾く。

**Tech Stack:** NixOS、agenix、mkpasswd（yescrypt）。

## Global Constraints

- パッケージ本体は集約 `packages.nix` にのみ書く。機能ディレクトリの `default.nix` は設定専用。
- コメントは非自明な理由だけを 1 から 2 行で書く。設定項目の言い換えコメントは書かない。
- 各タスクの完了前に `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。deadnix が未使用 let 束縛を検出する。
- root と mkiin は**同一パスワード**。暗号化ファイルは 1 つ（`nixos/core/secrets/password.age`）。
- 復号先はデフォルトの `/run/agenix/password`（owner root, mode 0400）。
- `mutableUsers = false`。identityPaths は `/home/${username}/.config/agenix/key.txt`（`mkiin` 直書きをやめ username 由来）。
- username 完全一致アサーション: `username == "mkiin"`。
- `username` は specialArgs 経由でモジュールに渡る。secrets/users モジュールは `username` を引数に取れる。

---

## ファイル構成

- `nixos/core/secrets/secrets.nix`（変更）：agenix ルールに `password.age` を追加。
- `nixos/core/secrets/password.age`（作成）：yescrypt ハッシュを暗号化。
- `nixos/core/secrets/default.nix`（変更）：`age.secrets."password"` 配線、identityPaths を username 由来へ。
- `nixos/core/users/default.nix`（変更）：`mutableUsers = false`、root/mkiin の `hashedPasswordFile`、username アサーション。

---

## Task 1: パスワードハッシュのプロビジョニング（人手）

`mkpasswd` と `agenix -e` は対話的で秘密を扱うため人手で実施する。

**Files:**

- Modify: `nixos/core/secrets/secrets.nix`
- Create: `nixos/core/secrets/password.age`

**Interfaces:**

- Consumes: mkiin の age 公開鍵（`secrets.nix` に既存）。
- Produces: `nixos/core/secrets/password.age`。後続タスクの `age.secrets."password".file` が参照する。

- [ ] **Step 1: secrets.nix に password のルールを追加**

`nixos/core/secrets/secrets.nix` を次にする。

```nix
let
  mkiin = "age1jsh6xwxl7gckzcc002feuzy2j4rtt635257gwkqd3c5pcv0yksxq7stjy8";
in
{
  "rclone-r2.conf.age".publicKeys = [ mkiin ];
  "password.age".publicKeys = [ mkiin ];
}
```

- [ ] **Step 2: パスワードハッシュを生成**

Run:

```bash
mkpasswd -m yescrypt
```

プロンプトに設定したいパスワードを入力する。出力される `$y$...` の行を控える（これが root と mkiin 共通のハッシュ）。

- [ ] **Step 3: agenix でハッシュを暗号化**

Run:

```bash
cd nixos/core/secrets
EDITOR=nvim nix run github:ryantm/agenix -- -e password.age -i ~/.config/agenix/key.txt
```

エディタが開くので、Step 2 の `$y$...` ハッシュを**1 行だけ**貼って保存する（余計な空行やコメントを残さない）。

- [ ] **Step 4: 暗号化を確認**

Run:

```bash
head -c 21 nixos/core/secrets/password.age; echo
```

Expected: `age-encryption.org/v1` で始まる。平文の `$y$` が見えてはならない。

- [ ] **Step 5: git add（コミットは Task 2 とまとめる）**

```bash
git add nixos/core/secrets/secrets.nix nixos/core/secrets/password.age
```

---

## Task 2: agenix に password を配線し identityPaths を username 由来にする

**Files:**

- Modify: `nixos/core/secrets/default.nix`

**Interfaces:**

- Consumes: `nixos/core/secrets/password.age`、specialArgs の `username`。
- Produces: 復号済み `/run/agenix/password`（owner root, mode 0400）。後続の `config.age.secrets."password".path` が参照する。

- [ ] **Step 1: secrets モジュールを更新**

`nixos/core/secrets/default.nix` を次にする。引数に `username` を足し、identityPaths のハードコードを解消し、password を配線する。

```nix
{ inputs, username, ... }:
{
  imports = [ inputs.agenix.nixosModules.default ];

  # SSH host key を持たないため個人 age 鍵を復号鍵にする。activation(root) から読める。
  age.identityPaths = [ "/home/${username}/.config/agenix/key.txt" ];

  # ユーザーの rclone user service と flake app から読めるよう owner を mkiin にする。
  age.secrets."rclone-r2.conf" = {
    file = ./rclone-r2.conf.age;
    path = "/run/agenix/rclone-r2.conf";
    owner = "mkiin";
    mode = "0400";
  };

  # root が /etc/shadow 生成時に読むため owner/mode はデフォルト(root, 0400)でよい。
  age.secrets."password".file = ./password.age;
}
```

- [ ] **Step 2: ビルドと整形を確認**

Run:

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

Expected: 成功。`username` は `mkiin` なので identityPaths の実パスは従来と同一（R2 復号も不変）。失敗する場合 `password.age` の未 git add か公開鍵不一致を疑う。

- [ ] **Step 3: コミット**

```bash
git add nixos/core/secrets/default.nix
git commit -m "feat(secrets): password を agenix 配線し identityPaths を username 由来に"
```

---

## Task 3: パスワードを適用し username アサーションを入れる

**Files:**

- Modify: `nixos/core/users/default.nix`

**Interfaces:**

- Consumes: `config.age.secrets."password".path`、specialArgs の `username`。
- Produces: root と mkiin に同一パスワード、`mutableUsers = false`、username アサーション。

- [ ] **Step 1: users モジュールを更新**

`nixos/core/users/default.nix` の引数に `config` を足し、末尾へ password 適用・mutableUsers・アサーションを追加する。既存の `programs.zsh` / `security.sudo` / `users.users.${username}` はそのまま残す。

先頭行を変更:

```nix
{
  pkgs,
  username,
  config,
  ...
}:
```

`users.users.${username}` ブロックの後（`}` の後）に次を追加:

```nix
  users.mutableUsers = false;
  users.users.${username}.hashedPasswordFile = config.age.secrets."password".path;
  users.users.root.hashedPasswordFile = config.age.secrets."password".path;

  # secrets と鍵パスは mkiin 用にプロビジョニング済み。username がずれると復号失敗で
  # mutableUsers=false 下ではロックアウトするため build 時に弾く。
  assertions = [
    {
      assertion = username == "mkiin";
      message = "secrets/鍵パスは mkiin 用。別ユーザーで使うには age 鍵とパスワードの再暗号化が必要。username を mkiin に合わせるか再プロビジョニングせよ。";
    }
  ];
```

- [ ] **Step 2: ビルドと整形を確認**

Run:

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

Expected: 成功。

- [ ] **Step 3: アサーションが機能することを確認**

`flake.nix` の `makeNixosConfig` の `username = "mkiin";` を一時的に `username = "other";` にして build し、アサーションで失敗することを確かめる。

Run:

```bash
sed -i 's/username = "mkiin";/username = "other";/' flake.nix
nix run .#build 2>&1 | grep -i "mkiin 用" && echo "ASSERTION FIRED"
git checkout -- flake.nix
```

Expected: `ASSERTION FIRED` が出て build が失敗する。確認後 `git checkout` で戻す（戻し忘れ厳禁）。

- [ ] **Step 4: switch してパスワードを検証（ロックアウト注意）**

別の TTY にログインセッションを 1 つ残したまま実施する（tty2 で `Ctrl+Alt+F2` 等）。

Run:

```bash
nix run .#switch
sudo -k
sudo true            # 設定したパスワードを求められ、通ればOK
su - "$USER" -c true # 同上
```

Expected: 設定したパスワードで `sudo` と `su` が通る。通らない場合は残した TTY のセッションから `git revert` 相当で戻し、鍵と `password.age` を点検する。

- [ ] **Step 5: コミット**

```bash
git add nixos/core/users/default.nix
git commit -m "feat(users): root/user に同一パスワードを宣言的付与(mutableUsers=false, username assertion)"
```

---

## フレッシュインストール手順（完成後の運用メモ）

1. インストーラで mkiin を作成し `/home/mkiin` を用意する。
2. clone し、age 鍵を `/home/mkiin/.config/agenix/key.txt` に置く（`nix run .#restore-agenix-key` か手動）。
3. `nixos-rebuild switch`。agenix が `password.age` を復号し root と mkiin に同一パスワードが入る。

---

## Self-Review 結果

- **Spec coverage:** 秘密生成(Task 1)、agenix 配線(Task 2)、identityPaths の username 化(Task 2)、mutableUsers=false と hashedPasswordFile(Task 3)、完全一致アサーション(Task 3)、ロックアウト対策(Task 3 Step 4)。spec の各節に対応がある。
- **依存順:** `password.age` 不在で build 失敗するため、暗号化(Task 1)→ secrets 配線(Task 2)→ users 適用(Task 3)の順に固定。
- **名称の一貫性:** 秘密名 `password`、復号先 `/run/agenix/password`、ルール `password.age`、identity `/home/${username}/.config/agenix/key.txt`、アサーション `username == "mkiin"` を全タスクで統一。
