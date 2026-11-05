# 再インストール基盤の実装・検証状況

## 実装したもの

- `nix run ./installer#install -- HOST`。Nushellで実装し、既存のflake/writers.nixを再利用。
  flake.nixは入力・構成、apps.nixはアプリ、configuration.nixは初期OS設定を扱う。
- `--dry-run`、対象SSDの入力確認、マウント中・swap使用中の消去拒否、
  `--resume`によるマウント照合と再フォーマットなしの再試行。
- Yukino・Yuiの本番とInstallerが同じ各ホストのdisko.nixをimportする。
  旧UUIDのfileSystems・swapDevicesは両hardware-configuration.nixから削除済み。
- パスワードとrcloneの2ファイルをローカルSecretsへ移行。
  暗号化先はYuiのみ。漏洩した旧Yukino鍵・旧回復鍵・不要なNixトークンは除外した。
- 本番のmysecrets input・引数・lockノードを削除。
- 公開鍵取得、指紋照合、一時コピーでの再暗号化、両ホストでの復号確認、
  転送、本番適用、失敗時の復旧をdocs/reinstall-operations.mdに記載。

ルートscripts/・tests/、Installer専用modules/、libへのDisko切り出し、
独自enroll・パスワード生成スクリプト・追加CIジョブは作成しない。
初期パスワードの平文はYuiのGit管理外に保存し、Gitにはハッシュだけを含める。

## 検証結果

| 検証 | 結果 |
| --- | --- |
| 新暗号文2ファイルをYuiの実ホスト秘密鍵で復号 | 終了0、PASS: 2 secrets。平文は表示・保存していない |
| agenix -c | 終了0。2ファイルともYuiだけが受信者 |
| 非公開inputのoverrideなしで両本番toplevelをビルド | 終了0 |
| nix flake check --no-build | 終了0。両本番構成を評価 |
| Installerアプリのビルド・Nu構文検査 | 終了0。既存writeNuによるnu-checkを使用 |
| --help、両ホストの--dry-run | 終了0 |
| 不明なホスト・不明なオプション・非対話実行 | 非0で拒否。ディスク操作なし |
| 対話端末からYuiの使用中ディスクを選択 | 非0で拒否。sudo前に停止。ディスク操作なし |
| /mnt未マウントで--resume | 非0で拒否。ディスク操作なし |
| 本番・Installerのディスクとマウント定義の比較 | 両ホストとも完全一致 |
| 両本番のfstab実ビルド | 終了0。root・ESP・swapがDiskoのby-partlabel参照 |
| 両Installerのtoplevel実ビルド | 終了0 |
| Yukinoのバックアップ・復元確認 | ユーザーから完了報告済み |
| 公式Minimal ISOのUSB書き込み・全データ照合 | 終了0。USBを安全に取り外し済み |

本番ビルド成果物:

- Yukino: `/nix/store/xr407i79m28qpxxj2gfailzq91axhan3-nixos-system-nixos-26.11.20261103.1d06008`
- Yui: `/nix/store/4nafhbra23ryr0d6r0nilk3ryh2lp7qr-nixos-system-oregairu-yui-26.11.20261103.1d06008`

## 実機で行うもの

ISOでの対象SSD照合、実際のDisko・nixos-install、初期OSの起動・ログイン、
新Yukino鍵への再暗号化、本番切替・再起動・Secrets・ネットワーク・GPU・デスクトップ検証。
これらは未実施。VM試験はユーザー判断で省略しており、成功扱いにしない。
専用オフライン回復鍵も後日対応とし、Yuiの鍵を復旧手段として保持する。
