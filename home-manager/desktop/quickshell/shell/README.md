# quickshell 設定

waybar と併用する常駐デーモン。
バーは持たず、通知サーバ、コントロールセンター、audio と bluetooth のポップアウトを提供する。

初期実装は Swarnim Tripathi 氏の QuickShell 設定（MIT、LICENSE 参照）を基にしていたが、
2026 年 7 月に UI 層を全面的に作り直した。
現在は shadcn/ui の設計思想と Material Design 3 のトークン体系に沿っている。

## 現在の状態

**動くもの**：コントロールセンター、Bluetooth ポップアウト、Audio ポップアウト、waybar 連携（通知件数とアイドル抑制の表示）、matugen によるカラーリロード。

**スタブ**：`features/network/Network.qml`。Wi-Fi を使っていないため、CC のタイルを描くための最小限だけを返す。

## 構成

```
shell.qml            エントリ。通知サーバと IPC の配線のみ
Config.qml           shell.json 読込。最下層で何にも依存しない
theme/               Colours(matugen読込) / Theme(意味色) / Appearance(寸法・タイポ・動き)
ui/                  ヘッドレス部品。どの画面にも依存しない
features/            機能単位。状態(サービス)と、その機能固有の UI を同居させる
windows/             PanelWindow。features を並べる器
utils/               Logger
```

依存は `windows → features → ui → theme → Config` の一方向に流れる。
features どうしは参照しない。

## 設計ルール

作り直しの過程で決めた規約を列挙する。
いずれも破ると同じ問題が再発するため、変更するときは理由を添えて記録する。

### 色

**matugen の実トークンだけを使う**：`Theme` は matugen が出力する M3 トークンから意味色を導出する。
`Qt.rgba` と alpha 合成は禁止で、透過が要る箇所は要素側の `opacity` または `MultiEffect.shadowOpacity` で表す。
色に alpha を埋め込むと、面の上に別の面を重ねたとき破綻する。

**文字色は 2 段**：`Theme.text`（`onSurface`）と `Theme.textVariant`（`onSurfaceVariant`）だけ。
3 段目を作らない。

**`on*` プロパティは `_on*` で持つ**：QML は `on` で始まるプロパティ名をシグナルハンドラと解釈するため、
`readonly property color onSurface` は宣言できても読むと黒が返る。
`Colours` と `Theme` では `_onSurface` のように接頭辞を付けて回避している。

### 寸法

**中身の量で変わるものは導出、変わらないものはトークン**：
ボタンの高さは文字数で変わるべきではないからトークン、幅は変わるべきだから導出。
`Item` の高さは 1 行か 2 行かで変わるから導出。

**トークンは `Appearance` に置く**：数値を直書きしてよいのは、後で調整する余地がないもの（1px の区切り線など）だけ。

### 状態

**状態は features が持つ**：UI は状態を保持しない。
`Switch` の `checked` は外から与えられた値を描くだけで、切り替えは `clicked` を受けた側が行う。

**値の出どころが 1 つになるようにする**：BlueZ や Pipewire が値を持つなら、
features はそれを参照するだけで、自前のフラグを作らない。

**ポーリングを避ける**：D-Bus のシグナル、`FileView` の `watchChanges`、Pipewire のバインディングで
変化を受け取る。常時動くタイマーは通知の経過時間表示（1 分ごと、プロセス起動なし）だけ。

### 部品

**使う場所が 1 つなら部品にしない**：使う側に直接書く。
作り直しの過程で `IconText`、`Label`、`Divider`、`Toggle` を作っては消した。

**置く側の都合を部品に焼き込まない**：`Layout.fillWidth` のようなレイアウトへの参加、
折りたたむかどうか、押したときにパネルを閉じるかは、置く側が決める。

**`ui/` は抽象、`windows/` は具体**：`ui/` の部品は用途を名前に持たない（`Button`、`Item`）。
`windows/` の部品はドメインを名前に持つ（`QuickActions`）。

### 状態表現

