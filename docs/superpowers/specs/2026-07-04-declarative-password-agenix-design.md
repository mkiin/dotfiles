# root と user パスワードの宣言的統一管理（agenix）

## 背景と目的

クリーンインストールのたびに `passwd` でパスワードを手で設定するのは手間で、マシン間でばらつく。
root と user のパスワードを宣言的に固定し、再インストールでも常に同じにしたい。

この設計は、root と mkiin に**同一のパスワード**を与え、その値を agenix で暗号化して宣言的に管理する。
`mutableUsers = false` により、宣言した値だけが唯一の真実になる。

## スコープ

- root と mkiin に同一パスワードを設定する。
- パスワードハッシュを agenix で暗号化し `nixos/core/secrets/` に置く。
- `mutableUsers = false` にする。
- ユーザー名の不一致を build 時に弾くアサーションを入れる。

age 鍵の生成や rbw による鍵の保管と復元は既存（別 spec）で完了しているため対象外とする。

## 前提となる現状

`nixos/core/users/default.nix` は mkiin を定義するだけでパスワードを設定していない。
`mutableUsers` は未設定なのでデフォルトの true で、現状は `passwd` による手動管理になっている。

agenix は `nixos/core/secrets/default.nix` で配線済みで、R2 認証を `age.secrets."rclone-r2.conf"` として復号している。
`age.identityPaths` は現在 `/home/mkiin/.config/agenix/key.txt` を**ハードコード**している。

`username` は `flake.nix` の `makeNixosConfig { username = "mkiin"; }` が唯一の定義元で、specialArgs 経由で各モジュールへ渡る。

## 設計

### パスワードの秘密

`mkpasswd -m yescrypt` で生成した 1 つの yescrypt ハッシュ（`$y$...`）を、mkiin の age 公開鍵で暗号化して `nixos/core/secrets/password.age` に置く。
root と mkiin は同一パスワードのため、暗号化ファイルは 1 つでよい。

ルールファイル `nixos/core/secrets/secrets.nix` に登録を足す。

```nix
"password.age".publicKeys = [ mkiin ];
```

### agenix の配線

`nixos/core/secrets/default.nix` に秘密を追加する。
復号先はデフォルトの `/run/agenix/password`、owner は root、mode は 0400 とする。
NixOS が `/etc/shadow` を生成する際に root が読むため、owner の上書きは不要である。

```nix
age.secrets."password".file = ./password.age;
```

あわせて identityPaths のハードコードを解消し、`username` から導出する。

```nix
age.identityPaths = [ "/home/${username}/.config/agenix/key.txt" ];
```

この変更で secrets モジュールは `username` を引数に取る。

### パスワードの適用

`nixos/core/users/default.nix` で `mutableUsers` を false にし、root と mkiin の `hashedPasswordFile` を同じ復号先へ向ける。
モジュールは `config` を引数に取り、`config.age.secrets."password".path` を参照する。

```nix
users.mutableUsers = false;
users.users.${username}.hashedPasswordFile = config.age.secrets."password".path;
users.users.root.hashedPasswordFile = config.age.secrets."password".path;
```

**`mutableUsers = false`** は、`/etc/passwd` と `/etc/shadow` を NixOS が完全管理する設定である。
`passwd` などの手動変更は rebuild で消え、宣言した値だけが残る。
クリーンインストールで必ず宣言どおりのパスワードになる代わりに、変更は秘密を再暗号化して rebuild する運用になる。

### ユーザー名の完全一致ガード

秘密と復号鍵のパスは mkiin 用にプロビジョニングされている。
`username` が想定値とずれたまま build や switch をすると、鍵のパスが食い違って復号に失敗し、`mutableUsers = false` の下ではパスワード未設定でロックアウトする。
これを build 時に明確なエラーで弾く。

```nix
assertions = [
  {
    assertion = username == "mkiin";
    message = "secrets と鍵パスは mkiin 用にプロビジョニング済み。別ユーザーで使うには age 鍵とパスワードの再暗号化が必要。username を mkiin に合わせるか再プロビジョニングせよ。";
  }
];
```

これにより「インストール時のユーザー名 ≠ dotfiles のユーザー名」は switch が通らず、理由が表示される。

## ハッシュ生成（手動・一度）

```bash
mkpasswd -m yescrypt

cd nixos/core/secrets
EDITOR=nvim nix run github:ryantm/agenix -- -e password.age -i ~/.config/agenix/key.txt
```

エディタに `$y$...` ハッシュを 1 行貼って保存する。

## フレッシュインストールの流れ

1. インストーラでユーザー mkiin を作成し `/home/mkiin` まで用意する。
2. リポジトリを clone し、age 秘密鍵を `/home/mkiin/.config/agenix/key.txt` に置く（rbw の restore か手動）。
3. `nixos-rebuild switch` する。agenix が password.age を復号し、root と mkiin に同一パスワードが設定される。

agenix の復号は活性化のうち users より前に走るため、鍵さえ在れば switch 内でパスワードが正しく設定される。

## ロックアウト対策

- 最初にパスワードを有効化する switch の前に、age 鍵が復号可能な場所に在ることを確認する。
- switch 実行時は別 TTY にログインセッションを 1 つ残し、`su - mkiin` と `sudo` が新パスワードで通ることを確かめてから抜ける。
- 秘密が復号できないと no password になりロックアウトするため、鍵の不在や公開鍵の不一致がないか build 前に確認する。

## 検証

- `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。
- switch 後に `sudo -k` してから `sudo true` が新パスワードを受け付ける。
- `su - mkiin` が通る。root ログインも同一パスワードで通る。
- `username` を別値にして build するとアサーションで失敗することを確認する。

## 対象外

- root をロックする運用（今回は root と user 同一パスワードを採る）。
- age 鍵の生成と rbw による保管/復元（既存 spec で完了）。
- パスワードのローテーション自動化。必要になれば別途。
