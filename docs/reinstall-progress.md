# NixOS再インストール基盤の実装状況

この変更はレビュー用の途中実装。WBSは未完了で、実機再インストールには使用しない。

## 採用する復旧方式

- 安全なYuiのホスト鍵を使ってSecretsを移行する。
- 移行後は、漏洩した可能性がある旧Yukino鍵と `mkiin@recovery` を受信者から除外する。
- 不要になった `nix-access-tokens` は移行しない。対象はパスワードとrcloneの2ファイル。
- 専用オフライン回復鍵は後日対応。Yukinoの復旧完了までYuiのOSと鍵を保持する。
- VM試験はユーザー判断で省略。成功扱いにはしない。

## 実装済みの範囲

- Yui用の独立Installer Flake・lock、最小ユーザー、OpenSSH、NetworkManager。
- 初期パスワードを対話入力またはランダム生成し、ハッシュのみGitへ追加する処理。
  今回生成した平文はYuiの `~/.local/state/dotfiles-installer/initial-password` に600で保存。
- Yuiの実測値に基づくDisko定義と共通ext4レイアウト。まだ本番へ組み込んでいない。
- Yuiのみへの初期Secrets移行、新ホスト登録、同名ホストの鍵交換、受信者検査、
  再暗号化前後の平文一致検証、排他制御、ジャーナルによるロールバック。
- 本番のagenix定義とNix設定からNixアクセストークン参照を除去。
- CIの非公開input用SSH鍵受け渡しを撤去し、enroll試験とInstallerビルドを追加。

## 検証済みの範囲

以下はいずれも終了コード0。実機へのswitch・ディスク初期化・再起動は未実施。

| 検証 | 結果・限界 |
| --- | --- |
| 独立Installerのlock生成・Diskoスクリプト評価 | 非公開inputなし。Diskoは未実行 |
| Yui Installerのtoplevelビルド（max-jobs 1、cores 1） | `/nix/store/rnd2apmvc3sa8svgsxjds9m39vyd4qfm-nixos-system-oregairu-yui-26.11.20260730.1559d3d` を生成。起動未検証 |
| `python3 -B -m unittest discover -s tests -p 'test_*.py' -v` | 8件成功。実agenixと使い捨て鍵で移行・旧鍵排除・新ホスト復号・再実行・暗号文修復・鍵交換・ロールバックを検証 |
| `bash tests/check-installer-password.sh` | ハッシュ一致、保存権限、Gitへの平文混入なし、再実行での置換防止を確認 |
| Yuiと同容量の疎ファイル上でのsgdisk作成・整合性検査 | GPT整合性成功。マウント・起動の代替ではない |
| 両本番ホストのagenix属性名とYuiのNix追加設定の評価 | 対象は2ファイル、トークンincludeなし。mysecretsを既存ローカルコピーへ一時overrideして検査 |

検証用ツール環境と実行コマンドは [操作仕様](reinstall-operations.md) に記載。
単純な復号確認は標準のageを直接使う。専用check-recoveryスクリプトは削除した。

## マージ・実機作業までに必要なもの

1. Yuiの実ホスト鍵による2ファイルの復号確認。非対話sudoが不可のため端末での実行が必要。
2. 実Secretsの再暗号化・公開配置、mysecretsの引数・input・lockノードの除去。
3. Yukinoのディスクby-id・容量・構成の実測とDisko定義、Installerへの追加。
4. 両ホストの旧UUID定義整理と本番へのDisko組み込み、両本番ホストの認証なしでのビルド。
5. 公開内容の監査、実際のGitHub Actions実行結果。
6. Yukinoのバックアップ・復元確認、対象SSD確認、実機での初期導入から本番復帰までの検証。
7. 新ホスト鍵を含む暗号文のGitHub反映とクリーンclone検証。

**CIはまだ完成していない。** SSH鍵の受け渡しを撤去した一方、本番のmysecrets inputが残っている。
この途中状態をマージすると既存の本番チェック・ビルドが非公開input取得で失敗し得る。
レビュー用ドラフトとして扱い、Secrets移行と全体検証が済むまでマージしない。
