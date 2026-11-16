# NixOS のインストール

## nixos-anywhere を利用する場合

### インストール先のデバイスで USB から NixOS を起動する

1. NixOS Minimal ISO を書き込んだ USB メモリを挿す。電源を入れ、起動メニューで USB メモリを選んで NixOS を起動する。

2. 端末で `nixos` ユーザーのパスワードを設定する。

   ```bash
   passwd
   ```

3. 有線 LAN の IPv4 アドレスを控える。

   ```bash
   ip -br -4 addr
   ```

4. 容量と型番からインストール先の SSD を特定する。`/dev/disk/by-id/` の一覧で、その SSD を指すパスを控える。

   ```bash
   lsblk -d -o NAME,SIZE,MODEL
   ls -l /dev/disk/by-id/
   ```

### NixOS がインストール済みのデバイスで準備する

1. dotfiles のディレクトリで agenix を使える Bash を開く。このデバイスでのインストール作業には、以降も同じ端末を使う。

   ```bash
   cd ~/ghq/github.com/mkiin/dotfiles
   nix shell --inputs-from . agenix#agenix -c bash
   ```

2. `hosts/` の一覧からインストール先のホスト名を入力し、そのデバイスの `disko.nix` を開く。

   ```bash
   ls hosts/
   read -rp 'インストール先のホスト名: ' target_host
   vim "hosts/$target_host/disko.nix"
   ```

   `disko.devices.disk.system` の `device` に、先ほど控えた SSD のパスを書いて保存する。

3. 一時ディレクトリを作り、その中にインストール先の SSH ホスト鍵を生成する。

   ```bash
   work=$(mktemp -d -p "$XDG_RUNTIME_DIR")
   install -d -m 755 "$work/extra" "$work/extra/etc" "$work/extra/etc/ssh"
   key="$work/extra/etc/ssh/ssh_host_ed25519_key"
   ssh-keygen -t ed25519 -N '' -C "$target_host" -f "$key"
   ```

4. 公開鍵を表示し、`secrets/agenix-rules.nix` を開く。

   ```bash
   cat "$key.pub"
   vim secrets/agenix-rules.nix
   ```

5. インストール先に応じて公開鍵を登録する。再インストールの場合は、そのデバイスの古い公開鍵を置き換える。

   - デスクトップの場合は、インストール先のホスト名に公開鍵を割り当て、その名前を `desktopRecipients` に含める。
   - サーバーの場合は、公開鍵を二重引用符で囲んで `serverRecipients` に書く。

6. 復旧用 USB を NixOS がインストール済みのデバイスに挿し、パーティション名を調べる。

   ```bash
   lsblk -p -o NAME,SIZE,MODEL,LABEL,MOUNTPOINTS
   ```

7. パーティションのパスを入力し、USB を読み取り専用でマウントする。

   ```bash
   read -rp '復旧用 USB のパーティション（/dev/…）: ' recovery_partition
   sudo mkdir -p /mnt/recovery
   sudo mount -o ro "$recovery_partition" /mnt/recovery
   ```

8. USB に `recovery_key` があることを確認する。

   ```bash
   ls -l /mnt/recovery/recovery_key
   ```

9. `secrets/` に移り、USB の秘密鍵を使って `user-password.age` を暗号化し直す。パスフレーズを求められたら、復旧鍵のものを入力する。

   ```bash
   cd secrets
   TMPDIR="$XDG_RUNTIME_DIR" EDITOR=: agenix -e user-password.age -i /mnt/recovery/recovery_key
   ```

   インストール先がデスクトップの場合は、同じディレクトリで `rclone-r2.conf.age` も暗号化し直す。

   ```bash
   TMPDIR="$XDG_RUNTIME_DIR" EDITOR=: agenix -e rclone-r2.conf.age -i /mnt/recovery/recovery_key
   ```

10. dotfiles のルートに戻り、復旧用 USB をアンマウントして抜く。

    ```bash
    cd ..
    sudo umount /mnt/recovery
    ```

### NixOS がインストール済みのデバイスからインストールを実行する

1. USB から起動したインストール先の IP アドレスを入力する。

   ```bash
   read -rp 'インストール先の IP アドレス: ' usb_ip
   ```

2. 次のコマンドを実行する。`remote-install` は `disko.nix` で指定した SSD を消去して NixOS をインストールし、生成したホスト鍵をインストール先の `/etc/ssh/` にコピーする。

   ```bash
   nix run .#remote-install -- --flake ".#$target_host" --target-host "nixos@$usb_ip" \
     --build-on local --no-substitute-on-destination --extra-files "$work/extra"
   ```

   SSH のパスワードを求められたら、USB から起動した `nixos` ユーザーに設定したパスワードを入力する。

