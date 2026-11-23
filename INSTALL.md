# NixOS のインストール

コマンドの `<...>` は実際の値に置き換える。`<target_host>` には、インストール先に対応する `hosts/` 内のディレクトリ名を使う。

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

### USB から起動した NixOS のハードウェア設定を取得する

1. 操作元の PC の dotfiles ディレクトリで実行する。`<usb_ip>` には USB 起動中のインストール先の IP アドレスを指定する。

   ```bash
   ssh nixos@<usb_ip> 'nixos-generate-config --show-hardware-config --no-filesystems'
   ```

   パスワードを求められたら、`passwd` で設定したパスワードを入力する。

2. 表示された設定を `hosts/<target_host>/hardware-configuration.nix` に保存する。既存ファイルがある場合は、差分を確認して反映する。

   ```bash
   vim hosts/<target_host>/hardware-configuration.nix
   ```

### NixOS がインストール済みのデバイスで準備する

1. dotfiles のディレクトリで、インストール先の `disko.nix` を開く。

   ```bash
   vim hosts/<target_host>/disko.nix
   ```

   `disko.devices.disk.system` の `device` に、先ほど控えた SSD のパスを書いて保存する。

2. 一時ディレクトリを作り、その中にインストール先の SSH ホスト鍵を生成する。以降も同じ端末を使う。

   ```bash
   work=$(mktemp -d -p "$XDG_RUNTIME_DIR")
   install -d -m 755 "$work/extra" "$work/extra/etc" "$work/extra/etc/ssh"
   key="$work/extra/etc/ssh/ssh_host_ed25519_key"
   ssh-keygen -t ed25519 -N '' -C <target_host> -f "$key"
   ```

3. 公開鍵を表示し、`secrets/default.nix` を開く。

   ```bash
   cat "$key.pub"
   vim secrets/default.nix
   ```

4. インストール先に応じて公開鍵を登録する。再インストールの場合は、そのデバイスの古い公開鍵を置き換える。

   - デスクトップの場合は、インストール先のホスト名に公開鍵を割り当て、その名前を `recipientAliases.desktops` に含める。
   - サーバーの場合は、`recipientAliases` のホスト名に公開鍵を割り当て、その名前を `recipientAliases.servers` に含める。

5. dotfilesのルートで作業する。新しいファイルを追加した場合は `git add` する。

6. 操作しているデバイスの SSH ホスト秘密鍵で各ファイルを復号し、`secrets/default.nix` に登録した公開鍵で暗号化し直す。

   ```bash
   sudo nix-secrets rekey --flake ".#<target_host>" --storage ./secrets
   ```

   <details>
   <summary>このホスト鍵で復号できない .enc ファイルがある場合</summary>

   復旧用 USB を挿し、パーティションを調べる。

   ```bash
   lsblk -p -o NAME,SIZE,MODEL,LABEL,MOUNTPOINTS
   ```

   確認したパーティションを読み取り専用でマウントする。

   ```bash
   sudo mkdir -p /mnt/recovery
   sudo mount -o ro /dev/<partition> /mnt/recovery
   ```

   復号に USB の秘密鍵を使って、もう一度実行する。

   ```bash
   sudo nix-secrets rekey --flake ".#<target_host>" --storage ./secrets \
     --identity /mnt/recovery/recovery_key
   ```

   USB をアンマウントして抜く。

   ```bash
   sudo umount /mnt/recovery
   ```

   </details>

7. 暗号化し直したファイルの所有者とグループを `secrets/default.nix` に揃える。

   ```bash
   sudo chown --reference=secrets/default.nix secrets/*.enc
   ```

8. 変更した公開鍵と暗号化ファイルを確認する。

### NixOS がインストール済みのデバイスからインストールを実行する

`<usb_ip>` に USB から起動したときの IP アドレスを指定する。このコマンドは `disko.nix` で指定した SSD を消去し、NixOS と生成したホスト鍵をインストールする。

