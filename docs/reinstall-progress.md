# NixOS再インストール基盤の実装状況

レビュー用の途中実装。WBSは未完了であり、実機再インストールにはまだ使用しない。

## 現在の範囲

- Yukino・Yui用の独立Installerとlock。URLはnixos-unstable、固定はlockで管理する。
- Installerから本番と共通のユーザー・SSH・ロケールモジュールをimportする。
  Installerだけに必要な初期認証とネットワーク設定はconfiguration.nixに置く。
- Yuiの実測値に基づくパーティション定義をhosts/oregairu-yui/disko.nixへ直接記述する。
- 提示画像のディスク指定・容量に基づきhosts/oregairu-yukino/disko.nixを追加。
  ESPは1G、rootは940603124Kのext4、swapは35108800K。
  実機初期化前のby-idとディスク構成の照合はまだ必要。
- WBS C-03・C-04: 両本番ホストにDiskoモジュールと各ホストのdisko.nixを登録し、
  hardware-configuration.nixから旧UUIDのfileSystems・swapDevicesを削除。
  本番のDiskoはInstallerと同じv1.13.0を独立lockで固定する。
- 不要なNixアクセストークンのagenix定義・利用設定を削除する。
- CIの非公開input用SSH鍵受け渡しを削除する。

ルートのscripts/・tests/、installer/modules/、lib/disko-ext4.nixは全廃。
enroll・初期パスワード生成の独自スクリプトと専用CIジョブも削除した。
以前の独自処理に対する試験結果は、現在の実装の検証結果として扱わない。

## 今回の検証

- Disko組み込み後の両本番toplevel実ビルド（max-jobs 1、cores 1）: 終了0。
  Yukino: `/nix/store/szq8assbkd926r3vl2l8ij0262jdngb0-nixos-system-nixos-26.11.20261103.1d06008`。
  Yui: `/nix/store/a81f0h9h58c42qk5d9rbvnbpavqkz0rq-nixos-system-oregairu-yui-26.11.20261103.1d06008`。
  mysecretsは既存ローカルコピーへ一時overrideして検証。公開Secrets移行済みとは扱わない。
- 本番とInstallerの両ホストについて、ディスクby-id・fileSystems・swapDevicesを評価して比較: 終了0。
  両段階のマウント先・形式・オプション・デバイス参照が完全一致。
- 両本番ホストのenvironment.etc.fstab.source実ビルド: 終了0。
  `/nix/store/gz5gylnsf5gqraihn78frg85qssk16am-etc-fstab` を生成し、
  root・ESP・swapがすべてDiskoのby-partlabel参照であることを確認。
  検査時のみmysecretsを既存ローカルコピーへoverrideし、lockへは保存していない。
- 画像の値を反映後、Yukino・Yui Installerのtoplevel実ビルド: 両方とも終了0。
  Yukinoは `/nix/store/v391l8s3pis77id05wphg08qnqrx0kcb-nixos-system-oregairu-yukino-26.11.20260730.1559d3d`。
  YukinoのDiskoスクリプトも評価済み。ディスク初期化・実機適用は実施していない。
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
4. Yukino実機でのディスクby-id・構成の最終照合。
5. Secrets移行後の認証なしでの両本番ビルド。
6. 公開差分・履歴の監査とGitHub Actionsの結果確認。
7. バックアップ・復元確認後のYukino実機作業、再起動・ログイン・Secrets・デスクトップの検証。
8. 更新した暗号文のGitHub反映とクリーンclone検証。

**マージ不可のドラフト。** CIのSSH鍵受け渡しを削除した一方、本番のmysecretsが残っている。
非公開inputの取得が必要な環境では本番チェック・ビルドが失敗し得る。
VM試験と専用オフライン回復鍵は後日対応・省略として扱い、完了扱いにはしない。
