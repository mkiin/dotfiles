# 再インストール操作仕様

## 現在採用する復旧方式

安全なYuiのホスト秘密鍵を使い、2ファイルを再暗号化する。
漏洩した可能性がある旧Yukino鍵と `mkiin@recovery` は移行後の受信者に含めない。
`nix-access-tokens` は不要になったため移行しない。
専用オフライン回復鍵は後日対応。Yukino復旧完了までYuiのOSとホスト鍵を保持する。
両ホストの鍵を失う場合の復旧は、この方式では保証しない。

## ツール環境

リポジトリのルートで実行する。既存lockのnixpkgsとagenixのみを使う。
以下はGitHub認証を使わない。秘密鍵の内容を端末へ表示しない。

```sh
nix --option access-tokens '' develop --impure \
  --expr 'import ./scripts/reinstall-tools.nix'
```

環境内での試験:

```sh
bash tests/check-installer-password.sh
python3 -B -m unittest discover -s tests -p 'test_*.py' -v
```

## Yuiでの初回移行

上記のツール環境に入った状態で、Yuiのローカル端末から既存の2ファイルを検査する。
sudoにはageの絶対パスを渡す。平文は表示・保存しない。
各コマンドの終了コード0が成功。失敗した場合は移行を進めない。

```sh
sudo "$(command -v age)" --decrypt --identity /etc/ssh/ssh_host_ed25519_key \
  ../nix-secrets/user-password.age >/dev/null
sudo "$(command -v age)" --decrypt --identity /etc/ssh/ssh_host_ed25519_key \
  ../nix-secrets/rclone-r2.conf.age >/dev/null
```

検査成功後、初回だけ次を実行する。元のnix-secretsは変更しない。
現時点では自動実行していない。

```sh
sudo nix --option access-tokens '' develop --impure \
  --expr 'import ./scripts/reinstall-tools.nix' \
  -c python3 -B scripts/enroll.py . oregairu-yui \
  /etc/ssh/ssh_host_ed25519_key.pub /etc/ssh/ssh_host_ed25519_key \
  --initialize-from ../nix-secrets
```

この処理はYuiだけを受信者にしたルールと2ファイルを作成する。
全ファイルの事前復号、agenixの受信者検査、再暗号化前後の平文ハッシュ一致を確認する。
成功後に本番のローカル参照への変更・非公開input除去・評価とビルドを行う。
平文のハッシュはログやGitへ出さない。

## 新しいYukinoの登録

初期OS起動後、同一ネットワークのYukinoへYuiからSSH接続する。
接続先IPとホスト鍵の指紋はYukinoのローカル画面で照合する。
初期ログインパスワードは `bash scripts/set-installer-password.sh` で設定する。
このスクリプトは対話入力からハッシュだけを作り、Gitへstageする。
初期パスワードは専用のものを使い、本番パスワードは流用しない。
`--generate` を付けるとランダムな専用パスワードをGit管理外に保存する。
今回の生成先はYuiの `~/.local/state/dotfiles-installer/initial-password`。
値はユーザーのローカル端末で確認し、チャットや作業ログには貼らない。

1. SSHで `/etc/ssh/ssh_host_ed25519_key.pub` だけをYuiへ取得する。
2. Yui上で `enroll.py REPO oregairu-yukino PUBLIC_KEY /etc/ssh/ssh_host_ed25519_key` を実行する。
   上記と同じsudoのツール環境を使う。他ホストの受信者は維持する。
3. 更新したルールと2つの `.age` をYukinoのdotfilesへ転送する。
4. Yukinoで自分のホスト秘密鍵を使い、2ファイルの復号試験を行う。
5. 復号成功後に3ファイルをgit addし、本番ビルドへ進む。commit・pushはこの時点では不要。
6. 本番適用、再起動、ログイン・sudo・ネットワーク・Secrets・デスクトップを確認する。
7. 更新した暗号文を公開Gitへ反映し、クリーンcloneから評価する。

SSHホスト秘密鍵を送信・上書きしない。enroll自身はGit index・ブランチ・OSを変更しない。

実際の転送コマンド（Yui側、IPとリモート作業ツリーのパスを実値へ置き換える）:

```sh
yukino=mkiin@192.168.1.100
remote_repo=/home/mkiin/ghq/github.com/mkiin/dotfiles
public_key=$(mktemp)
ssh "$yukino" 'cat /etc/ssh/ssh_host_ed25519_key.pub' >"$public_key"
ssh-keygen -lf "$public_key"
```

この指紋を、Yukinoのローカル端末の
`ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub` と照合してから登録する。

```sh
sudo nix --option access-tokens '' develop --impure \
  --expr 'import ./scripts/reinstall-tools.nix' \
  -c python3 -B scripts/enroll.py . oregairu-yukino \
  "$public_key" /etc/ssh/ssh_host_ed25519_key
rm "$public_key"
scp secrets/agenix-rules.nix secrets/user-password.age secrets/rclone-r2.conf.age \
  "$yukino:$remote_repo/secrets/"
```

転送失敗時は、同じ3ファイルの転送を再実行する。全ファイル転送後に、Yukinoで実行する:

```sh
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix --option access-tokens '' develop --impure \
  --expr 'import ./scripts/reinstall-tools.nix'
sudo "$(command -v age)" --decrypt --identity /etc/ssh/ssh_host_ed25519_key \
  secrets/user-password.age >/dev/null
sudo "$(command -v age)" --decrypt --identity /etc/ssh/ssh_host_ed25519_key \
  secrets/rclone-r2.conf.age >/dev/null
git add secrets/agenix-rules.nix secrets/user-password.age secrets/rclone-r2.conf.age
nix --option access-tokens '' build \
  .#nixosConfigurations.oregairu-yukino.config.system.build.toplevel --no-link
sudo nixos-rebuild switch --flake .#oregairu-yukino
```

各コマンドの成功を確認してから次へ進む。初期OSの世代を残し、
本番再起動後のログインとsudoを確認するまでは世代削除・GCを行わない。

## 失敗時の動作

- 鍵が使えない、入力不正、復号失敗、受信者検査失敗: 反映前に停止。
- 通常の書き込み失敗・SIGTERM・SIGHUP・Ctrl-C: 元のルールと暗号文へ復元。
- 電源断・SIGKILL: `.git/enroll-transaction.json` を残し、次回enrollで復元してから処理を再開。
- 復元自体が失敗: ジャーナルを残して停止。これを削除して無理に再開しない。
- 登録済みかつ受信者検査成功: 再暗号化せず終了。
- 登録済みだが暗号文が古い: 再暗号化して修復。
- 本番ビルド・切替の失敗: 検証済みの登録結果は保持して再試行。

agenixの一時平文は `/dev/shm` を使い、終了時に削除する。
tmpfsは暗号化されていないswapへ退避される可能性がある。平文の恒久保存先としては使用しない。

## 実機作業までの保留事項

- Yuiの実ホスト鍵による2ファイルの復号試験（root権限が必要）。
- Yukinoのディスク型番・by-id・パーティション容量の実測。
- Yukinoの必要データのバックアップと復元確認。
- 両ホストの本番評価・ビルドとYukino用Installerの構成・ビルド。
- 実機SSD初期化の直前には対象SSDを再確認する。現在の作業は初期化の実行許可を意味しない。

VM試験は省略と記録する。疎ファイル上のGPT検査は起動・マウントの代替試験とは扱わない。