```bash
nix run .#remote-install -- --flake .#<target_host> --target-host nixos@<usb_ip> \
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

`<target_ip>` には、SSD から起動したときの IP アドレスを使う。

1. 再インストールで同じ IP アドレスを使う場合は、古い公開鍵を削除する。

   ```bash
   ssh-keygen -R <target_ip>
   ```

2. 新しい公開鍵の先頭に IP アドレスを付け、`~/.ssh/known_hosts` に追記する。

   ```bash
   echo "<target_ip> $(cat "$key.pub")" >> ~/.ssh/known_hosts
   ```

3. 一時ディレクトリとその中の秘密鍵を削除する。

   ```bash
   rm -r -- "$work"
   ```

### NixOS がインストール済みのデバイスから設定を更新する

操作元から `ssh root@<target_host>` で接続できる状態にして、dotfiles のディレクトリで実行する。ホスト名は flake の構成名と SSH の接続先を兼ねる。

```bash
nix run .#remote-switch -- <target_host>
```

## インストール先のデバイスだけで作業する場合

デスクトップに最小構成をインストールし、SSD から起動して普段使う構成を適用する。

### 1. 準備

- UEFI で起動する NixOS Minimal ISO
- インターネット接続
- インストール対象の SSD（既存データはすべて失われる）
- パスフレーズ付き復旧用 SSH 秘密鍵を保存した USB
- 復旧鍵で復号できる `user-password.enc`・`rclone-r2.conf.enc`・`nextcloud-app-password.enc`
- `installer/initial-password-hash` に設定した初期パスワード

対象 SSD が `hosts/<target_host>/disko.nix` のパーティション構成を収容できることを確認する。
必要な個人ファイルをバックアップする。
別のハードウェアに導入する場合は、対象ホストの hardware configuration を見直す。
新しいホストや設定ファイルを追加した場合は、対象ファイルを `git add` する。
ISO から取得する変更は事前に commit・push しておく。

### 2. 復旧鍵の初回準備

復旧鍵を登録済みなら、手順3へ進む。
初めて復旧鍵を用意するときは、NixOS がインストール済みで、現在の `.enc` ファイルを復号できるデバイスを使う。そこに復旧用 USB をマウントする。
以下の `/mnt/recovery` は実際の USB のマウント先に読み替える。

```bash
ssh-keygen -t ed25519 -a 256 \
  -C nix-secrets-recovery -f /mnt/recovery/recovery_key # パスフレーズを設定
cat /mnt/recovery/recovery_key.pub
vim secrets/default.nix # recipientAliases.recovery に公開鍵を登録
```

dotfiles のルートで、デスクトップのホスト名を `<target_host>` に指定し、登録した公開鍵で暗号化し直す。

```bash
sudo nix-secrets rekey --flake ".#<target_host>" --storage ./secrets
sudo chown --reference=secrets/default.nix secrets/*.enc
```

公開鍵の宣言と再暗号化した `.enc` ファイルを commit・push する。
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

対象 SSD のマウントと swap を解除する。`<ssd_id>` には、`/dev/disk/by-id/` の一覧からディスク全体を指す ID を指定する。

消去せず事前確認する場合：

```bash
sudo mkdir -p /mnt/disko-install-root
nix --extra-experimental-features 'nix-command flakes' run .#install -- --dry-run \
  <target_host> /dev/disk/by-id/<ssd_id> # disko.nix の SSD ID は更新される
```

**以下のコマンドは対話確認なしで、対象 SSD の既存パーティションとデータを消去する。**

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run .#install -- \
  <target_host> /dev/disk/by-id/<ssd_id>
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
vim secrets/default.nix
```

表示したホスト名に新しい公開鍵を割り当て、その名前を `recipientAliases.desktops` に含める。再インストールの場合は、このデバイスの公開鍵だけを置き換える。

### 5. USB をマウントし Secrets を再暗号化

復旧用 USB のパーティション名を調べる。

```bash
lsblk -fp
```

確認したパーティションを読み取り専用でマウントする。

```bash
sudo mkdir -p /mnt/recovery
sudo mount -o ro /dev/<partition> /mnt/recovery
```

復旧鍵で各ファイルを復号し、登録した公開鍵で暗号化し直す。パスフレーズを求められたら入力する。

```bash
sudo nix-secrets rekey --flake ".#<target_host>" --storage ./secrets \
  --identity /mnt/recovery/recovery_key
sudo chown --reference=secrets/default.nix secrets/*.enc
```

復旧用 USB をアンマウントする。

```bash
sudo umount /mnt/recovery
```

新しいホスト鍵で各ファイルを復号できることを確認する。

```bash
sudo age --decrypt -i /etc/ssh/ssh_host_ed25519_key secrets/user-password.enc > /dev/null
sudo age --decrypt -i /etc/ssh/ssh_host_ed25519_key secrets/rclone-r2.conf.enc > /dev/null
sudo age --decrypt -i /etc/ssh/ssh_host_ed25519_key secrets/nextcloud-app-password.enc > /dev/null
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
