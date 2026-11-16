# NixOS Installation

対象は `oregairu-yukino` と `oregairu-yui`。以下は Yukino の例。

## 1. 準備

- UEFI で起動する NixOS Minimal ISO
- インターネット接続
- インストール対象の SSD（既存データはすべて失われる）
- パスフレーズ付き復旧用 SSH 秘密鍵を保存した USB
- 復旧鍵で復号できる `user-password.age` と `rclone-r2.conf.age`
- `installer/initial-password-hash` に設定した初期パスワード

対象 SSD が `hosts/<host>/disko.nix` のパーティション構成を収容できることを確認する。
必要な個人ファイルをバックアップする。
別のハードウェアに導入する場合は、対象ホストの hardware configuration を見直す。
新しいホストや設定ファイルを追加した場合は、対象ファイルを `git add` する。
ISO から取得する変更は事前に commit・push しておく。

## 2. 復旧鍵の初回準備

復旧鍵で両方の Secrets を復号確認済みなら、セクション3へ進む。
現在の Secrets を復号できる既存 NixOS 上で、USB をマウントして実行する。
以下の `/mnt/recovery` は実際の USB のマウント先に読み替える。

```bash
ssh-keygen -t ed25519 -a 256 \
  -C agenix-recovery -f /mnt/recovery/recovery_key # パスフレーズを設定
cat /mnt/recovery/recovery_key.pub
vim secrets/agenix-rules.nix # recovery_key に公開鍵を登録し、desktopRecipients に追加
```

リポジトリのルートから実行する。

```bash
cd secrets
sudo nix shell --inputs-from .. github:ryantm/agenix#agenix \
  -c agenix -r -i /etc/ssh/ssh_host_ed25519_key

nix shell --inputs-from .. github:ryantm/agenix#agenix \
  -c agenix -d user-password.age -i /mnt/recovery/recovery_key > /dev/null
nix shell --inputs-from .. github:ryantm/agenix#agenix \
  -c agenix -d rclone-r2.conf.age -i /mnt/recovery/recovery_key > /dev/null
cd ..
```

`401 Bad credentials` が出た場合は、`nix --option access-tokens '' shell ...` で再実行する。
両方の復号成功を確認し、公開鍵の宣言と `.age` を commit・push する。
復旧秘密鍵は USB に保管し、repo や SSD にコピーしない。

初期パスワードを設定し直す場合：

```bash
mkpasswd --method=yescrypt > installer/initial-password-hash
```

入力した初期パスワードを控え、変更したハッシュを commit・push する。

## 3. ISO から最小 NixOS をインストール

NixOS Minimal ISO を UEFI で起動し、ネットワークに接続する。

```bash
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git \
  -c git clone https://github.com/mkiin/dotfiles.git
cd dotfiles
lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS
ls -l /dev/disk/by-id/
```

対象 SSD の by-id を確認する。USB やパーティションの ID を指定しない。
対象 SSD のマウントと swap を解除する。

消去せず事前確認する場合：

```bash
sudo mkdir -p /mnt/disko-install-root
nix --extra-experimental-features 'nix-command flakes' run .#install -- --dry-run \
  oregairu-yukino /dev/disk/by-id/<SSD-ID> # disko.nix の SSD ID は更新される
```

**以下のコマンドは対話確認なしで、対象 SSD の既存パーティションとデータを消去する。**

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run .#install -- \
  oregairu-yukino /dev/disk/by-id/<SSD-ID>
```

インストール成功後に再起動し、SSD 上の最小 OS を起動する。

```bash
reboot
```

## 4. ホスト公開鍵を登録

`mkiin` と初期パスワードでログインする。必要なら `nmtui` でネットワークに接続する。

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
vim '+1read /etc/ssh/ssh_host_ed25519_key.pub' secrets/agenix-rules.nix # let の直後に公開鍵を読み込む。編集後 :wq で保存
```

```nix
  oregairu-yukino = "ssh-ed25519 ..."; # 読み込んだ行をこの形に整える。鍵は省略せず、古い Yukino の宣言は削除
  desktopRecipients = [
    oregairu-yui # Yui と復旧鍵の値は変更しない
    oregairu-yukino # なければ追加
    recovery_key
  ];
```

## 5. USB をマウントし Secrets を再暗号化

```bash
lsblk -f
ls -l /dev/disk/by-id/
sudo mkdir -p /mnt/recovery
sudo mount -o ro /dev/disk/by-id/<USB-PARTITION-ID> /mnt/recovery
ls /mnt/recovery/recovery_key
```

```bash
cd secrets
TMPDIR="$XDG_RUNTIME_DIR" agenix -r -i /mnt/recovery/recovery_key # 復旧鍵のパスフレーズを入力
agenix -c
```

鍵の読み取り権限がない場合は、次で再暗号化する。

```bash
sudo env TMPDIR=/run agenix -r -i /mnt/recovery/recovery_key
agenix -c
```

両方の鍵で復号できることを確認する。