hover と pressed は面の色を差し替えず、`ui/StateLayer` を重ねて表す。
重ねる色はその要素の面に対応する on-color で、強度は `Theme.stateHovered`（8%）と `Theme.statePressed`（12%）。
M3 の規定値を使っている。

面の色を差し替える方式だと、surface の階調が 5 段しかないため、
入れ子が深くなったときに親と子が同じ色になる。

### 動き

色の補間アニメーションは持たない。
`ui/Anim` が duration と easing の組を提供し、`Behavior` の中で使う。

```qml
Behavior on opacity {
    Anim { speed: "fast" }
}
```

## 色の流れ

```
壁紙変更
  → matugen が ~/.cache/quickshell/matugen-colors.json を書く
  → post_hook が qs -c shell ipc call theme reload を呼ぶ
  → Colours が読み直す
  → Theme が意味トークンへ割り当てる
  → 各コンポーネントが Theme を参照する
```

`Colours` は `FileView` の `watchChanges` でも監視しているが、
matugen が一時ファイルを rename する書き方をするため監視が外れることがある。
post_hook による明示リロードはその保険。

matugen のテンプレートは `home-manager/desktop/matugen/templates/quickshell-colors.json` にある。
`onSecondaryContainer` などコンテナ色の上に載せる文字色は、そこに追記して出力させている。

## IPC

| コマンド                                | 動作                             |
| --------------------------------------- | -------------------------------- |
| `qs -c shell ipc call cc toggle`        | コントロールセンター             |
| `qs -c shell ipc call audio toggle`     | オーディオポップアウト（waybar） |
| `qs -c shell ipc call bluetooth toggle` | Bluetooth ポップアウト（waybar） |
| `qs -c shell ipc call cc status`        | waybar の通知アイコン用 JSON     |
| `qs -c shell ipc call idle status`      | waybar のアイドル抑制表示用 JSON |
| `qs -c shell ipc call theme reload`     | matugen 色の再読込               |

`cc toggle` は Super+N と waybar の 3 モジュールが同じコマンドを呼ぶ。
パネルは `shell.qml` の `openPanel()` が排他制御し、同時に 1 つだけ開く。
CC を閉じると `Notifs.markAllRead()` で既読になり、waybar のバッジが消える。

waybar 側の `format-icons` と CSS は `none` / `notification` / `dnd-none` / `dnd-notification` の
4 状態に整理してある。
`cc status` が返す `alt` と `class` はこの 4 値と一致させる。

## 動作確認の手順

`xdg.configFile` は作業ツリーへの symlink なので、`nix run .#switch` は要らない。

```bash
systemctl --user restart quickshell
journalctl --user -u quickshell -n 10 --no-pager | grep -iE "ERROR|Loaded"
qs -c shell ipc call bluetooth toggle
```

`Configuration Loaded` が出ればエントリは読めている。
描画時のエラーは開いた直後のログに出る。

Nix のビルドとフォーマットは別途確認する。

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

## コントロールセンター

`windows/controlcenter/` に CC 専用の部品を置く。

```
ControlCenterWindow (PopupCard 420px)
├── ヘッダー … 時刻・日付（SystemClock、開いている間だけ動く）+ 電源ボタン(wlogout)
├── QuickActions … 6 タイル 2 列 3 行
├── Divider
├── 音量スライダー + アプリ別音量の展開トグル（Audio.streams）
├── MediaCard … プレイヤーが居るときだけ表示
└── NotificationList … 内部スクロール、空のときは Empty
```

6 タイルは Wi-Fi、Bluetooth、Do Not Disturb、Caffeine、Screenshot、Record Screen。
Wi-Fi は `features/network` がスタブのため常に Off 表示。

音量スライダーはドラッグで宣言時の束縛が切れるため、
Pipewire 側の変化は `Binding on value`（`when: !pressed`）で書き戻している。

## 次にやること

- 通知トースト。`windows/NotificationToasts.qml` を削除したまま。`Notifs` に `hasAnimated` を残してある
- `features/network` のスタブを実装に置き換える。`nmcli monitor` で変化を検知する方針
