# インストール

## 最初に一度だけ：Yui

リポジトリのルートで実行する。

```sh
nix run ./installer#reinstall -- --prepare ./secrets/recovery.age
```

復旧用パスフレーズを決めて入力する。USBは不要。
ログイン用パスワードのハッシュとrclone設定を、パスフレーズで暗号化して保存する。
復号できることを確認してから、`secrets/recovery.age`をcommit・pushする。
パスフレーズはGitに保存しない。忘れるとこのファイルから復旧できない。
Secretsを変更したら、新しい保存先で復旧ファイルを作り直して置き換える。

## 再インストール：ISOで起動したYukino

UEFIで起動し、ネットにつないで実行する。

```sh
nix --extra-experimental-features 'nix-command flakes' run \
  'github:mkiin/dotfiles/main?dir=installer#reinstall' -- oregairu-yukino
```

復旧用パスフレーズを入力 → SSDを選ぶ → 消去を確認 → 本番環境の導入 → 再起動。
ログイン用パスワードとrclone設定は復旧ファイルから戻す。Yuiへの接続は不要。

## 初回インストール：ISOで起動した対象PC

```sh
nix --extra-experimental-features 'nix-command flakes' run \
  'github:mkiin/dotfiles/main?dir=installer#install' -- oregairu-yukino
```

SSDを選ぶ → ログイン用パスワードとrcloneを設定 → 消去を確認 → 本番環境の導入 → 再起動。
対象はリポジトリに設定のあるホスト。Yuiには`oregairu-yui`を指定する。

## 共通

- 選んだSSDのデータはすべて消える。マウント中・swap使用中のSSDは消去しない。
- SSDのIDを調べる必要はない。選んだSSDのby-idをホストの`disko.nix`へ直接保存する。
- パーティションの構成と容量は各ホストの`disko.nix`を使う。小さいSSD向けの自動調整はしない。
- ビルドとSecretsの復号確認は、SSDを消去する前に行う。
- 新しいホスト鍵と、その鍵で開けるSecretsを保存する。
- 更新したリポジトリはインストール先の`~/ghq/github.com/mkiin/dotfiles`に保存する。GitHubへのpushは自動では行わない。
- `--dry-run`はホスト名と実行モードの確認だけを行う。ビルド・復号・ディスク操作はしない。
- 失敗後、同じSSDが`/mnt`と`/mnt/boot`にマウントされたままなら、同じコマンドに`--resume`を付ける。再フォーマットせず再試行する。
- 復元するのはOS設定と上記Secrets。個人ファイルのバックアップは別途必要。

この変更のcommit・pushと復旧ファイルの作成は、ISOで実行する前に済ませる。
実機でのインストール・起動確認は未実施。
