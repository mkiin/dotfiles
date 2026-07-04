# 壁紙の R2 バックアップと初回ブート成立

## 背景と目的

壁紙のバックアップを失い、いま `images/wallpaper/2026799-final.png` の 1 枚しか手元にない。
再発を防ぎ、今後増える壁紙を安全に保管したい。
同時に、フレッシュインストール直後に壁紙も色ファイルも無い状態で waybar が起動できない問題を解消したい。

この設計は次の三つを扱う。

- **R2 バックアップ**：壁紙を Cloudflare R2 に保管し、追加した瞬間に自動退避する。
- **R2 復元**：フレッシュインストール時に R2 から壁紙を取り戻す。
- **フォールバック色**：壁紙適用前でも waybar と wlogout が起動できるよう、初回用の色ファイルを用意する。

## 前提となる現状

pyprland の `wallpapers` プラグインは、nix store ではなく実クローンの作業ディレクトリ `${dotfilesDir}/images/wallpaper`（`~/ghq/github.com/mkiin/dotfiles/images/wallpaper`）を直接読む。
したがってフレッシュクローンでこのディレクトリが空だと、`awww img` に渡す画像が無く壁紙が出ない。

waybar の `style.css` は `colors.css`（matugen 生成）と `colors-waybar.css`（wallust 生成）を `@import` する。
どちらも壁紙適用時に初めて生成される runtime ファイルで、初回ブート時には存在しない。
このため waybar と、`colors-waybar.css` を共有する wlogout が起動できない。
hyprlock は静的に home-manager 管理される `lock-colors.conf` を読むため影響を受けない。
hyprland の `colors.lua` を source する箇所は無く、quickshell は `onLoadFailed` で欠損を許容するため、いずれも初回ブートを妨げない。

`agenix` は flake input に含まれるが、どのモジュールにも配線されていない。
このマシンには SSH host key が無い。

## 保管方針の決定

壁紙のバイナリは git に載せない。
git はコミットごとに blob 全体を履歴へ永久保持し、後から `git rm` しても `.git` は縮まない。
dotfiles はフレッシュインストールの度に clone するため、履歴に積んだ壁紙は全バージョンが毎回のダウンロード対象になる。
壁紙の store は R2 が担い、git には小さなテキストであるフォールバック色だけを置く。

転送ツールは **rclone** を使い、R2 へは S3 互換バックエンドで接続する。
壁紙は一度追加すれば内容が変わらない不変メディアであり、必要なのは世代管理ではなく「一度上げた壁紙を失わないこと」である。
そこで保持モデルは **アーカイブ方式**を採り、`rclone copy`（追加のみ、削除を伝播しない）で退避する[^copy]。
バックアップの起動は **on-change 方式**とし、`images/wallpaper` の変化を systemd path unit で検知して即座に退避する。

restic のようなスナップショット型は、増分と差分の世代チェーンや point-in-time 復元を提供するが、内容の変わらない壁紙には過剰なため採らない。

[^copy]: `rclone sync` は宛先を元と一致させるため、ローカルの誤削除が R2 へ伝播して壁紙を失う。`rclone copy` は宛先の余分なオブジェクトを消さないため、ローカルから消しても R2 側は残る。

## 認証情報の管理

R2 の S3 API トークン（access key と secret）を **agenix** で暗号化して repo にコミットし、NixOS 側で復号して rclone に渡す。

暗号化する内容は、鍵を含んだ完全な rclone 設定ファイル一式とする。

```ini
[r2]
type = s3
provider = Cloudflare
access_key_id = <ACCESS_KEY>
secret_access_key = <SECRET_KEY>
endpoint = https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

`type` や `endpoint` のような非機密部分も暗号化 blob に含めるが、内容は小さく静的なので repo で差分を見られない不利益は許容する。
これにより rclone は復号済みファイルを `--config` で参照するだけでよく、環境変数への鍵の展開が要らない。

復号鍵は **個人の age 鍵をマスター**にする。
`age-keygen` で鍵対を一度だけ生成し、秘密鍵をマシン上の既知パスに置き、公開鍵を `secrets/secrets.nix` に登録する。
秘密鍵はパスワードマネージャ等へオフラインで手動退避する。
この方式は SSH host key を必要としないため、host key が無いという現状の制約を回避できる。
秘密鍵の起点は自動化できないため、フレッシュインストールでは秘密鍵の手動配置が復元前の必須手順になる。

agenix は NixOS モジュール（`age.secrets`）で配線し、復号先を `/run/agenix/rclone-r2.conf`、owner を `mkiin`、mode を `0400` に設定してユーザーの rclone サービスから読めるようにする。
rclone を呼ぶ全箇所はこの復号先を `--config` で参照する。
R2 のバケット名は機密ではないため、実装時に決める固定の定数として scripts と unit に直接書く。
将来のユーザーパスワードの宣言的管理も同じ secrets 基盤に載せられる。

## コンポーネント設計

### フォールバック色

現行の runtime 色ファイルは seed 壁紙 `2026799-final.png` から生成されており、これをそのままフォールバックとして採用すると初回ブートから壁紙と一致した配色になる。

`~/.config/waybar/colors.css` と `~/.config/waybar/colors-waybar.css` の現在値をスナップショットし、repo にコミットする。
配置は生成元へのコロケーションとし、`colors.css` のフォールバックは matugen ディレクトリ、`colors-waybar.css` のフォールバックは wallust ディレクトリに置く。

各ディレクトリの `default.nix` に home-manager の activation script を追加し、対象が存在しない場合だけコピーする。

```nix
home.activation.fallbackWaybarColors =
  lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/waybar/colors.css"
    [ -e "$t" ] || install -Dm644 ${./fallback/colors.css} "$t"
  '';
