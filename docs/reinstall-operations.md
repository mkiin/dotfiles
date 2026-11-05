# Yukino再インストール手順

操作場所を各段階に記載する。コマンドが失敗したら次へ進まない。
USB起動後にSSDを初期化するのはInstallerの実行時だけ。本番への切替では再初期化しない。

## 1. USB起動前: Yui

バックアップ・復元確認はユーザーから完了報告済み。
初期パスワードはYuiの `~/.local/state/dotfiles-installer/initial-password` で確認する。
パスワードや秘密鍵をチャットへ貼らない。Yukinoの復旧完了までYuiのホスト鍵を保持する。

この手順は公開mainブランチを使用する。

## 2. USB起動後: Yukinoで構成取得・初期OS導入

UEFIでMinimal ISOを起動し、ネット接続する。まず読み取り専用の確認を実行する。
公開GitHubからInstallerを取得するため、GitHubログインと手動cloneは不要。

```sh
nix --extra-experimental-features 'nix-command flakes' --option access-tokens '' run \
  'github:mkiin/dotfiles/main?dir=installer#install' -- \
  oregairu-yukino --dry-run
lsblk -o NAME,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS
```

表示されたSSDと `/dev/disk/by-id/nvme-eui.000000000000000100a075244c33c582` を照合する。
対象が違う場合は実行しない。以下はSSDを消去する。

```sh
nix --extra-experimental-features 'nix-command flakes' --option access-tokens '' run \
  'github:mkiin/dotfiles/main?dir=installer#install' -- \
  oregairu-yukino
```

Installerは対象SSDの表示と確認入力、Disko、nixos-installを順に実行する。
確認には表示されたby-idのフルパスを入力する。マウント中のディスク・有効なswapは消去しない。
ローカルcloneがある場合の入口は `nix run ./installer#install -- oregairu-yukino`。

インストール途中の通信断などで停止し、/mntと/mnt/bootが対象SSDからマウント済みの場合:

```sh
nix --extra-experimental-features 'nix-command flakes' --option access-tokens '' run \
  'github:mkiin/dotfiles/main?dir=installer#install' -- \
  oregairu-yukino --resume
```

--resumeは両マウントの親ディスクを照合し、Diskoを再実行せずnixos-installだけを再試行する。
マウントが失われた場合は停止する。ISO再起動後は既存パーティションを次でマウントしてから再試行する。
--resumeは親ディスクも照合する。初期化モードを再実行しない。

```sh
sudo mount /dev/disk/by-partlabel/disk-system-root /mnt
sudo mount --mkdir /dev/disk/by-partlabel/disk-system-ESP /mnt/boot
```

導入成功後にUSBを抜いて再起動し、mkiinと初期パスワードでログインする。
ネット接続を確認し、`ip -br address` でYukinoのIPを確認する。

## 3. 新ホスト公開鍵取得: YuiからYukinoへ接続

Yukinoのローカル端末で指紋を表示する。

```sh
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Yuiで実行する。IPは実値へ変更する。

```sh
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
yukino=mkiin@192.168.1.100
host_key=$(mktemp)
ssh "$yukino" 'cat /etc/ssh/ssh_host_ed25519_key.pub' >"$host_key"
ssh-keygen -lf "$host_key"
```

SSH初回接続の指紋もYukino画面と照合してから承認し、初期パスワードで接続する。
旧ホスト鍵によるknown_hostsの警告が出た場合は、指紋を照合してから該当する旧エントリを削除する。
YuiのSSHサーバーは鍵認証のみのため、この手順ではYuiを接続元にする。
送るのは公開鍵と暗号文だけで、ホスト秘密鍵は移動しない。

## 4. 登録・再暗号化: Yuiの一時コピーで実行

Yuiのdotfilesはcommit済みで変更のない状態から開始する。
同じ公開鍵がすでに登録され、agenixの受信者検査も成功する場合は再暗号化を省略する。

```sh
rekey_dir=$(mktemp -d /dev/shm/yukino-rekey.XXXXXX)
cp secrets/agenix-rules.nix secrets/user-password.age secrets/rclone-r2.conf.age "$rekey_dir/"
wl-copy <"$host_key"
```

一時コピーのagenix-rules.nixをエディタで開き、取得した公開鍵をyukinoとしてlet内へ追加する。
Yuiの公開鍵は維持し、recipientsを `[ yui yukino ]` にする。
Yukinoが登録済みで鍵を再生成した場合は、古いyukinoの値を新しい鍵へ置き換える。
漏洩した旧Yukino鍵と旧回復鍵は追加しない。

```sh
nvim "$rekey_dir/agenix-rules.nix"
```

```sh
sudo env TMPDIR=/dev/shm AGENIX_RULES="$rekey_dir/agenix-rules.nix" \
  nix --option access-tokens '' run --inputs-from . agenix -- \
  -r -i /etc/ssh/ssh_host_ed25519_key
