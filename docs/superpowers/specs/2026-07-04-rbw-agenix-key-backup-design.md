# rbw による agenix マスター鍵の CLI 保管と復元

## 背景と目的

agenix の復号鍵（`~/.config/agenix/key.txt`）は、自動化できない唯一の起点である。
この鍵を失うと、リポジトリに暗号化して置いた秘密（R2 認証やパスワード）を一切復号できなくなる。
一方で、鍵を Bitwarden の GUI にコピー貼り付けで保管し、フレッシュインストールで手作業で戻す運用は手間が大きい。

この設計は、鍵の保管と復元を CLI 一貫で行えるようにする。
GUI 操作を排し、フレッシュインストール時の鍵配置を `nix run` のコマンドに閉じ込める。

## スコープ

対象は次の 2 つだけとする。

- rbw を宣言的に導入する。
- age マスター鍵を Bitwarden へ CLI で保管し、CLI で復元する。

`.env` や direnv による環境変数管理は対象外とする。
rbw を導入すれば後から独立に足せるため、混ぜない。
ユーザーとルートのパスワードの宣言的管理も対象外とする。
この鍵運用が固まった後、同じ agenix 基盤に乗せる別の spec で扱う。

## 前提となる現状

`~/.config/agenix/key.txt` は生成済みで、公開鍵は `secrets/default.nix` に登録済みである。
NixOS では `age.identityPaths = [ "/home/mkiin/.config/agenix/key.txt" ]` がこの鍵を復号に使う。
`home-manager/cli/` は 1 機能 1 ディレクトリ構成で、pinentry と gnupg と direnv はまだ導入されていない。
flake の `apps.${system}` は `pkgs.writeShellScript` で `build` や `switch` を定義しており、同じ形で app を足せる。

## 設計

### rbw の宣言的導入

`home-manager/cli/rbw/default.nix` を新設し、home-manager の **`programs.rbw`** モジュールで設定する。
`programs.rbw.enable` はパッケージ導入を含む正しい設定機構であり、集約 `packages.nix` への直書きには当たらない。

```nix
{ pkgs, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "blckcaties@gmail.com";
      pinentry = pkgs.pinentry-curses;
    };
  };
}
```

pinentry は端末内で解錠が完結する `pinentry-curses` を採る。
本設計の保管と復元はすべて端末から `nix run` で起動するため、GUI ポップアップは要らない。
将来 GUI 解錠が必要になれば `pinentry-gnome3` に差し替えられる。

`home-manager/cli/default.nix` の imports に `./rbw` を足す。

### 保管する内容

Bitwarden に保管するのは `key.txt` のうち **`AGE-SECRET-KEY-` で始まる 1 行だけ**とする。
先頭のコメント行（生成時刻と公開鍵）は復号に不要で、公開鍵は `secrets/default.nix` に既にある。
rbw のエントリ名は `agenix-age-key` とする。

rbw の `add` は「1 行目をパスワード、残りをノート」として保存するため、秘密鍵 1 行をパスワード欄に入れる形になる。
これにより復元は `rbw get agenix-age-key` の標準出力をそのままファイルへ書けばよい。

### 保管フロー

flake app `nix run .#backup-agenix-key` として実装する。
現マシンで rbw が unlock 済みであることを前提とする。

1. `~/.config/agenix/key.txt` が存在しなければエラーで止める。
2. `AGE-SECRET-KEY-` 行を一時ファイルへ抽出する。
3. rbw が locked なら unlock を促して止める。
4. エントリ `agenix-age-key` が既にあれば `rbw edit` で更新し、無ければ `EDITOR="cp <一時ファイル>" rbw add agenix-age-key` で作成する。既存時に `add` すると重複エントリになるため分岐する。
5. 一時ファイルを削除する。

rbw が editor に渡す一時ファイルへ、`cp` を editor に見せかけて内容を流し込む。
これにより GUI もキーボード入力も介さずに保管できる。

### 復元フロー

flake app `nix run .#restore-agenix-key` として実装する。
フレッシュインストールで、home-manager 適用前かつ最初の switch より前に単独で走らせる。

1. `rbw config set email blckcaties@gmail.com` で email を設定する。email は公開情報のため app に定数で埋める。
2. 既に unlock 済みなら login と unlock を飛ばす。そうでなければ `rbw login`（マスターパスワードを手入力）に続けて `rbw unlock` する。
3. `~/.config/agenix/key.txt` が既に存在する場合は上書きせず警告して止める。
4. `rbw get agenix-age-key` の出力を `~/.config/agenix/key.txt` へ書き、`chmod 600` する。

マスターパスワードの手入力だけが唯一の手作業であり、これは鶏卵を断ち切る起点として意図的に自動化しない。

### 通常運用

保管と復元以外の日常操作に rbw は登場しない。
`nix run .#switch` のたびに agenix が `key.txt` を読んで復号するだけで、Bitwarden も rbw も経由しない。

## フレッシュインストールの流れ

1. リポジトリを clone する。
2. `nix run .#restore-agenix-key` を実行する。login と unlock を経て `key.txt` が配置される。
3. `nix run .#switch` を実行する。agenix が復号し、各サブプロジェクトの秘密が使えるようになる。
4. 壁紙などの復元コマンドを実行する。

## エラー処理

- 保管で `key.txt` が無い場合はエラーで止める。誤って空の鍵を保管しないため。
- 保管でエントリが既にある場合は `edit` で更新する。重複エントリを作らないため。
- 復元で `key.txt` が既にある場合は上書きせず警告する。既存の正しい鍵を壊さないため。
- 復元で既に unlock 済みなら login を省く。二重ログインの手間を避けるため。

## 検証

- `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。
- 保管後に `rbw get agenix-age-key` が `AGE-SECRET-KEY-` 行を返すことを確認する。
- ラウンドトリップを確認する。復元を一時パスへ向けて実行し、その内容が現在の `key.txt` の秘密鍵行と一致することを確かめる。本物の `key.txt` は消さない。

## 対象外

- direnv や mise による環境変数管理。rbw 導入後に独立して足せる。
- ユーザーとルートのパスワードの宣言的管理。同じ agenix 基盤に乗る次の spec で扱う。
- 自己ホスト Bitwarden（Vaultwarden）対応。既定の bitwarden.com を前提とし、必要になれば `base_url` を足す。
