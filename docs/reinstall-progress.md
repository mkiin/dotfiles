# NixOS再インストール基盤の実装状況

レビュー用の途中実装。WBSは未完了であり、実機再インストールにはまだ使用しない。

## 現在の範囲

- Yui用の独立Installerとlock。URLはnixos-unstable、固定はlockで管理する。
- Installerから本番と共通のユーザー・SSH・ロケールモジュールをimportする。
  Installerだけに必要な初期認証とネットワーク設定はconfiguration.nixに置く。
- Yuiの実測値に基づくパーティション定義をhosts/oregairu-yui/disko.nixへ直接記述する。
- 不要なNixアクセストークンのagenix定義・利用設定を削除する。
- CIの非公開input用SSH鍵受け渡しを削除する。

ルートのscripts/・tests/、installer/modules/、lib/disko-ext4.nixは全廃。
enroll・初期パスワード生成の独自スクリプトと専用CIジョブも削除した。
以前の独自処理に対する試験結果は、現在の実装の検証結果として扱わない。

## 今回の検証

- 共通モジュール再利用後のYui Installer実ビルド: 終了0。
  `/nix/store/dn17b2k9jbb0lr6s5yzv6lws0q88apvs-nixos-system-oregairu-yui-26.11.20260730.1559d3d` を生成。
  実機起動・ログインは未検証。
- 本番Yui・Yukinoの認証設定評価: 終了0。
  両方ともパスワードは `/run/agenix/user-password`、SSHパスワード認証はfalse。
  非公開inputは既存ローカルコピーへ一時overrideし、lockは変更していない。
- Installerのmetadata評価: 終了0。URLはnixos-unstable、lockの固定revは従来のまま。
- ci.yamlのactionlint: 終了0。追加のreinstallジョブなし。

## 未完了

1. Yuiの実ホスト鍵による2ファイルの復号確認。
2. 標準agenixによる安全な再暗号化・失敗時の復旧手順と実Secretsの公開移行。
3. 本番のmysecrets input・引数・lockノードの除去。
4. Yukinoのディスク実測、Disko定義、Installerへの追加。
5. 両本番ホストへのDisko組み込みと旧UUID整理、認証なしでのビルド。
6. 公開差分・履歴の監査とGitHub Actionsの結果確認。
7. バックアップ・復元確認後のYukino実機作業、再起動・ログイン・Secrets・デスクトップの検証。
8. 更新した暗号文のGitHub反映とクリーンclone検証。

**マージ不可のドラフト。** CIのSSH鍵受け渡しを削除した一方、本番のmysecretsが残っている。
非公開inputの取得が必要な環境では本番チェック・ビルドが失敗し得る。
VM試験と専用オフライン回復鍵は後日対応・省略として扱い、完了扱いにはしない。
