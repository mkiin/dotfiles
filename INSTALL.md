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

## Yukino から G5 に NixOS をインストールする

1. G5 を NixOS の USB から起動する。IP アドレスとインストール先の SSD の ID を調べる。

   ```bash
   ip -br -4 addr
   lsblk -d -o NAME,SIZE,MODEL
   ls -l /dev/disk/by-id/
   ```

2. USB から起動した NixOS で、Yukino のログイン用 SSH 公開鍵を `/root/.ssh/authorized_keys` に貼り付ける。

   ```bash
   sudo -i
   install -d -m 700 /root/.ssh
   nano /root/.ssh/authorized_keys
   ```

3. Yukino の dotfiles で `nixosConfigurations.oregairu-iroha` を用意し、`hosts/oregairu-iroha/disko.nix` に手順1の SSD の `/dev/disk/by-id/…` を指定する。新規ファイルは `git add` する。

4. Yukino の dotfiles のルートで、Iroha の SSH ホスト鍵を作る。

   ```bash
   nix shell --inputs-from . agenix#agenix -c bash
   work=$(mktemp -d -p "$XDG_RUNTIME_DIR")
   install -d -m 755 "$work/extra" "$work/extra/etc" "$work/extra/etc/ssh"
   key="$work/extra/etc/ssh/ssh_host_ed25519_key"
   ssh-keygen -t ed25519 -N '' -C oregairu-iroha -f "$key"
   cat "$key.pub"
   ```

5. 表示した公開鍵を `secrets/agenix-rules.nix` の `serverRecipients` に書く。再インストール時は Iroha の古い公開鍵を置き換える。

6. Yukino で復旧用 USB を `/mnt/recovery` にマウントする。USB の秘密鍵で `user-password.age` を復号し、Iroha の新しい秘密鍵でも開けるように暗号化し直す。

   ```bash
   cd secrets
   TMPDIR="$XDG_RUNTIME_DIR" EDITOR=: agenix -e user-password.age -i /mnt/recovery/recovery_key
   cd ..
   ```

7. Yukino で手順1の IP アドレスを入力し、G5 の SSD を消去して NixOS をインストールする。

   ```bash
   read -rp 'USB から起動した G5 の IP アドレス: ' usb_ip
   nix run .#remote-install -- --flake .#oregairu-iroha --target-host "root@$usb_ip" \
     --build-on local --extra-files "$work/extra"
   ```

8. G5 を SSD から起動する。Yukino に G5 の SSH ホスト公開鍵を登録する。

   ```bash
   read -rp 'SSD から起動した G5 の IP アドレス: ' iroha_ip
   # 再インストール時のみ、次の行を実行する
   # ssh-keygen -R "$iroha_ip"
   awk -v host="$iroha_ip" '{print host, $1, $2}' "$key.pub" >> ~/.ssh/known_hosts
   rm -r -- "$work"
   git add secrets/agenix-rules.nix secrets/user-password.age
   git commit -m "Update Iroha SSH host public key"
   ```

9. Yukino で復旧用 USB をアンマウントする。

## Yukino から Iroha の NixOS 設定を更新する

`192.168.1.50` を Iroha の IP アドレスに置き換え、Yukino の dotfiles のルートで実行する。

```bash
nix run .#remote-switch -- oregairu-iroha --target 192.168.1.50
```