```bash
agenix -d user-password.age -i /mnt/recovery/recovery_key > /dev/null
agenix -d rclone-r2.conf.age -i /mnt/recovery/recovery_key > /dev/null
sudo agenix -d user-password.age -i /etc/ssh/ssh_host_ed25519_key > /dev/null
sudo agenix -d rclone-r2.conf.age -i /etc/ssh/ssh_host_ed25519_key > /dev/null
sudo umount /mnt/recovery
cd .. # リポジトリのルートに戻る
```

## 6. 本番構成を適用

```bash
nix run .#switch -- oregairu-yukino
```

適用成功後に再起動する。

```bash
reboot
```

再インストール前のパスワードでログインする。
公開鍵と Secrets の差分を確認し、commit・push する。

## Yukino からのリモートインストール

対象は `nixosConfigurations.<host>` に登録済みのサーバー。以下のホスト名は
`oregairu-iroha`。実行前に本番構成・実機のハードウェア設定・disko の単一
`system` ディスクを用意し、SSD 全体の by-id を指定する。インストールする
構成は共通の `user-password` だけを復号する。以下の操作はリポジトリの
ルートで行う。USB 起動環境に本番用の dotfiles を置く必要はない。

1. G5 を NixOS Minimal ISO で UEFI 起動し、Live の root に Yukino の
   **ログイン公開鍵**を登録する。G5 本体で LAN IP、SSD の by-id、Live の
   指紋を確認する。

   ```sh
   ip -br addr
   lsblk -d -o NAME,SIZE,MODEL,SERIAL
   ls -l /dev/disk/by-id/
   ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. Yukino 側で Live 環境専用の SSH エイリアスを設定する。`HostName` は
   手順1の LAN IP。初回の SSH で本体に表示された指紋と一致することを確認
   する。Live ISO の再起動で鍵が変わった場合も本体で照合し直す。

   ```sshconfig
   Host iroha-live
     HostName <G5のLAN-IP>
     HostKeyAlias iroha-live
     HostKeyAlgorithms ssh-ed25519
     User root
   ```

   ```sh
   ssh -o StrictHostKeyChecking=ask root@iroha-live true
   ssh -o BatchMode=yes -o StrictHostKeyChecking=yes root@iroha-live true
   ```

3. 今回の本番ホスト鍵を作る。表示された**公開鍵だけ**を
   `secrets/agenix-rules.nix` の `serverRecipients` に登録する。
   再インストールなら同じホストの古い鍵と置き換える。秘密鍵は Yukino の
   `$XDG_RUNTIME_DIR/dotfiles-install-oregairu-iroha/` に一時保存される。
   `prepare` は処理中の鍵を上書きしない。

   ```sh
   nix run .#remote-install -- prepare oregairu-iroha
   ```

4. 復旧 USB を Yukino に接続する。**以下は指定した G5 の SSD を消去する。**
   `--erase` に渡した by-id が flake のディスクと一致し、Live 上で実在する
   内蔵ディスクと確認できた場合のみ続行する。

   ```sh
   nix run .#remote-install -- apply oregairu-iroha iroha-live \
     --erase /dev/disk/by-id/<SSD-ID> --recovery-key /mnt/recovery/recovery_key
   ```

   app は USB の鍵で `secrets/user-password.age` だけを再暗号化し、本番鍵で
   復号できることを確認する。平文をファイルに保存せず、復旧鍵は転送しない。
   Yukino でビルドし、Live 環境への認証済み SSH 経路を通して
   `nixos-anywhere --extra-files` で本番ホスト鍵を配置する。成功後、
   本番 SSH 照合用の公開鍵を `~/.ssh/dotfiles-hosts/oregairu-iroha` に保存し、
   一時秘密鍵を削除する。公開鍵のルールと暗号ファイルの差分を確認し、Git に残す。

   インストール前に失敗した場合は原因を直し、同じセッションで `apply` を
   再実行できる。SSD 書き込み後に切断した場合は、再度消去する前に G5 の起動状態を
   本体で確認する。SSD からすでに起動している場合は、手順3の公開鍵を
   `<本番ホスト名> ssh-ed25519 <公開鍵本体>` の形式で上記の照合用ファイルに
   保存すれば、再インストールせず接続できる。処理を中止した場合は、一時ディレクトリを
   削除し、未適用の受信者・暗号ファイルの変更を確認する。

## Yukino からの remote switch

G5 が SSD の本番 OS で起動したら、登録済みの本番ホスト鍵と照合して接続する。
初回は `mkiin` でのログインとパスワード付き sudo も確認する。
たとえば SSH 設定に次の本番用エイリアスを置けば、通常の SSH でも同じ公開鍵を使える。

```sshconfig
Host oregairu-iroha
  HostName <G5の本番LAN-IP>
  HostKeyAlias oregairu-iroha
  UserKnownHostsFile ~/.ssh/dotfiles-hosts/oregairu-iroha
  StrictHostKeyChecking yes
```

```sh
ssh mkiin@oregairu-iroha
nix run .#remote-switch -- oregairu-iroha
```

`remote-switch` は Yukino でビルドし、`root@oregairu-iroha` で
`nixos-rebuild switch` を実行する。本番 SSH 鍵とホスト名が一致しない場合は
停止する。接続先を別の LAN IP または SSH エイリアスにする場合は
`--target <接続先>` を指定する。通常の更新に復旧 USB は使わない。
