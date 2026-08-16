# quickshell 設定

waybar と併用する常駐デーモン。
バーは持たず、通知サーバ、コントロールセンター、audio と bluetooth のポップアウトを提供する。

初期実装は Swarnim Tripathi 氏の QuickShell 設定（MIT、LICENSE 参照）を基にしていたが、
2026 年 7 月に UI 層を全面的に作り直した。
現在は shadcn/ui の設計思想と Material Design 3 のトークン体系に沿っている。

## 現在の状態

**動くもの**：コントロールセンター、通知トースト、Bluetooth ポップアウト、Audio ポップアウト、waybar 連携（通知件数とアイドル抑制の表示）、matugen によるカラーリロード。

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

## 通知トースト

`windows/NotificationToasts.qml`。waybar 直下の右上に最大 3 件を積む。

```
Variants (model: Quickshell.screens)
└── PanelWindow … 幅 toastWidth + 影の余白、高さは中身から。exclusionMode: Ignore / keyboardFocus: None
    └── Column … 右上に寄せる
        └── Repeater (model: ScriptModel { values: Notifs.popups })
            └── カード … アクセントの棒 + summary + body(2 行まで) + 閉じるボタン
```

決めたことと理由:

**`PopupCard` を使わない**：あれは画面全面を覆って枠外クリックを拾う器で、常時出るトーストに
使うと下のウィンドウの操作を奪う。トーストは中身と同じ大きさの窓を持ち、`mask` で入力領域を
カードの矩形の和に限る。`Column` を丸ごと `mask` に渡すとカード間の隙間と影の余白まで
入力を吸うので、カード 1 枚ずつを積む。`Region.regions` は静的リストで動的に増やせないため、
スロットを `Notifs.maxPopups` と同数だけ並べ、delegate が自分を登録する。

**窓は影のぶん広い**：`MultiEffect` の影は面の外側へ描かれるので、面と同じ大きさの窓だと
レイヤーシェル面の端で切り落とされる（`PopupCard` は画面全面を覆うのでこの問題が出ない）。
窓を左と下へ `shadow.margin` だけ、右へ `edgeGap` だけ広げてカードを右上に寄せる。
上はバーに接していて、広げるとバーへ影が滲むため広げない（`offsetY` のぶん元々上側は薄い）。

**全モニタに出す**：`Quickshell.Hyprland` の `focusedMonitor` と `monitors` がこの環境では
空を返し、どのモニタを見ているかを知る手段がない（`PopupCard` のモニタ選択も同じ理由で
`Quickshell.screens[0]` に落ちている）。`Variants` で各スクリーンに 1 つずつ窓を作る。

**モデルは `ScriptModel` を通す**：JS 配列を `Repeater` に直接渡すと、再代入のたびに
全 delegate が作り直される。delegate に状態を置けなくなり、状態がモデル側へ逃げていく
（実際に出現済みフラグやフェード用 Timer が `Notif` に溜まり、モデルが theme の
アニメ時間まで知る羽目になった）。`ScriptModel` はオブジェクトの同一性で差分を取り、
既存の delegate を保つので、状態は本来の持ち主に置ける。CC の通知リストも同じ。

**消えるプロトコルは「モデルが宣告、表示が報告」**：寿命（`popupTimer`、Critical は消さない、
ホバー中は数えない）はデーモンの方針なので `Notif` が持ち、時が来たら `dismissing` を立てる
だけで動きの長さは知らない。表示側はそれを見てフェードを再生し、`finished` で
`removePopup()` を呼んで配列から抜く。全モニタが同時に報告しても `removePopup` は冪等。

**消えるときに高さを動かさない**：カード高を毎フレーム変えると `Column` から `PanelWindow` へ
伝播して、レイヤーシェルの窓リサイズと入力マスクの更新が毎フレーム走る。各カードは
`MultiEffect` の影を持つのでその再合成も重なり、目に見えて引っかかる。
繰り上がりは配列から抜けた 1 フレームで済ませる。

Critical は自動で消さない（`popupTimeout` が 0）。それ以外は通知の `expireTimeout` を尊重し、
未指定なら 5 秒。quickshell の `expireTimeout` はドキュメント上「秒」だが、実装は D-Bus の
ms を無変換で保持しているので ms のまま使う（換算すると 3 秒が 50 分になる）。閉じても履歴には残る
（`removePopup` は `popups` から外すだけで、履歴から消す `remove` とは別物。
`remove` は D-Bus 側にも `dismiss` で閉じたことを伝える）。

## 通知履歴の保持

quickshell は `closed` の後に元の `Notification` オブジェクトを破棄する。
`Notif` は生きている間は元オブジェクトに束縛で追従し（置換更新がそのまま映る）、
`closed` を拾ったら `freeze()` で束縛を代入で切って最後の値を固定する。
これをしないと、送り手が閉じた通知が 24 時間残るはずの履歴の中で空文字に化ける。
`actions` と `image` は元オブジェクトと一緒に死ぬ参照なので、固定せず空にする。

## 次にやること

- `features/network` のスタブを実装に置き換える。`nmcli monitor` で変化を検知する方針
- `Quickshell.Hyprland` が値を返さない件。直せば CC / Audio / Bluetooth のモニタ選択も正しくなる