```

`[ -e ]` ガードにより、壁紙適用で生成済みの本物の色を上書きしない。
xdg.configFile ではなく activation script を使う理由は、xdg.configFile が nix store への read-only symlink を作り、matugen と wallust が runtime に上書きできなくなるためである。

### rclone パッケージ

`rclone` は集約点 `home-manager/desktop/packages.nix` に追加する。
機能ディレクトリの `default.nix` には systemd unit と設定のみを置き、パッケージ本体は直書きしない。

### バックアップ（on-change）

新設ディレクトリ `home-manager/desktop/wallpaper-backup/default.nix` に、systemd user の path unit と oneshot service を定義する。
path unit は `images/wallpaper` の変化を監視し、変化時に service を起動する。
service は `rclone copy` で壁紙ディレクトリを R2 のバケット直下 `wallpaper/` プレフィックスへ退避する。

```nix
systemd.user.paths.wallpaper-backup = {
  Unit.Description = "Watch wallpaper dir and trigger R2 backup";
  Path.PathModified = "${dotfilesDir}/images/wallpaper";
  Install.WantedBy = [ "default.target" ];
};

systemd.user.services.wallpaper-backup = {
  Unit.Description = "Back up wallpapers to R2 (rclone copy, additive)";
  Service = {
    Type = "oneshot";
    ExecStart = "${pkgs.rclone}/bin/rclone copy ${dotfilesDir}/images/wallpaper r2:<BUCKET>/wallpaper --config /run/agenix/rclone-r2.conf";
  };
};
```

path unit と同名の service が起動する仕組みを用いる。
oneshot service は多重起動しないため、短時間に複数ファイルを追加してもバックアップは直列で 1 回ずつ走る。

### 復元（手動）

flake app `nix run .#restore-wallpaper` として `apps.${system}` に追加する。
既存の `build` や `switch` と同じ `pkgs.writeShellScript` パターンで書く。
R2 から壁紙ディレクトリへ `rclone copy` で取り戻す。

```sh
rclone copy r2:<BUCKET>/wallpaper ${dotfilesDir}/images/wallpaper --config /run/agenix/rclone-r2.conf
```

`copy` を使うため、既存のローカル壁紙を消さずに欠けている分だけ取得する。
フレッシュインストールではディレクトリが空なので全件を取得する。
自動化ではなく手動コマンドにする理由は、復号鍵の配置とネットワークが整っていない初期段階で activation を失敗させ、switch をブロックする事故を避けるためである。

### 初期アップロード

R2 に壁紙が存在しなければ復元できないため、一度だけ現在の壁紙を R2 へ上げる必要がある。
これは対称の flake app `nix run .#backup-wallpaper` を用意し、手元の `2026799-final.png` を初回にアップロードして満たす。
on-change の自動バックアップは以後の追加分を担う。

## フレッシュインストール時の流れ

1. リポジトリを clone し、age 秘密鍵を既知パスへ手動配置する。
2. `nix run .#switch` で NixOS を反映する。ここで agenix が rclone 設定を復号し、フォールバック色が配置され、waybar と wlogout が起動する。壁紙はまだ無い。
3. `nix run .#restore-wallpaper` で R2 から壁紙を取得する。pyprland が壁紙を表示し、matugen と wallust が本物の色を再生成する。

フォールバック色が初回ブートを R2 復元から切り離すため、復元前でもデスクトップは操作できる。

## 実装フェーズ

依存関係の順に分ける。

- **フェーズ 1（フォールバック色）**：他に依存せず、初回ブートを単独で成立させる。matugen と wallust への色ファイル追加と activation。
- **フェーズ 2（agenix 基盤）**：個人 age 鍵の生成、`secrets/secrets.nix`、NixOS モジュール配線。R2 認証の前提。
- **フェーズ 3（R2 と rclone）**：rclone 設定の暗号化、backup の path unit、restore と backup の flake app。フェーズ 2 と、後述の人手手順に依存する。
- **フェーズ 4（stale 整理）**：`notify.sh` の todo 項目を削除する。post.sh は既に `notify_downstream()` にリファクタ済みで外部 notify.sh を呼んでいない。`todo.md` の初回セットアップ節を、R2 がブートストラップ必須要件でなくなった前提に更新する。

## 人手が必要な手順

自動化できず、実装者が Cloudflare とローカルで実施する。

- R2 バケットを作成し、S3 API トークン（access key と secret）を発行する。
- `age-keygen` で個人 age 鍵を生成し、秘密鍵をオフライン退避する。
- `agenix -e` で rclone 設定を暗号化して `.age` を作る。
- `nix run .#backup-wallpaper` を一度実行し、現在の壁紙を R2 へ上げる。

## 検証

- `nix run .#build` で home-manager と NixOS の評価を通す。
- `nix run .#fmt -- --fail-on-change` で整形を確認する。
- activation の冪等性を確認する。対象色ファイルが存在する状態で switch し、上書きされないことを確かめる。
- backup の path unit を確認する。`images/wallpaper` にファイルを追加し、oneshot service が起動して R2 に反映されることを確かめる。
- restore を確認する。壁紙ディレクトリを空にして flake app を実行し、R2 から取得できることを確かめる。

## 対象外

- バックアップの定期実行やコスト最適化。R2 は egress 無料で、この規模では storage と write ops の課金は誤差に近いため、on-change で足りる。
- 世代管理と point-in-time 復元。壁紙が不変メディアであるため採らない。必要が生じたら restic への置き換えを別途検討する。
- ユーザーパスワードの agenix 管理。secrets 基盤は共有できるが、本設計の対象外とする。
