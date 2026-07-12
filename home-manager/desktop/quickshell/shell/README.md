# quickshell 設定

waybar と併用する常駐デーモン。バーは持たず、通知サーバ、通知トースト、コントロールセンター、audio/bluetooth ポップアウトだけを提供する。
初期実装は Swarnim Tripathi 氏の QuickShell 設定（MIT、LICENSE 参照）を基にしており、その後の大規模リファクタで構成を作り直した。

## 構成

```
shell.qml        エントリポイント。ウィンドウの組み立てと IPC 配線のみ
config/          Config(shell.json 読込) / Appearance(寸法トークン) / Theme(意味色トークン)
services/        システム状態のシングルトン（Audio, Bluetooth, Colours, Notifs, ...）
utils/           純粋ヘルパー（Logger）
components/      汎用 UI 部品。containers/ と effects/ に用途別分類
modules/         画面単位。notifications / controlcenter / popouts
```

## 設計ルール

- 色は `Theme`、寸法・タイポ・アニメは `Appearance` だけを参照する。`Colours`（matugen プリミティブ）の直参照と生数値は禁止。
- 色の流れ: matugen が `~/.cache/quickshell/matugen-colors.json` を書き、`Colours` が FileView で読み、`Theme` が意味トークンへ割り当てる。壁紙変更時は matugen の post_hook が `qs -c shell ipc call theme reload` を呼ぶ。
- スクリーンショットと録画の実装は `hyprland/scripts/{screenshot,record}.sh` が正。`Screenshot` サービスはスクリプトを呼ぶだけ。

## IPC

| コマンド                                | 動作                                         |
| --------------------------------------- | -------------------------------------------- |
| `qs -c shell ipc call cc toggle`        | コントロールセンター開閉（Super+N / waybar） |
| `qs -c shell ipc call audio toggle`     | オーディオポップアウト（waybar）             |
| `qs -c shell ipc call bluetooth toggle` | Bluetooth ポップアウト（waybar）             |
| `qs -c shell ipc call theme reload`     | matugen 色の再読込                           |
| `qs -c shell ipc call idle toggle`      | アイドルインヒビター                         |

パネルは排他制御されており、同時に開くのは 1 つだけ。