sudo chown --reference=secrets/default.nix "$rekey_dir/user-password.age" "$rekey_dir/rclone-r2.conf.age"
AGENIX_RULES="$rekey_dir/agenix-rules.nix" nix --option access-tokens '' run --inputs-from . agenix -- -c
sudo nix --option access-tokens '' shell --inputs-from . nixpkgs#age -c \
  age -d -i /etc/ssh/ssh_host_ed25519_key "$rekey_dir/user-password.age" >/dev/null
sudo nix --option access-tokens '' shell --inputs-from . nixpkgs#age -c \
  age -d -i /etc/ssh/ssh_host_ed25519_key "$rekey_dir/rclone-r2.conf.age" >/dev/null
```

失敗時は一時コピーを破棄する。この段階では本番作業ツリーを一切変更していない。
agenixの一時平文はtmpfsを使うが、未暗号化swapへ退避される可能性はある。

## 5. 新Yukinoで復号確認

Yuiから暗号文とルールをYukinoの一時ディレクトリへ転送する。

```sh
ssh "$yukino" 'mkdir -p ~/.cache/agenix-enroll'
scp "$rekey_dir/agenix-rules.nix" "$rekey_dir/user-password.age" "$rekey_dir/rclone-r2.conf.age" \
  "$yukino:/home/mkiin/.cache/agenix-enroll/"
```

Yukinoの端末で実行する。両方の終了コード0を確認するまで本番へ進まない。

```sh
sudo /run/current-system/sw/bin/age -d -i /etc/ssh/ssh_host_ed25519_key ~/.cache/agenix-enroll/user-password.age >/dev/null
sudo /run/current-system/sw/bin/age -d -i /etc/ssh/ssh_host_ed25519_key ~/.cache/agenix-enroll/rclone-r2.conf.age >/dev/null
```

転送失敗時は同じ3ファイルの転送をやり直す。本番作業ツリーはまだ変更していない。

## 6. 本番へ切替: Yukino

初期OSにはGitがある。公開ブランチを取得し、検証済みの3ファイルを反映する。

```sh
mkdir -p ~/ghq/github.com/mkiin
cd ~/ghq/github.com/mkiin
git clone --branch main https://github.com/mkiin/dotfiles.git
cd dotfiles
cp ~/.cache/agenix-enroll/agenix-rules.nix ~/.cache/agenix-enroll/user-password.age ~/.cache/agenix-enroll/rclone-r2.conf.age secrets/
git add secrets/agenix-rules.nix secrets/user-password.age secrets/rclone-r2.conf.age
nix --option access-tokens '' --accept-flake-config build \
  .#nixosConfigurations.oregairu-yukino.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake .#oregairu-yukino
```

GitHubへのcommit・push・ユーザーSSH鍵の登録は本番切替の条件ではない。
ビルド失敗時は修正後にビルドを再試行し、Diskoは実行しない。
暗号文を元へ戻す場合は、3ファイルだけ `git restore --source=HEAD --staged --worktree --` で戻す。
switch失敗時は初期OSの世代を保持して原因を解消する。成功後も動作確認までは世代削除・GCをしない。

再起動し、本番パスワードでのローカルログイン・sudo・ネットワーク・Secrets・GPU・デスクトップを確認する。
本番のSSHは鍵認証へ戻る。本番用ユーザー鍵の整備はホスト鍵の登録とは別作業。

## 7. 復旧後の反映

Yuiでも検証済みの一時コピー3ファイルをsecretsへ反映してcommit・pushする。
反映途中で失敗したら、同じ3ファイルをHEADからrestoreして一時コピーからやり直す。
push後、別のHTTPS cloneで受信者検査と評価を実行し、ローカル変更への依存がないことを確認する。
確認後に一時ディレクトリと公開鍵の一時ファイルを削除する。
元のnix-secretsは移行直後には削除しない。

VM試験はユーザー判断で省略済み。実機の起動・ログイン試験の成功を事前に主張しない。
