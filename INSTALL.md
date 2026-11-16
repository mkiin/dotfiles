# NixOS Installation

手順1〜6では `oregairu-yukino` を例に、yukino または yui に NixOS をインストールする。
iroha にインストールするときは「[yukino から iroha に NixOS をインストールする](#yukino-から-iroha-に-nixos-をインストールする)」を参照する。

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

## yukino から iroha に NixOS をインストールする

### iroha で USB から NixOS を起動する

1. NixOS Minimal ISO を書き込んだ USB メモリを iroha に挿す。電源を入れ、起動メニューで USB メモリを選んで NixOS を起動する。

2. NixOS が起動したら、端末で有線 LAN の IPv4 アドレスを調べる。

   ```bash
   ip -br -4 addr
   ```

3. 容量と型番からインストール先の SSD を特定する。`/dev/disk/by-id/` の一覧で、その SSD を指すパスを控える。

   ```bash
   lsblk -d -o NAME,SIZE,MODEL
   ls -l /dev/disk/by-id/
   ```

4. root のシェルを開く。

   ```bash
   sudo -i
   ```

5. root の SSH 用ディレクトリを作り、`authorized_keys` をエディタで開く。

   ```bash
   install -d -m 700 /root/.ssh
   nano /root/.ssh/authorized_keys
   ```

6. yukino の `vars/default.nix` で `mainSshAuthorizedKeys` にある `ssh-ed25519` で始まる公開鍵をコピーする。iroha で開いたファイルに、引用符を除いて1行で貼り付ける。Ctrl+O、Enter で保存し、Ctrl+X で閉じる。

### yukino でインストールの準備をする

1. dotfiles のディレクトリに移り、agenix を使える Bash を開く。以降の yukino の操作はこの端末で行う。

   ```bash
   cd ~/ghq/github.com/mkiin/dotfiles
   nix shell --inputs-from . agenix#agenix -c bash
   ```

2. `hosts/oregairu-iroha/disko.nix` を開く。

   ```bash
   vim hosts/oregairu-iroha/disko.nix
   ```

   `disko.devices.disk.system` の `device` に iroha で控えた `/dev/disk/by-id/` から始まるパスを書き、保存して閉じる。

3. 一時ディレクトリを作り、その中に iroha の SSH ホスト鍵を生成する。

   ```bash
   work=$(mktemp -d -p "$XDG_RUNTIME_DIR")
   install -d -m 755 "$work/extra" "$work/extra/etc" "$work/extra/etc/ssh"
   key="$work/extra/etc/ssh/ssh_host_ed25519_key"
   ssh-keygen -t ed25519 -N '' -C oregairu-iroha -f "$key"
   ```

4. 生成した公開鍵を表示し、`secrets/agenix-rules.nix` を開く。

   ```bash
   cat "$key.pub"
   vim secrets/agenix-rules.nix
   ```

5. `serverRecipients` の角括弧の中に、表示した公開鍵を二重引用符で囲んで書く。再インストールの場合は iroha の古い公開鍵を置き換える。ファイルを保存して閉じる。

6. 復旧用 USB を yukino に挿す。次の一覧で USB のパーティション名を調べる。

   ```bash
   lsblk -p -o NAME,SIZE,MODEL,LABEL,MOUNTPOINTS
   ```

7. パーティションのパスを入力する。`/mnt/recovery` を作り、そこに USB を読み取り専用でマウントする。

   ```bash
   read -rp '復旧用 USB のパーティション（/dev/…）: ' recovery_partition
   sudo mkdir -p /mnt/recovery
   sudo mount -o ro "$recovery_partition" /mnt/recovery
   ```

8. USB に `recovery_key` があることを確認する。

   ```bash
   ls -l /mnt/recovery/recovery_key
   ```

9. USB の秘密鍵で `user-password.age` を復号し、iroha の新しい鍵でも復号できるように暗号化し直す。パスフレーズを求められたら、USB の秘密鍵に設定したものを入力する。

   ```bash
   cd secrets
   TMPDIR="$XDG_RUNTIME_DIR" EDITOR=: agenix -e user-password.age -i /mnt/recovery/recovery_key
   cd ..
   ```

10. 復旧用 USB をアンマウントしてから抜く。

    ```bash
    sudo umount /mnt/recovery
    ```

### yukino から iroha の SSD にインストールする

1. USB から NixOS を起動したときに調べた iroha の IP アドレスを入力する。

   ```bash
   read -rp 'iroha の IP アドレス: ' usb_ip
   ```

2. yukino で次のコマンドを実行する。`remote-install` は `disko.nix` で指定した SSD を消去して NixOS をインストールし、先ほど作った SSH ホスト鍵を iroha の `/etc/ssh/` にコピーする。

   ```bash
   nix run .#remote-install -- --flake .#oregairu-iroha --target-host "root@$usb_ip" \
     --build-on local --no-substitute-on-destination --extra-files "$work/extra"
   ```

### SSD から起動した iroha の公開鍵を yukino に登録する

1. インストールが終わったら、iroha からインストール用 USB を抜き、SSD から NixOS を起動する。
2. iroha の端末で有線 LAN の IPv4 アドレスを調べる。

   ```bash
   ip -br -4 addr
   ```

3. yukino の端末にそのアドレスを入力する。

   ```bash
   read -rp 'SSD から起動した iroha の IP アドレス: ' iroha_ip
   ```

4. 再インストールで同じ IP アドレスを使う場合は、yukino から古い公開鍵を削除する。

   ```bash
   ssh-keygen -R "$iroha_ip"
   ```

5. iroha の IP アドレスと新しい公開鍵を yukino の `~/.ssh/known_hosts` に書き込む。

   ```bash
   awk -v host="$iroha_ip" '{print host, $1, $2}' "$key.pub" >> ~/.ssh/known_hosts
   ```

6. yukino から一時ディレクトリとその中の秘密鍵を削除する。

   ```bash
   rm -r -- "$work"
   ```

## yukino から iroha の設定を更新する

yukino の dotfiles のディレクトリで実行する。`192.168.1.50` は iroha の IP アドレスに置き換える。

```bash
nix run .#remote-switch -- oregairu-iroha --target 192.168.1.50
```