### インストール先のデバイスで SSD から NixOS を起動する

1. インストールが終わったら、インストール用 USB を抜いて SSD から NixOS を起動する。
2. 有線 LAN の IPv4 アドレスを控える。

   ```bash
   ip -br -4 addr
   ```

3. デスクトップの場合は `mkiin` でログインし、インストールに使った dotfiles を `~/ghq/github.com/mkiin/dotfiles` に置く。

### NixOS がインストール済みのデバイスに SSH ホスト公開鍵を登録する

1. インストールに使った端末に、SSD から起動したインストール先の IP アドレスを入力する。

   ```bash
   read -rp 'インストール先の IP アドレス: ' target_ip
   ```

2. 再インストールで同じ IP アドレスを使う場合は、古い公開鍵を削除する。

   ```bash
   ssh-keygen -R "$target_ip"
   ```

3. インストール先の IP アドレスと新しい公開鍵を `~/.ssh/known_hosts` に書き込む。

   ```bash
   awk -v host="$target_ip" '{print host, $1, $2}' "$key.pub" >> ~/.ssh/known_hosts
   ```

4. 一時ディレクトリとその中の秘密鍵を削除する。

   ```bash
   rm -r -- "$work"
   ```

### NixOS がインストール済みのデバイスから設定を更新する

インストール先に SSH で `root` としてログインできる場合は、dotfiles のディレクトリで Bash を開き、更新するデバイスのホスト名と IP アドレスを指定する。

```bash
cd ~/ghq/github.com/mkiin/dotfiles
bash
read -rp '更新するデバイスのホスト名: ' target_host
read -rp '更新するデバイスの IP アドレス: ' target_ip
nix run .#remote-switch -- "$target_host" --target "$target_ip"
```

## インストール先のデバイスだけで作業する場合

デスクトップに最小構成をインストールし、SSD から起動して普段使う構成を適用する。

### 1. 準備

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

### 2. 復旧鍵の初回準備

復旧鍵で両方の Secrets を復号確認済みなら、セクション3へ進む。
初めて復旧鍵を用意するときは、NixOS がインストール済みで、現在の `.age` ファイルを復号できるデバイスを使う。そこに復旧用 USB をマウントする。
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

### 3. ISO から最小 NixOS をインストール

NixOS Minimal ISO を UEFI で起動し、ネットワークに接続する。

```bash
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git \
  -c git clone https://github.com/mkiin/dotfiles.git
cd dotfiles
lsblk -o NAME,SIZE,MODEL,TYPE,MOUNTPOINTS
ls -l /dev/disk/by-id/
```

`hosts/` の一覧からインストール先のホスト名を入力する。SSD にはディスク全体を指す `/dev/disk/by-id/` のパスを指定する。

```bash
ls hosts/
read -rp 'インストール先のホスト名: ' target_host
read -rp 'インストール先の SSD（/dev/disk/by-id/…）: ' target_disk
```

対象 SSD のマウントと swap を解除する。

消去せず事前確認する場合：

```bash
sudo mkdir -p /mnt/disko-install-root
nix --extra-experimental-features 'nix-command flakes' run .#install -- --dry-run \
  "$target_host" "$target_disk" # disko.nix の SSD ID は更新される
```

**以下のコマンドは対話確認なしで、対象 SSD の既存パーティションとデータを消去する。**

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run .#install -- \
  "$target_host" "$target_disk"
```

インストール成功後に再起動し、SSD 上の最小 OS を起動する。

```bash
reboot
```

### 4. ホスト公開鍵を登録

`mkiin` と初期パスワードでログインする。必要なら `nmtui` でネットワークに接続する。

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
hostname
cat /etc/ssh/ssh_host_ed25519_key.pub
vim secrets/agenix-rules.nix
```

表示したホスト名に新しい公開鍵を割り当て、その名前を `desktopRecipients` に含める。再インストールの場合は、このデバイスの公開鍵だけを置き換える。

### 5. USB をマウントし Secrets を再暗号化

```bash
lsblk -f
ls -l /dev/disk/by-id/
sudo mkdir -p /mnt/recovery
printf '復旧用 USB のパーティション（/dev/disk/by-id/…）: '
read -r recovery_partition
sudo mount -o ro "$recovery_partition" /mnt/recovery
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

### 6. 本番構成を適用

```bash
nix run .#switch
```

適用成功後に再起動する。

```bash
reboot
```

再インストール前のパスワードでログインする。
公開鍵と Secrets の差分を確認し、commit・push する。
