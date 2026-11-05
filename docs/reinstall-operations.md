# 再インストール操作仕様

## 構成

Installerは既存のユーザー・SSH・ロケールモジュールを相対importする。
Installerでのみ初期パスワードとSSHパスワード認証を設定し、Home Managerとagenixは導入しない。
本番では従来どおりagenixのパスワードファイルを使う。

パーティションは各ホストの `disko.nix` に直接記述する。
YukinoとYuiの両方を定義済み。本番へのDisko組み込みは未完了。

## 初期パスワード

既存lockのnixpkgsに含まれるmkpasswdを使い、端末で対話入力する。
パスワードはコマンド引数やGitへ入れず、生成したハッシュのみ追加する。

以下の取得先は現在のInstaller lockの固定先。

```sh
nix --option access-tokens '' shell github:NixOS/nixpkgs/1559d3daa3ecc813a650b79375ea61b6741b8746#mkpasswd
mkpasswd --method=yescrypt >installer/initial-password-hash
git add installer/initial-password-hash
```

今回すでに生成した専用パスワードはYuiの
`~/.local/state/dotfiles-installer/initial-password` にある。
平文をログやチャットに貼らない。本番パスワードとは別にする。

## Secretsの移行

安全なYuiのホスト鍵で移行する。旧Yukino鍵と `mkiin@recovery` は移行後の受信者から除外する。
不要なNixアクセストークンは移行せず、パスワードとrcloneの2ファイルを対象とする。
元のnix-secretsは復旧用に保持する。専用回復鍵は後日対応とし、Yukino復旧までYuiの鍵を保持する。

復号確認には標準のageを直接使う。以下のコマンドは値を表示・保存せず、終了コード0なら成功。

```sh
nix --option access-tokens '' shell github:NixOS/nixpkgs/1559d3daa3ecc813a650b79375ea61b6741b8746#age
sudo "$(command -v age)" -d -i /etc/ssh/ssh_host_ed25519_key ../nix-secrets/user-password.age >/dev/null
sudo "$(command -v age)" -d -i /etc/ssh/ssh_host_ed25519_key ../nix-secrets/rclone-r2.conf.age >/dev/null
```

新しいYukinoのホスト公開鍵はSSHでYuiへ取得し、指紋をYukinoのローカル画面と照合する。
Yui上で通常のagenixを使い、一時作業コピー内のルールに新しい公開鍵を登録して再暗号化する。
秘密鍵は転送しない。公開鍵と暗号化済みファイルのみやり取りする。

全ファイルの復号と受信者の確認が済むまで、本番の作業ツリーへ反映しない。
途中で失敗した一時コピーは破棄し、元の暗号文からやり直す。
独自enroll・自動ロールバック処理は削除済みであり、標準ツールによる具体的な移行手順はまだ未完了。

## 実機作業の前提

Yuiでの実復号、Yukino実機でのディスク指定の照合、バックアップ・復元確認が必要。
VM試験は省略するが、成功扱いにはしない。
現時点では実機初期化・インストールへ進める状態ではない。
