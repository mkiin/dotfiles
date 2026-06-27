# Zen Browser ブックマークバックアップ

OS 再インストールに備えた Zen Browser のブックマーク退避。

- `bookmarks.html` — Netscape 形式。Zen / Firefox / Chrome 等にそのままインポート可能
- `bookmarks.json` — フォルダ階層を保持した素の JSON（参照・再加工用）

ブックマークのみ。履歴・Cookie・パスワード等の機微情報は含めていない。

## 復元手順（Zen / Firefox）

1. メニュー → ブックマーク → ブックマークを管理（ライブラリ）
2. インポートとバックアップ → HTML からインポート
3. `bookmarks.html` を選択

## 再エクスポート

`places.sqlite` から再生成する場合は scratchpad の `export_bookmarks.py` を参照。
