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
vim secrets/agenix-rules.nix # recovery_key に公開鍵を登録し、recipients に追加
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
sudo chown -R mkiin:mkiin /home/mkiin/ghq/github.com/mkiin/dotfiles
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
vim '+1read /etc/ssh/ssh_host_ed25519_key.pub' secrets/agenix-rules.nix # let の直後に公開鍵を読み込む。編集後 :wq で保存
```

```nix
  oregairu-yukino = "ssh-ed25519 ..."; # 読み込んだ行をこの形に整える。鍵は省略せず、古い Yukino の宣言は削除
  recipients = [
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
