# quickshell リファクタ実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** quickshell 設定から死蔵コードと常時ポーリングを除去し、色のデータフローを matugen 由来トークンに一本化した上で、feature based のディレクトリ構造へ再編する。

**Architecture:** 削除を先に行って対象を減らし、次に色とトークンの単一情報源を確立し、最後にディレクトリを再編する。構造変更を最後に置くのは、削除と色修正の差分が「意味の変更」として読め、移動と混ざらないようにするため。最終構造は `windows/`（PanelWindow の器）→ `features/`（状態＋機能固有UI）→ `ui/`（ヘッドレス部品）→ `theme/`（デザイントークン）→ `config/`（ユーザー設定）の一方向依存。

**Tech Stack:** QML (Qt 6.10), Quickshell 0.3.0, Nix (home-manager), matugen

## Global Constraints

- 対象ディレクトリは `home-manager/desktop/quickshell/shell/` 配下のみ。以降パスはここからの相対で書く。
- 色は `Theme` のみ参照する。`Colours`（matugen プリミティブ）の直参照は禁止。
- 寸法・タイポ・アニメは `Appearance` のみ参照する。生数値の直書きは禁止。
- **`Qt.rgba` と alpha 合成は全面禁止。** 色は matugen の実トークンをそのまま使う。
  `Theme.withAlpha` は削除する。state layer は surface 階調（`card` / `cardHigh`）で表す。
- **透過が要る箇所は色ではなく要素側で表す。** 影は `MultiEffect.shadowOpacity`、
  覆いは `Rectangle.opacity`。色に alpha を埋め込まない。
- **文字色は 2 段のみ。** `Theme.text`（本文＝`onSurface`）と `Theme.textVariant`（副次＝`onSurfaceVariant`）。
  3 段目を作らない。
- `../` で親ディレクトリへ遡るパスは Nix 側では禁止（プロジェクト規約）。QML の相対 import はこの規約の対象外だが、階層は浅く保つ。
- コメントは「なぜ」だけを 1〜2 行。`enable = true; # 有効化` 的な逐条コメントは書かない。
- 各タスクの最後に必ずコミットする。コミットメッセージは Conventional Commits（`refactor(quickshell): ...` 等）。
- Quickshell 0.3.0 の実 API を使う。存在確認済みのモジュールは `Quickshell.Services.Pipewire`, `Quickshell.Services.Mpris`, `Quickshell.Services.Notifications`, `Quickshell.Bluetooth`, `Quickshell.Services.UPower`。

## 検証方法（全タスク共通）

QML には本リポジトリにユニットテスト基盤が無い。各タスクの検証は次の3段で行う。

```bash
# 1. 構文とフォーマット
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change

# 2. Nix ビルド（xdg.configFile の解決を含む）
nix run .#build

# 3. 実行時の QML エラー確認
systemctl --user restart quickshell
sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

手順3の期待出力は、`.qml:NN: ReferenceError` / `TypeError` / `Unable to assign` / `is not a type` を **含まない** こと。
`Logger` の `debug` / `info` 行は出てよい。

「目視確認」と書かれた箇所は、`qs -c shell ipc call cc toggle` で Control Center を開いて確認する。

---

## File Structure

### 最終構造

```
shell/
  shell.qml                     エントリ。IPC 配線とウィンドウ組み立てのみ
  config/
    Config.qml                  shell.json 読込。最下層、何にも依存しない
    qmldir
  theme/
    Colours.qml                 matugen JSON 読込（プリミティブ）
    Theme.qml                   意味色トークン
    Appearance.qml              寸法・タイポ・モーション
    qmldir
  ui/                           ヘッドレス部品。サービスを一切参照しない
    IconText.qml                アイコンフォント 1 文字（抽出元 30 箇所超）
    Label.qml                   本文テキスト。variant で font を一括決定（同 23 箇所超）
    Divider.qml                 1px の水平線
    StateLayer.qml              hover 色と押下スケールの計算（同 13 箇所超）
    IconButton.qml              円形アイコンボタン（同 8 箇所）
    TextIconButton.qml          アイコン + ラベルの横長ボタン（同 3 箇所）
    PillButton.qml              角丸いっぱいの小ボタン（同 2 箇所）
    Surface.qml                 旧 AuroraSurface
    FloatingPanel.qml           パネルの殻
    Slider.qml                  旧 VolumeTrack
    Toggle.qml                  旧 QuickToggle
    ListRow.qml                 一覧の 1 行。trailing スロット付き（同 2 箇所）
    EmptyState.qml              一覧が空のときの表示（同 3 箇所）
    PopoutCard.qml              ポップアウトの背景シェル（両ポップアウトで完全一致）
    PopoutHeader.qml            ポップアウトのヘッダー（同上）
    qmldir
  features/
    audio/      Audio.qml, AudioStreams.qml, AudioIcon.qml, VolumeRow.qml, AppVolumeMixer.qml, qmldir
    bluetooth/  Bluetooth.qml, qmldir
    media/      Players.qml, MediaCard.qml, qmldir
    network/    Network.qml, qmldir
    notifications/ Notifs.qml, NotifIcon.qml, NotificationList.qml, AppIconTile.qml, qmldir
    power/      IdleInhibitor.qml, qmldir
    screenshot/ Screenshot.qml, qmldir
  windows/
    ControlCenterWindow.qml
    AudioPopout.qml
    BluetoothPopout.qml
    NotificationToasts.qml      旧 NotificationPopups
  utils/
    Logger.qml
    qmldir
```

### 削除されるファイル（全 11 ファイル・約 3100 行）

| ファイル                                                  | 行数 | 理由                                           |
| --------------------------------------------------------- | ---- | ---------------------------------------------- |
| `modules/controlcenter/sections/SettingsSection.qml`      | 630  | 死蔵（どこからも import されていない）         |
| `modules/controlcenter/sections/MediaSection.qml`         | 617  | 死蔵                                           |
| `modules/controlcenter/sections/PerformanceSection.qml`   | 369  | 死蔵                                           |
| `modules/controlcenter/sections/NotificationsSection.qml` | 344  | 死蔵                                           |
| `services/SystemUsage.qml`                                | 338  | waybar と重複                                  |
| `modules/controlcenter/components/SystemStats.qml`        | 178  | 同上                                           |
| `services/PowerProfiles.qml`                              | 94   | 死蔵（宣言のみ、UI 参照なし）                  |
| `services/Brightness.qml`                                 | 138  | 実機に `/sys/class/backlight` が存在しない     |
| `modules/controlcenter/components/BrightnessSlider.qml`   | 142  | 同上                                           |
| `components/effects/Elevation.qml`                        | 100  | 利用 1 箇所、`MultiEffect` 4 行で代替可能      |
| `components/effects/Material3Anim.qml`                    | 73   | `Appearance` と二重定義。生存 9 トークンを統合 |

---

## Task 1: 死蔵コードの削除

**Files:**

- Delete: `modules/controlcenter/sections/SettingsSection.qml`
- Delete: `modules/controlcenter/sections/MediaSection.qml`
- Delete: `modules/controlcenter/sections/PerformanceSection.qml`
- Delete: `modules/controlcenter/sections/NotificationsSection.qml`
- Delete: `services/PowerProfiles.qml`
- Modify: `services/qmldir`
- Modify: `modules/controlcenter/ControlCenterWindow.qml:27`

**Interfaces:**

- Consumes: なし（最初のタスク）
- Produces: なし。以降のタスクは `sections/` と `PowerProfiles` が存在しない前提で進む。

- [ ] **Step 1: 削除前に死蔵であることを再確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "MediaSection\|NotificationsSection\|PerformanceSection\|SettingsSection" \
  --include='*.qml' --include=qmldir . | grep -v "^./modules/controlcenter/sections/"
grep -rn "PowerProfiles" --include='*.qml' . | grep -v "^./services/PowerProfiles.qml"
```

期待出力: 1本目は何も出ない。2本目は `ControlCenterWindow.qml:27` の 1 行のみ。
これ以外が出た場合は削除を中止し、参照元を報告すること。

- [ ] **Step 2: ファイルを削除する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
git rm -r modules/controlcenter/sections
git rm services/PowerProfiles.qml
```

- [ ] **Step 3: `services/qmldir` から PowerProfiles の行を削除する**

削除する行:

```
singleton PowerProfiles PowerProfiles.qml
```

- [ ] **Step 4: `ControlCenterWindow.qml` から powerProfiles 宣言を削除する**

`modules/controlcenter/ControlCenterWindow.qml:27` の次の行を削除する。

```qml
    readonly property var powerProfiles: QsServices.PowerProfiles
```

- [ ] **Step 5: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラー行なし。目視で Control Center を開き、削除前と見た目が変わらないこと。

- [ ] **Step 6: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): 死蔵の sections/ と PowerProfiles を削除"
```

---

## Task 2: SystemUsage と SystemStats の削除

waybar が同じ情報を表示しているため不要。10 個の `/bin/sh` を 2 秒ごとに起動していた処理が消える。

**Files:**

- Delete: `services/SystemUsage.qml`
- Delete: `modules/controlcenter/components/SystemStats.qml`
- Modify: `services/qmldir`
- Modify: `modules/controlcenter/components/qmldir`
- Modify: `modules/controlcenter/ControlCenterWindow.qml:26`, `:363-367`

**Interfaces:**

- Consumes: Task 1 完了状態
- Produces: なし

- [ ] **Step 1: 参照箇所を確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "SystemUsage\|SystemStats" --include='*.qml' --include=qmldir .
```

期待出力は次の 5 箇所のみ。

```
./services/qmldir:  singleton SystemUsage SystemUsage.qml
./modules/controlcenter/components/qmldir:  SystemStats 1.0 SystemStats.qml
./modules/controlcenter/ControlCenterWindow.qml:26:    readonly property var systemUsage: QsServices.SystemUsage
./modules/controlcenter/ControlCenterWindow.qml:364:                SystemStats {
./modules/controlcenter/ControlCenterWindow.qml:366:                    systemUsage: root.systemUsage
```

- [ ] **Step 2: ファイルを削除する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
git rm services/SystemUsage.qml modules/controlcenter/components/SystemStats.qml
```

- [ ] **Step 3: qmldir から行を削除する**

`services/qmldir` から削除:

```
singleton SystemUsage SystemUsage.qml
```

`modules/controlcenter/components/qmldir` から削除:

```
SystemStats 1.0 SystemStats.qml
```

- [ ] **Step 4: `ControlCenterWindow.qml` の宣言と描画を削除する**

26 行目の次の行を削除する。

```qml
    readonly property var systemUsage: QsServices.SystemUsage
```

363〜367 行目の次のブロックを削除する。直前のコメント行と、その上の Divider も一緒に消す。

```qml
                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: QsConfig.Theme.border
                }

                // System Stats
                SystemStats {
                    Layout.fillWidth: true
                    systemUsage: root.systemUsage
                }
```

Divider を消す理由: SystemStats と MediaCard の間の区切りだったため、SystemStats が消えると
スライダー群と MediaCard の間に区切りが 2 本連続してしまう。

- [ ] **Step 5: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。Control Center を開き、CPU/メモリのグラフが消えて、
スライダーの下に MediaCard が直接続くこと。区切り線が 2 本連続していないこと。

- [ ] **Step 6: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): SystemUsage を削除（waybar と重複）"
```

---

## Task 3: Brightness の削除

実機の `/sys/class/backlight/` が空でバックライト制御対象が存在しないため、機能していない。

**Files:**

- Delete: `services/Brightness.qml`
- Delete: `modules/controlcenter/components/BrightnessSlider.qml`
- Modify: `services/qmldir`
- Modify: `modules/controlcenter/components/qmldir`

**Interfaces:**

- Consumes: Task 2 完了状態
- Produces: なし

- [ ] **Step 1: バックライトが存在しないことを確認する**

```bash
ls -1 /sys/class/backlight/
```

期待: 何も出力されない。もし何か出力された場合は、このタスクを中止してユーザーに報告する。

- [ ] **Step 2: 参照箇所を確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "Brightness" --include='*.qml' --include=qmldir . | grep -v "^./services/Brightness.qml\|^./modules/controlcenter/components/BrightnessSlider.qml"
```

期待出力は qmldir の 2 行のみ。Task 1 で `SettingsSection.qml` を消しているため、
`BrightnessSlider` の唯一の利用元だった参照はすでに無い。

- [ ] **Step 3: ファイルを削除して qmldir を更新する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
git rm services/Brightness.qml modules/controlcenter/components/BrightnessSlider.qml
```

`services/qmldir` から削除:

```
singleton Brightness Brightness.qml
```

`modules/controlcenter/components/qmldir` から削除:

```
BrightnessSlider 1.0 BrightnessSlider.qml
```

- [ ] **Step 4: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。

- [ ] **Step 5: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): 実機に対象が無い Brightness を削除"
```

---

## Task 4: Control Center のボタン整理

ヘッダー右上から Settings と Lock Screen を削除し、Power Menu だけ残す。
QuickToggle から Open Captures を削除して 6 個にし、2 列 × 3 行に揃える。

**Files:**

- Modify: `modules/controlcenter/ControlCenterWindow.qml:31-53`, `:134-143`, `:213-215`, `:248-258`
- Modify: `services/Screenshot.qml:13`

**Interfaces:**

- Consumes: Task 3 完了状態
- Produces: なし

- [ ] **Step 1: ヘッダーの Settings / Lock Screen ボタンを削除する**

`ControlCenterWindow.qml` の 134〜143 行目、次の 2 ブロックを削除する。

```qml
                    HeaderButton {
                        icon: "󰒓"
                        tooltip: "Settings"
                        onClicked: settingsProcess.running = true
                    }
                    HeaderButton {
                        icon: "󰍜"
                        tooltip: "Lock Screen"
                        onClicked: lockProcess.running = true
                    }
```

残るのは Power Menu の 1 ブロックのみ。

```qml
                    HeaderButton {
                        icon: "󰐥"
                        tooltip: "Power Menu"
                        onClicked: powerProcess.running = true
                    }
```

- [ ] **Step 2: 使われなくなった Process を削除する**

31〜53 行目付近から、次の 3 つの `Process` を削除する。
`settingsProcess` と `lockProcess` は Step 1 で参照元が消えた。
`screenshotsProcess` は Step 3 で参照元が消える。

```qml
    Process {
        id: settingsProcess
        ...
    }

    Process {
        id: lockProcess
        command: ["hyprlock"]
        ...
    }

    Process {
        id: screenshotsProcess
        command: ["wezterm", "start", "--", "yazi", root.screenshot.screenshotsDir]
        ...
    }
```

`powerProcess`（`command: ["wlogout"]`）は残す。

- [ ] **Step 3: Open Captures トグルを削除する**

248〜258 行目の次のブロックを削除する。

```qml
                    QuickToggle {
                        Layout.fillWidth: true
                        icon: "󰉋"
                        label: "Open Captures"
                        subLabel: "Screenshots & recordings"
                        active: false
                        activeColor: QsConfig.Theme.secondary
                        surfaceColor: QsConfig.Theme.card
                        textColor: QsConfig.Theme.text
                        onClicked: screenshotsProcess.running = true
                    }
```

- [ ] **Step 4: Screenshot トグルの columnSpan を外す**

215 行目の次の 1 行を削除して、6 個すべてが同じ幅で 2 列 × 3 行に並ぶようにする。

```qml
                        Layout.columnSpan: 2
```

削除後、Screenshot の QuickToggle は次の形になる。

```qml
                    QuickToggle {
                        Layout.fillWidth: true
                        icon: "󰹑"
                        label: "Screenshot"
                        subLabel: "Region / Window / Output"
                        active: false
                        activeColor: QsConfig.Theme.secondary
                        surfaceColor: QsConfig.Theme.card
                        textColor: QsConfig.Theme.text
                        onClicked: {
                            root.shouldShow = false;
                            root.screenshot.openMenu();
                        }
                    }
```

- [ ] **Step 5: 未使用になった screenshotsDir を削除する**

`services/Screenshot.qml:13` の次の行を削除する。Step 3 で唯一の参照元が消えたため。

```qml
    readonly property string screenshotsDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
```

削除前に参照が無いことを確認する。

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "screenshotsDir" --include='*.qml' .
```

期待: `services/Screenshot.qml` の定義行のみ。

- [ ] **Step 6: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。目視で次を確認する。

- ヘッダー右上のボタンが電源アイコン 1 個だけになっている
- QuickToggle が 6 個、2 列 × 3 行で均等な幅に並んでいる
- 並び順は Wi-Fi / Bluetooth / Do Not Disturb / Caffeine / Screenshot / Record Screen

- [ ] **Step 7: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): CC のボタンを 6 個に整理"
```

---

## Task 5: Audio を Pipewire バインディングへ書き換え

現状は `wpctl get-volume` を 250ms ごとに 2 プロセス起動している（毎秒 8 プロセス）。
同リポジトリの `AudioStreams.qml` が既に Pipewire を宣言的に使っており、そちらに揃える。

**Files:**

- Rewrite: `services/Audio.qml`（120 行 → 約 45 行）

**Interfaces:**

- Consumes: Task 4 完了状態
- Produces: `Audio` シングルトンの公開インターフェース。既存の消費者が使っている名前を維持すること。
  - `readonly property bool ready`
  - `readonly property bool muted`
  - `readonly property real volume`（0.0〜1.5）
  - `readonly property int percentage`
  - `readonly property bool sourceReady`
  - `readonly property bool sourceMuted`
  - `readonly property real sourceVolume`
  - `readonly property int sourcePercentage`
  - `function setVolume(v: real)`
  - `function increaseVolume()`
  - `function decreaseVolume()`
  - `function setMute(m: bool)`
  - `function toggleMute()`
  - `function setSourceVolume(v: real)`
  - `function setSourceMute(m: bool)`
  - `function toggleSourceMute()`

- [ ] **Step 1: 現在の消費者を確認して、維持すべき名前を固定する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "audio\.\|Audio\." --include='*.qml' modules | grep -v AudioStreams
```

期待: `VolumeSlider.qml` が `audio.percentage` と `audio.muted` を、
`ControlCenterWindow.qml` が `root.audio` を子へ渡していること。
上の Produces に挙げた名前以外が使われていたら、その名前も維持対象に加える。

- [ ] **Step 2: `services/Audio.qml` を全面的に書き換える**

ファイル全体を次の内容で置き換える。

```qml
pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// 音量は Pipewire のノードに直接バインドする。
// wpctl のポーリングは毎秒 8 プロセスを起動していたため置き換えた。
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool ready: root.sink?.ready ?? false
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property int percentage: Math.round(root.volume * 100)

    readonly property bool sourceReady: root.source?.ready ?? false
    readonly property bool sourceMuted: root.source?.audio?.muted ?? false
    readonly property real sourceVolume: root.source?.audio?.volume ?? 0
    readonly property int sourcePercentage: Math.round(root.sourceVolume * 100)

    // tracker で保持しないと audio プロパティの変更通知が来ない
    PwObjectTracker {
        objects: [root.sink, root.source].filter(n => n)
    }

    function clamp(v) {
        return Math.max(0, Math.min(1.5, v))
    }

    function setVolume(v) {
        if (!root.sink?.audio)
            return
        root.sink.audio.muted = false
        root.sink.audio.volume = root.clamp(v)
    }

    function increaseVolume() {
        root.setVolume(root.volume + 0.05)
    }

    function decreaseVolume() {
        root.setVolume(root.volume - 0.05)
    }

    function setMute(m) {
        if (root.sink?.audio)
            root.sink.audio.muted = m
    }

    function toggleMute() {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted
    }

    function setSourceVolume(v) {
        if (!root.source?.audio)
            return
        root.source.audio.muted = false
        root.source.audio.volume = root.clamp(v)
    }

    function setSourceMute(m) {
        if (root.source?.audio)
            root.source.audio.muted = m
    }

    function toggleSourceMute() {
        if (root.source?.audio)
            root.source.audio.muted = !root.source.audio.muted
    }
}
```

- [ ] **Step 3: ポーリングが消えたことを検証する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#build
systemctl --user restart quickshell && sleep 5
```

`wpctl` のプロセス生成が止まったことを確認する。

```bash
timeout 10 strace -f -e trace=execve -p $(systemctl --user show -p MainPID --value quickshell) 2>&1 | grep -c wpctl
```

期待: `0`。
`strace` が使えない環境の場合は、代わりに次で確認する。

```bash
for i in 1 2 3 4 5; do pgrep -c wpctl || true; sleep 1; done
```

期待: 全行 `0`。

- [ ] **Step 4: 音量操作が動くことを目視確認する**

Control Center を開き、次を確認する。

- 音量スライダーが現在の音量を表示している
- スライダーを動かすと実際に音量が変わる
- ミュートボタンで消音と復帰ができる
- 外部（`wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.5` 等）で変更したとき、スライダーが即座に追従する

最後の項目が Pipewire バインディングの効果で、ポーリング時代は最大 250ms 遅れていた。

- [ ] **Step 5: コミット**

```bash
git add -A
git commit -m "perf(quickshell): Audio を Pipewire バインディングへ移行しポーリングを撤廃"
```

---

## Task 6: theme/ の確立とモーショントークンの一本化

`config/` からデザイントークンを `theme/` へ分離し、`Colours` を `services/` から `theme/` へ移す。
`Material3Anim` の生存 9 トークンを `Appearance.anim` に統合し、`Material3Anim` と `Elevation` を削除する。

**Files:**

- Create: `theme/qmldir`
- Move: `services/Colours.qml` → `theme/Colours.qml`
- Move: `config/Theme.qml` → `theme/Theme.qml`
- Move: `config/Appearance.qml` → `theme/Appearance.qml`
- Delete: `components/effects/Material3Anim.qml`
- Delete: `components/effects/Elevation.qml`
- Delete: `components/effects/qmldir`
- Modify: `config/qmldir`, `services/qmldir`
- Modify: `components/containers/AuroraSurface.qml`
- Modify: 全 import 参照元

**Interfaces:**

- Consumes: Task 5 完了状態
- Produces:
  - `theme` モジュールが `Colours` / `Theme` / `Appearance` の 3 シングルトンを公開する
  - `Appearance.anim.durations` に `short2`(100), `short3`(150), `short4`(200), `medium2`(300), `medium4`(400) が加わる
  - `Appearance.anim.curves` に `springGentle` が加わる
  - `Material3Anim.X` の全参照が `Appearance.anim.durations.X` または `Appearance.anim.curves.X` に置き換わる

- [ ] **Step 1: 現在の Material3Anim 参照を棚卸しする**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rhoE "Material3Anim\.[a-zA-Z]+" --include='*.qml' . | sort | uniq -c | sort -rn
```

期待出力（Task 1〜3 の削除後）:

```
     32 Material3Anim.standard
     12 Material3Anim.medium2
     10 Material3Anim.short3
      9 Material3Anim.short2
      7 Material3Anim.short4
      5 Material3Anim.emphasizedDecelerate
      1 Material3Anim.medium4
      1 Material3Anim.emphasizedAccelerate
      1 Material3Anim.springGentle
      1 Material3Anim.hoverScale
```

件数は削除タスクの結果により減っている可能性がある。
ここに **上記 10 種以外** のトークンが現れた場合は、Step 2 の統合先に追加すること。

- [ ] **Step 2: ディレクトリを作ってファイルを移動する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
mkdir -p theme
git mv services/Colours.qml theme/Colours.qml
git mv config/Theme.qml theme/Theme.qml
git mv config/Appearance.qml theme/Appearance.qml
git rm components/effects/Material3Anim.qml components/effects/Elevation.qml components/effects/qmldir
```

- [ ] **Step 3: `theme/qmldir` を作る**

```
module qs.theme
singleton Colours Colours.qml
singleton Theme Theme.qml
singleton Appearance Appearance.qml
```

- [ ] **Step 4: `config/qmldir` と `services/qmldir` を更新する**

`config/qmldir` の全内容を次に置き換える。

```
module qs.config
singleton Config Config.qml
```

`services/qmldir` から次の行を削除する。

```
singleton Colours Colours.qml
```

- [ ] **Step 5: `theme/Appearance.qml` にモーショントークンを統合する**

63〜77 行目の `anim` ブロックを、次の内容で置き換える。
`durations` の既存 4 種は残したまま、M3 の 5 種を追加する。既存参照を壊さないため。

```qml
    // M3 の duration トークンと、本設定で先に使っていた 4 種が併存する。
    // 新規コードは M3 側（short2/short3/short4/medium2/medium4）を使う。
    readonly property var anim: QtObject {
        readonly property var durations: QtObject {
            property int fast: 120
            property int normal: 180
            property int medium: 260
            property int slow: 340

            property int short2: 100
            property int short3: 150
            property int short4: 200
            property int medium2: 300
            property int medium4: 400
        }
        readonly property var curves: QtObject {
            property var standard: [0.2, 0.0, 0, 1.0]
            property var standardDecel: [0.0, 0.0, 0, 1.0]
            property var standardAccel: [0.3, 0.0, 1, 1.0]
            property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0]
            property var emphasizedAccel: [0.3, 0.0, 0.8, 0.15]
            property var springGentle: [0.22, 1.0, 0.36, 1.0]
        }
        readonly property real hoverScale: 1.02
    }
```

- [ ] **Step 6: 未使用の typography 段を削除する**

`theme/Appearance.qml` の `typography` ブロックから、参照 0 回の 5 段を削除する。

削除する行:

```qml
        readonly property var displayLarge: QtObject { property int size: 57; property int weight: Font.Normal }
        readonly property var displayMedium: QtObject { property int size: 45; property int weight: Font.Normal }
        readonly property var titleSmall: QtObject { property int size: 14; property int weight: Font.Medium }
        readonly property var labelLarge: QtObject { property int size: 14; property int weight: Font.Medium }
        readonly property var bodySmall: QtObject { property int size: 12; property int weight: Font.Normal }
```

削除前に参照が無いことを確認する。

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "displayLarge\|displayMedium\|titleSmall\|labelLarge\|bodySmall" --include='*.qml' .
```

期待: `theme/Appearance.qml` の定義行のみ。他が出たら、その段は削除しない。

- [ ] **Step 7: Material3Anim の参照を Appearance へ置換する**

対象ファイル全体に対して次の置換を行う。

| 置換前                               | 置換後                                           |
| ------------------------------------ | ------------------------------------------------ |
| `Material3Anim.short2`               | `QsTheme.Appearance.anim.durations.short2`       |
| `Material3Anim.short3`               | `QsTheme.Appearance.anim.durations.short3`       |
| `Material3Anim.short4`               | `QsTheme.Appearance.anim.durations.short4`       |
| `Material3Anim.medium2`              | `QsTheme.Appearance.anim.durations.medium2`      |
| `Material3Anim.medium4`              | `QsTheme.Appearance.anim.durations.medium4`      |
| `Material3Anim.standard`             | `QsTheme.Appearance.anim.curves.standard`        |
| `Material3Anim.emphasizedDecelerate` | `QsTheme.Appearance.anim.curves.emphasizedDecel` |
| `Material3Anim.emphasizedAccelerate` | `QsTheme.Appearance.anim.curves.emphasizedAccel` |
| `Material3Anim.springGentle`         | `QsTheme.Appearance.anim.curves.springGentle`    |
| `Material3Anim.hoverScale`           | `QsTheme.Appearance.anim.hoverScale`             |

`emphasizedDecelerate` → `emphasizedDecel` の名前変更に注意すること。値は同一（`[0.05, 0.7, 0.1, 1.0]`）。

- [ ] **Step 8: import 文を全面的に更新する**

各ファイルの import を次のように直す。`QsConfig.Theme` / `QsConfig.Appearance` は
`QsTheme.Theme` / `QsTheme.Appearance` になる。`QsConfig.Config` はそのまま。

`modules/` 配下の 2 階層下のファイル（例 `modules/controlcenter/ControlCenterWindow.qml`）:

```qml
import "../../theme" as QsTheme
import "../../config" as QsConfig
```

`modules/controlcenter/components/` 配下（3 階層下）:

```qml
import "../../../theme" as QsTheme
```

`components/containers/` 配下:

```qml
import "../../theme" as QsTheme
```

`shell.qml`:

```qml
import "theme" as QsTheme
import "config" as QsConfig
```

そのうえで、各ファイル内の `QsConfig.Theme` を `QsTheme.Theme` に、
`QsConfig.Appearance` を `QsTheme.Appearance` に置換する。
`QsConfig.Config` は置換しない。

`components/effects` を import している行は削除する。

```qml
import "../../../components/effects"
import "../../components/effects"
```

- [ ] **Step 9: `theme/Colours.qml` と `theme/Theme.qml` の内部 import を直す**

`theme/Colours.qml` の import は **変更不要**。
`services/` も `theme/` もルートから 1 階層下なので、次の 2 行はそのまま正しい。

```qml
import "../config" as QsConfig
import "../utils" as QsUtils
```

`theme/Theme.qml` の 5 行目を削除する。`Colours` が同じディレクトリになったため。

```qml
import "../services" as QsServices
```

そして 12 行目を次に直す。

```qml
    readonly property var p: Colours
```

- [ ] **Step 10: `AuroraSurface.qml` の Elevation を MultiEffect に置き換える**

43〜48 行目の次のブロックを削除する。

```qml
    Elevation {
        level: root.highlighted ? root.elevation + 2 : root.hovered ? root.elevation + 1 : root.elevation
        target: surface
        radius: surface.radius
        shadowColor: Qt.rgba(root.shadowColor.r, root.shadowColor.g, root.shadowColor.b, root.highlighted ? 0.24 : 0.18)
    }
```

代わりに、`surface` の `Rectangle` に layer effect を足す。
`Rectangle { id: surface ... }` の `clip: root.clipContent` の直後に次を挿入する。

影の濃さは `Qt.rgba` ではなく `shadowOpacity` で与える（色に alpha を埋め込まないため）。

```qml
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.shadowColor
            shadowOpacity: root.highlighted ? 0.24 : 0.18
            shadowBlur: 0.4
            shadowVerticalOffset: 4
        }
```

ファイル先頭に import を追加する。

```qml
import QtQuick.Effects
```

`elevation` プロパティ（14 行目 `property int elevation: 2`）は参照元が無くなるので削除する。
削除前に確認する。

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "elevation" --include='*.qml' .
```

期待: `AuroraSurface.qml` の定義行のみ。

- [ ] **Step 11: 参照漏れがないことを確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "Material3Anim\|Elevation\|components/effects" --include='*.qml' --include=qmldir .
grep -rn "QsConfig\.Theme\|QsConfig\.Appearance" --include='*.qml' .
grep -rn "QsServices\.Colours" --include='*.qml' .
```

期待: 3 本とも何も出力されない。

- [ ] **Step 12: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。目視で次を確認する。

- Control Center が開き、色が壁紙に追従している
- カードに影がついている（Elevation の置き換えが効いている）
- ホバー時のアニメーションが以前と同じ速さで動く

壁紙変更時のリロードも確認する。

```bash
qs -c shell ipc call theme reload
```

期待: エラーが出ず、色が再読込される。

- [ ] **Step 13: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): theme/ を分離しモーショントークンを Appearance に一本化"
```

---

## Task 7: ui/ の基礎部品（IconText / Label / Divider / StateLayer）

横断で最も多く重複している 4 つを先に作る。以降の部品はこれらを土台にする。

**Files:**

- Create: `ui/qmldir`, `ui/IconText.qml`, `ui/Label.qml`, `ui/Divider.qml`, `ui/StateLayer.qml`
- Modify: 呼び出し元 全 9 ファイル

**Interfaces:**

- Consumes: Task 6 の `theme` モジュール（`QsTheme.Theme` / `QsTheme.Appearance`）
- Produces:
  - `IconText { text: string, size: real, color: color }` — アイコンフォントの 1 文字表示
  - `Label { text: string, variant: string, muted: bool, elide: bool }` — 本文テキスト。`variant` は `"headline" | "title" | "body" | "label" | "caption"`
  - `Divider {}` — 1px の水平線。プロパティなし
  - `StateLayer { target: Item, hovered: bool, pressed: bool, hoverColor: color, pressedScale: real }` — ホバー色と押下スケールを 1 つにまとめる

- [ ] **Step 1: `ui/IconText.qml` を作る**

アイコンフォントの Text は 30 箇所超で同じ 3〜4 行が繰り返されている
（`AudioPopout:70-75, 87-93, 144-150, 267-272` / `BluetoothPopout:75-81, 160-173, 252-270, 320-326, 347-353, 373-387` /
`MediaCard:194-201, 290-296, 346-352` / `ControlCenterWindow:296-301, 312-317, 414-420` ほか）。

```qml
import QtQuick 6.10
import "../theme" as QsTheme

// アイコンフォントの 1 文字表示。size は Appearance.typography の段を数値で受ける。
Text {
    id: root

    property real size: QsTheme.Appearance.typography.bodyMedium.size

    font.family: QsTheme.Appearance.typography.iconFamily
    font.pixelSize: root.size
    color: QsTheme.Theme.text
}
```

- [ ] **Step 2: `ui/Label.qml` を作る**

本文テキストは 23 箇所超で `family / pixelSize / weight / color` の 4 行が繰り返されている。
`variant` で 3 つをまとめて決める。

```qml
import QtQuick 6.10
import "../theme" as QsTheme

// 本文テキスト。variant で font の 3 プロパティを一括決定する。
Text {
    id: root

    property string variant: "body"
    property bool muted: false

    readonly property var _spec: ({
        headline: QsTheme.Appearance.typography.headlineSmall,
        title: QsTheme.Appearance.typography.titleMedium,
        body: QsTheme.Appearance.typography.bodyMedium,
        label: QsTheme.Appearance.typography.labelMedium,
        caption: QsTheme.Appearance.typography.labelSmall
    })[root.variant] ?? QsTheme.Appearance.typography.bodyMedium

    font.family: QsTheme.Appearance.typography.family
    font.pixelSize: root._spec.size
    font.weight: root._spec.weight
    color: root.muted ? QsTheme.Theme.textVariant : QsTheme.Theme.text
    elide: Text.ElideRight
}
```

`elide` を既定で有効にしているのは、既存コードの大半が `elide: Text.ElideRight` を
付けているため。不要な箇所は呼び出し側で `elide: Text.ElideNone` と書く。

- [ ] **Step 3: `ui/Divider.qml` を作る**

`ControlCenterWindow:262-266` と `:357-361` が 0 差分で 2 回書かれている。

```qml
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../theme" as QsTheme

Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: 1
    color: QsTheme.Theme.border
}
```

- [ ] **Step 4: `ui/StateLayer.qml` を作る**

「ホバーで背景色が変わる」「押下でスケールが縮む」の組は 13 箇所超で反復している
（`NotificationPopups:653-659, 673-675, 805-816, 819-824` /
`NotificationList:64-73, 147-156, 159-165, 259-268` /
`AudioPopout:57, 261` / `BluetoothPopout:216, 316, 343, 454` ほか）。

M3 の state layer をそのまま部品にする。

```qml
import QtQuick 6.10
import "../theme" as QsTheme

// M3 の state layer。対象の面色と押下スケールをまとめて面倒を見る。
// 色は不透明トークンで切り替える（alpha 合成しない）。
QtObject {
    id: root

    property bool hovered: false
    property bool pressed: false
    property color baseColor: "transparent"
    property color hoverColor: QsTheme.Theme.cardHigh
    property real pressedScale: 0.96

    readonly property color color: root.hovered ? root.hoverColor : root.baseColor
    readonly property real scale: root.pressed ? root.pressedScale : 1.0
}
```

`QtObject` にしているのは、色とスケールの計算だけを担わせ、
どの要素に適用するかは呼び出し側が決めるため。使い方は次の形。

```qml
Rectangle {
    color: state.color
    scale: state.scale
    Behavior on color { ColorAnimation { duration: QsTheme.Appearance.anim.durations.short3; easing.bezierCurve: QsTheme.Appearance.anim.curves.standard } }
    Behavior on scale { NumberAnimation { duration: QsTheme.Appearance.anim.durations.short2; easing.bezierCurve: QsTheme.Appearance.anim.curves.standard } }

    StateLayer { id: state; hovered: ma.containsMouse; pressed: ma.pressed }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
}
```

- [ ] **Step 5: `ui/qmldir` を作る**

```
module qs.ui
IconText 1.0 IconText.qml
Label 1.0 Label.qml
Divider 1.0 Divider.qml
StateLayer 1.0 StateLayer.qml
```

- [ ] **Step 6: 呼び出し元を置換する**

対象 9 ファイルすべてで、次の 3 パターンを置換する。

アイコン Text（置換前）:

```qml
                Text {
                    text: "󰕾"
                    font.family: QsConfig.Appearance.typography.iconFamily
                    font.pixelSize: QsConfig.Appearance.typography.bodyMedium.size
                    color: QsConfig.Theme.textMuted
                }
```

置換後:

```qml
                IconText {
                    text: "󰕾"
                    size: QsTheme.Appearance.typography.bodyMedium.size
                    color: QsTheme.Theme.textVariant
                }
```

本文 Text（置換前）:

```qml
                Text {
                    Layout.fillWidth: true
                    text: "アプリ音量"
                    font.family: QsConfig.Appearance.typography.family
                    font.pixelSize: QsConfig.Appearance.typography.labelMedium.size
                    font.weight: Font.DemiBold
                    color: QsConfig.Theme.textMuted
                }
```

置換後:

```qml
                Label {
                    Layout.fillWidth: true
                    text: "アプリ音量"
                    variant: "label"
                    muted: true
                }
```

`font.weight` が `variant` の既定と違う場合（上の例は `DemiBold` だが `labelMedium` は `Medium`）は、
呼び出し側で `font.weight: Font.DemiBold` を明示的に上書きする。

区切り線（置換前）:

```qml
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: QsConfig.Theme.border
                }
```

置換後:

```qml
                Divider {}
```

各ファイルの import に次を追加する（階層に応じて `../` の数を調整）。

```qml
import "../../ui"
```

- [ ] **Step 7: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。特に `IconText is not a type` が出ないこと。

削減量を確認する。

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rc "typography.iconFamily" --include='*.qml' . | grep -v ':0'
```

期待: `ui/IconText.qml` の 1 行のみ。他ファイルに残っていたら置換漏れ。

目視で全画面のテキストとアイコンが以前と同じ大きさ・色で出ていることを確認する。

- [ ] **Step 8: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): IconText/Label/Divider/StateLayer を ui/ に抽出"
```

---

## Task 8: ui/ のボタン群（IconButton / TextIconButton / PillButton）

ボタン相当の構造が 12 箇所以上で個別に書かれている。3 つの型に集約する。

**Files:**

- Create: `ui/IconButton.qml`, `ui/TextIconButton.qml`, `ui/PillButton.qml`
- Modify: `ui/qmldir`
- Modify: `modules/controlcenter/ControlCenterWindow.qml:387-451`（`HeaderButton` を削除）
- Modify: `modules/controlcenter/components/MediaCard.qml:319-361`（`ControlButton` を削除）
- Modify: `modules/popouts/BluetoothPopout.qml:311-335, 338-362, 365-412, 144-192, 450-482`
- Modify: `modules/popouts/AudioPopout.qml:257-289`
- Modify: `modules/notifications/NotificationPopups.qml:647-703, 798-848`
- Modify: `modules/controlcenter/components/NotificationList.qml:58-92, 253-294`
- Modify: `modules/controlcenter/components/VolumeSlider.qml:43-81`
- Modify: `modules/controlcenter/components/AppVolumeMixer.qml:72-104`

**Interfaces:**

- Consumes: Task 7 の `IconText` / `StateLayer`
- Produces:
  - `IconButton { icon: string, size: real, iconSize: real, iconColor: color, hoverColor: color, borderColor: color, tooltip: string, spinning: bool, filled: bool, signal clicked }`
  - `TextIconButton { icon: string, label: string, spinning: bool, signal clicked }`
  - `PillButton { text: string, hPadding: real, baseColor: color, hoverColor: color, textColor: color, signal clicked }`

- [ ] **Step 1: `ui/IconButton.qml` を作る**

統合元は 8 箇所。
`BluetoothPopout:311-335`（Trust）、`:338-362`（Forget）、`:365-412`（接続、回転あり）、
`MediaCard:319-361`（ControlButton）、`:265-307`（Play/Pause、塗りつぶし）、
`ControlCenterWindow:387-451`（HeaderButton、tooltip あり）、
`NotificationPopups:647-703`（閉じる）、`NotificationList:253-294`（閉じる）。

差分は size / icon / 色 / border / tooltip / 回転 / 塗りつぶしなので、すべて property にする。

```qml
import QtQuick 6.10
import QtQuick.Controls 6.10
import "../theme" as QsTheme

// 円形アイコンボタン。BT の 3 連コピー・MediaCard・ヘッダー・通知の閉じるを統合。
Rectangle {
    id: root

    property string icon
    property real size: 40
    property real iconSize: QsTheme.Appearance.typography.bodyMedium.size
    property color iconColor: QsTheme.Theme.text
    property color hoverIconColor: root.iconColor
    property color baseColor: "transparent"
    property color hoverColor: QsTheme.Theme.cardHigh
    property color borderColor: "transparent"
    property string tooltip: ""
    property bool spinning: false
    property bool filled: false

    signal clicked

    implicitWidth: root.size
    implicitHeight: root.size
    width: root.size
    height: root.size
    radius: height / 2

    color: root.filled ? QsTheme.Theme.accent : layer.color
    scale: layer.scale
    border.width: root.borderColor === "transparent" ? 0 : 1
    border.color: root.borderColor

    StateLayer {
        id: layer
        hovered: mouse.containsMouse
        pressed: mouse.pressed
        baseColor: root.baseColor
        hoverColor: root.hoverColor
        pressedScale: 0.92
    }

    Behavior on color {
        ColorAnimation {
            duration: QsTheme.Appearance.anim.durations.short3
            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: QsTheme.Appearance.anim.durations.short2
            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
        }
    }

    IconText {
        id: glyph
        anchors.centerIn: parent
        text: root.icon
        size: root.iconSize
        color: root.filled ? QsTheme.Theme.onAccent : (mouse.containsMouse ? root.hoverIconColor : root.iconColor)

        RotationAnimation on rotation {
            running: root.spinning
            from: 0
            to: 360
            duration: 1200
            loops: Animation.Infinite
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    ToolTip {
        id: tip
        visible: mouse.containsMouse && root.tooltip !== ""
        text: root.tooltip
        delay: 500

        contentItem: Label {
            text: tip.text
            variant: "label"
        }

        background: Rectangle {
            radius: QsTheme.Appearance.radius.s
            color: QsTheme.Theme.card
            border.width: 1
            border.color: QsTheme.Theme.border
        }
    }
}
```

`spinning` が false のとき `RotationAnimation` は停止するが、`rotation` は最後の値で止まる。
停止時に 0 へ戻すため、`glyph` に次を足す。

```qml
        onVisibleChanged: if (!root.spinning) rotation = 0
```

- [ ] **Step 2: `ui/TextIconButton.qml` を作る**

`AudioPopout:257-289` と `BluetoothPopout:450-482` はラベル文字列以外が完全一致。
`BluetoothPopout:144-192` のスキャンボタンも、回転アニメを付ければ同型。

```qml
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../theme" as QsTheme

// アイコン + ラベルの横長ボタン。両ポップアウトの設定ボタンとスキャンボタンを統合。
Rectangle {
    id: root

    property string icon
    property string label
    property bool spinning: false

    signal clicked

    Layout.fillWidth: true
    Layout.preferredHeight: 36
    radius: QsTheme.Appearance.radius.s
    color: layer.color

    StateLayer {
        id: layer
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    Behavior on color {
        ColorAnimation {
            duration: QsTheme.Appearance.anim.durations.fast
        }
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: QsTheme.Appearance.spacing.s

        IconText {
            text: root.icon
            size: QsTheme.Appearance.typography.bodyMedium.size
            color: QsTheme.Theme.textVariant

            RotationAnimation on rotation {
                running: root.spinning
                from: 0
                to: 360
                duration: 1200
                loops: Animation.Infinite
            }
        }

        Label {
            text: root.label
            variant: "label"
            muted: true
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
```

- [ ] **Step 3: `ui/PillButton.qml` を作る**

`NotificationPopups:798-848`（通知アクション）と `NotificationList:58-92`（Clear All）を統合。

```qml
import QtQuick 6.10
import "../theme" as QsTheme

// 角丸いっぱいの小ボタン。通知アクションと Clear All を統合。
Rectangle {
    id: root

    property alias text: content.text
    property real hPadding: 18
    property color baseColor: QsTheme.Theme.card
    property color hoverColor: QsTheme.Theme.cardHigh
    property color textColor: QsTheme.Theme.text

    signal clicked

    implicitWidth: content.implicitWidth + root.hPadding
    implicitHeight: 28
    radius: height / 2

    color: layer.color
    scale: layer.scale

    StateLayer {
        id: layer
        hovered: mouse.containsMouse
        pressed: mouse.pressed
        baseColor: root.baseColor
        hoverColor: root.hoverColor
        pressedScale: 0.94
    }

    Behavior on color {
        ColorAnimation {
            duration: QsTheme.Appearance.anim.durations.short3
            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: QsTheme.Appearance.anim.durations.short2
            easing.bezierCurve: QsTheme.Appearance.anim.curves.standard
        }
    }

    Label {
        id: content
        anchors.centerIn: parent
        variant: "label"
        color: root.textColor
        elide: Text.ElideNone
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
```

- [ ] **Step 4: `ui/qmldir` に 3 行追加する**

```
IconButton 1.0 IconButton.qml
TextIconButton 1.0 TextIconButton.qml
PillButton 1.0 PillButton.qml
```

- [ ] **Step 5: `ControlCenterWindow` の HeaderButton を置き換える**

387〜451 行目の `component HeaderButton: Rectangle { ... }` 定義を丸ごと削除する。

呼び出し側（Task 4 で 1 個に減っている）を次に置き換える。

置換前:

```qml
                    HeaderButton {
                        icon: "󰐥"
                        tooltip: "Power Menu"
                        onClicked: powerProcess.running = true
                    }
```

置換後:

```qml
                    IconButton {
                        icon: "󰐥"
                        iconSize: QsTheme.Appearance.typography.titleMedium.size
                        hoverColor: QsTheme.Theme.cardHigh
                        tooltip: "Power Menu"
                        onClicked: powerProcess.running = true
                    }
```

`HeaderButton` は既定色が `Theme.card` だったので、`baseColor` で与える。
`Rectangle.color` を直接指定すると `layer.color` のバインドを壊すため、
必ず `baseColor` を使うこと。

```qml
                    IconButton {
                        icon: "󰐥"
                        iconSize: QsTheme.Appearance.typography.titleMedium.size
                        baseColor: QsTheme.Theme.card
                        tooltip: "Power Menu"
                        onClicked: powerProcess.running = true
                    }
```

- [ ] **Step 6: `MediaCard` の ControlButton を置き換える**

319〜361 行目の `component ControlButton: Rectangle { ... }` 定義を丸ごと削除する。

呼び出し 3 箇所を `IconButton` に置き換える。ハードコードだった
`Qt.rgba(1, 1, 1, 0.15)` / `Qt.rgba(1, 1, 1, 0.05)` は Theme トークンになる。

```qml
                    IconButton {
                        icon: "󰒮"
                        size: 40
                        iconSize: QsTheme.Appearance.typography.titleLarge.size
                        baseColor: QsTheme.Theme.card
                        hoverColor: QsTheme.Theme.cardHigh
                        onClicked: root.mpris.previous()
                    }
```

265〜307 行目の Play/Pause は `filled: true` を使う。

```qml
                    IconButton {
                        icon: root.mpris.isPlaying ? "󰏤" : "󰐊"
                        size: 48
                        iconSize: QsTheme.Appearance.typography.headlineSmall.size
                        filled: true
                        onClicked: root.mpris.playPause()
                    }
```

実際のアイコン文字とハンドラは既存コードの該当箇所からそのまま移すこと。
上は形の見本であり、`󰒮` や `mpris.previous()` は既存の記述に合わせて置き換える。

- [ ] **Step 7: `BluetoothPopout` の 3 連コピーを置き換える**

311〜335（Trust）、338〜362（Forget）、365〜412（接続）を `IconButton` 3 個にする。

```qml
                                    IconButton {
                                        size: 26
                                        icon: "󰒃"
                                        iconColor: modelData.trusted ? QsTheme.Theme.accent : QsTheme.Theme.textVariant
                                        borderColor: modelData.trusted ? QsTheme.Theme.accent : QsTheme.Theme.border
                                        onClicked: modelData.trusted = !modelData.trusted
                                    }

                                    IconButton {
                                        size: 26
                                        icon: "󰩹"
                                        iconColor: QsTheme.Theme.textVariant
                                        borderColor: QsTheme.Theme.border
                                        onClicked: modelData.forget()
                                    }

                                    IconButton {
                                        size: 28
                                        icon: modelData.connected ? "󰂲" : "󰂱"
                                        iconColor: QsTheme.Theme.accent
                                        borderColor: QsTheme.Theme.accent
                                        hoverColor: QsTheme.Theme.accentContainer
                                        spinning: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting
                                        onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
                                    }
```

アイコン文字・状態プロパティ・ハンドラは既存の該当行からそのまま移すこと。

144〜192 のスキャンボタンは `TextIconButton` にする。

```qml
                TextIconButton {
                    icon: "󰑐"
                    label: QsBluetooth.Bluetooth.adapter?.discovering ? "Scanning..." : "Scan"
                    spinning: QsBluetooth.Bluetooth.adapter?.discovering ?? false
                    onClicked: QsBluetooth.Bluetooth.setDiscovering(!QsBluetooth.Bluetooth.adapter?.discovering)
                }
```

450〜482 の設定ボタンも `TextIconButton` にする。

```qml
                TextIconButton {
                    icon: "󰒓"
                    label: "Bluetooth Settings"
                    onClicked: settingsProcess.running = true
                }
```

- [ ] **Step 8: `AudioPopout` の設定ボタンを置き換える**

257〜289 を次に置き換える。`BluetoothPopout` とラベル以外同一だったもの。

```qml
                TextIconButton {
                    icon: "󰒓"
                    label: "Sound Settings"
                    onClicked: settingsProcess.running = true
                }
```

- [ ] **Step 9: 通知の閉じるボタンとアクションを置き換える**

`NotificationPopups:647-703` の閉じるボタンを置き換える。
元コードはホバー時に赤くするため内部の `MouseArea` を参照していたが、
`IconButton` の内部は外から見えないので `hoverIconColor` で与える。

```qml
                            IconButton {
                                size: 26
                                icon: "󰅖"
                                iconSize: QsTheme.Appearance.typography.labelMedium.size
                                iconColor: root.m3OnSurfaceVariant
                                hoverIconColor: QsTheme.Theme.error
                                opacity: cardMouse.containsMouse ? 1 : 0
                                onClicked: root.dismiss(modelData)

                                Behavior on opacity {
                                    NumberAnimation { duration: QsTheme.Appearance.anim.durations.fast }
                                }
                            }
```

`NotificationList:253-294` の閉じるボタンも同様。こちらは常時表示なので `opacity` の指定は不要。

`NotificationPopups:798-848` のアクションボタンを `PillButton` にする。

```qml
                                PillButton {
                                    text: modelData.text
                                    hPadding: 22
                                    baseColor: QsTheme.Theme.accentContainer
                                    hoverColor: QsTheme.Theme.accent
                                    textColor: QsTheme.Theme.onAccentContainer
                                    onClicked: modelData.invoke()
                                }
```

`NotificationList:58-92` の Clear All も `PillButton` にする。

```qml
                    PillButton {
                        text: "Clear All"
                        hPadding: 16
                        onClicked: root.notifs.clearAll()
                    }
```

- [ ] **Step 10: ミュートボタンを置き換える**

`VolumeSlider:43-81` と `AppVolumeMixer:72-104` のミュートボタンを `IconButton` にする。

両者に同一の三項式（`isMuted ? "󰝟" : (v > 66 ? "󰕾" : (v > 33 ? "󰖀" : "󰕿"))`）が
あるので、`features/audio/` に置く関数へ切り出す。これは Task 12 で行うため、
ここでは両方に同じ式を残したまま `IconButton` 化だけ行う。

```qml
        IconButton {
            size: 40
            icon: root.isMuted ? "󰝟" : (root.currentVolume > 66 ? "󰕾" : (root.currentVolume > 33 ? "󰖀" : "󰕿"))
            iconSize: QsTheme.Appearance.typography.titleLarge.size
            onClicked: root.audio.toggleMute()
        }
```

- [ ] **Step 11: インライン component が消えたことを確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "component HeaderButton\|component ControlButton" --include='*.qml' .
grep -rc "MouseArea" --include='*.qml' modules/popouts/BluetoothPopout.qml
```

期待: 1 本目は何も出力されない。
2 本目は 2 以下（行ホバー検出用と、残ったリスト操作用のみ）。着手前は 7 だった。

- [ ] **Step 12: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。目視で全ボタンの動作を確認する。

- ヘッダーの電源ボタン（tooltip が出ること）
- MediaCard の前へ / 再生停止 / 次へ
- Bluetooth の Trust / Forget / 接続（接続中に回転すること）
- Bluetooth のスキャン（実行中に回転すること）
- 両ポップアウトの設定ボタン
- 通知トーストの閉じる（ホバーで現れ、ホバー時に赤くなること）
- 通知リストの閉じると Clear All
- 通知のアクションボタン
- 音量とアプリ音量のミュート

- [ ] **Step 13: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): ボタン 12 箇所を IconButton/TextIconButton/PillButton に統合"
```

---

## Task 9: ui/ の構造部品（Surface / FloatingPanel / Slider / Toggle / ListRow / EmptyState / PopoutCard / PopoutHeader）

既存の共有部品を `ui/` へ移し、ポップアウトの完全一致していた 2 構造を抽出する。

**Files:**

- Move: `components/containers/AuroraSurface.qml` → `ui/Surface.qml`
- Move: `components/containers/FloatingPanel.qml` → `ui/FloatingPanel.qml`
- Move: `modules/controlcenter/components/VolumeTrack.qml` → `ui/Slider.qml`
- Move: `modules/controlcenter/components/QuickToggle.qml` → `ui/Toggle.qml`
- Create: `ui/ListRow.qml`, `ui/EmptyState.qml`, `ui/PopoutCard.qml`, `ui/PopoutHeader.qml`
- Delete: `components/containers/qmldir`
- Modify: `ui/qmldir` と参照元

**Interfaces:**

- Consumes: Task 8 の `IconButton` ほか
- Produces:
  - `Surface`（旧 `AuroraSurface`。プロパティ名は変更しない）
  - `FloatingPanel`（変更なし。`panelWidth: int` 必須、default property が中身）
  - `Slider`（旧 `VolumeTrack`。`surfaceColor: color`, `wheelStep: real`, signal `volumeStepped(real newValue)`）
  - `Toggle`（旧 `QuickToggle`。`icon`, `label`, `subLabel`, `active`, `activeColor`, `surfaceColor`, `textColor`, signal `clicked`）
  - `ListRow { icon: string, iconColor: color, title: string, subtitle: string, highlighted: bool, default property alias trailing, signal clicked }`
  - `EmptyState { icon: string, message: string }`
  - `PopoutCard { default property alias content }` — 背景・影・パディングの殻
  - `PopoutHeader { icon: string, title: string, subtitle: string, property alias trailing }`

- [ ] **Step 1: 既存 4 部品を移動する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
git mv components/containers/AuroraSurface.qml ui/Surface.qml
git mv components/containers/FloatingPanel.qml ui/FloatingPanel.qml
git mv modules/controlcenter/components/VolumeTrack.qml ui/Slider.qml
git mv modules/controlcenter/components/QuickToggle.qml ui/Toggle.qml
git rm components/containers/qmldir
rmdir components/containers components 2>/dev/null || true
```

- [ ] **Step 2: `ui/Slider.qml` の自己参照を回避する**

`QtQuick.Controls` の `Slider` を継承した `Slider.qml` は自己参照エラーになる。
import に別名を付けて基底型を明示する。

先頭の import を次に変える。

```qml
import QtQuick.Controls 6.10 as QQC
```

ルート要素を次に変える。

```qml
QQC.Slider {
    id: control
```

- [ ] **Step 3: `ui/PopoutCard.qml` を作る**

`AudioPopout:110-131` と `BluetoothPopout:41-62` が `id` 名まで完全一致していたもの。

```qml
import QtQuick 6.10
import QtQuick.Layouts 6.10
import QtQuick.Effects
import "../theme" as QsTheme

// ポップアウトの背景シェル。両ポップアウトで完全一致していた構造。
Rectangle {
    id: root

    property real cardPadding: 16

    default property alias content: contentColumn.data

    implicitHeight: contentColumn.implicitHeight + root.cardPadding * 2

    color: QsTheme.Theme.panel
    radius: QsTheme.Appearance.radius.m
    border.width: 1
    border.color: QsTheme.Theme.border

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: QsTheme.Theme.shadow
        shadowOpacity: 0.35
        shadowBlur: 1.0
        shadowVerticalOffset: 6
    }

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.cardPadding
        spacing: QsTheme.Appearance.spacing.m
    }
}
```

- [ ] **Step 4: `ui/PopoutHeader.qml` を作る**

`AudioPopout:134-177` と `BluetoothPopout:65-141`。
`BluetoothPopout` だけ右側にトグルを持つので `trailing` スロットを用意する。

```qml
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../theme" as QsTheme

// ポップアウトのヘッダー。右側の trailing は Bluetooth のトグル用スロット。
RowLayout {
    id: root

    property string icon
    property string title
    property string subtitle
    property real iconBoxSize: 36

    default property alias trailing: trailingSlot.data

    Layout.fillWidth: true
    spacing: QsTheme.Appearance.spacing.m

    Rectangle {
        Layout.preferredWidth: root.iconBoxSize
        Layout.preferredHeight: root.iconBoxSize
        radius: QsTheme.Appearance.radius.s
        color: QsTheme.Theme.accentContainer

        IconText {
            anchors.centerIn: parent
            text: root.icon
            size: QsTheme.Appearance.typography.titleMedium.size
            color: QsTheme.Theme.onAccentContainer
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Label {
            Layout.fillWidth: true
            text: root.title
            variant: "body"
            font.weight: Font.Bold
        }

        Label {
            Layout.fillWidth: true
            text: root.subtitle
            variant: "caption"
            muted: true
            visible: root.subtitle !== ""
        }
    }

    Item {
        id: trailingSlot
        Layout.preferredWidth: childrenRect.width
        Layout.preferredHeight: childrenRect.height
        visible: children.length > 0
    }
}
```

`AudioPopout` 側だけサブタイトルに `elide` が付いていた非対称は、
`Label` が既定で `elide: Text.ElideRight` を持つため自動的に揃う。

- [ ] **Step 5: `ui/ListRow.qml` を作る**

`AudioPopout:48-108`（`DeviceRow`）と `BluetoothPopout:211-422`（delegate）の外枠は一致していた。
中身の差（サブタイトル有無・右端のボタン群）を `subtitle` と `trailing` スロットで吸収する。

```qml
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../theme" as QsTheme

// 一覧の 1 行。両ポップアウトのデバイス行を統合。右端は trailing スロット。
Rectangle {
    id: root

    property string icon
    property color iconColor: QsTheme.Theme.text
    property string title
    property string subtitle
    property bool highlighted: false

    default property alias trailing: trailingSlot.data

    signal clicked

    Layout.fillWidth: true
    Layout.preferredHeight: root.subtitle !== "" ? 52 : 44
    radius: QsTheme.Appearance.radius.s
    color: layer.color

    StateLayer {
        id: layer
        hovered: mouse.containsMouse
        hoverColor: QsTheme.Theme.cardHigh
    }

    Behavior on color {
        ColorAnimation {
            duration: QsTheme.Appearance.anim.durations.fast
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: QsTheme.Appearance.margin.m
        anchors.rightMargin: QsTheme.Appearance.margin.m
        spacing: QsTheme.Appearance.spacing.m

        IconText {
            text: root.icon
            size: QsTheme.Appearance.typography.titleMedium.size
            color: root.highlighted ? QsTheme.Theme.accent : root.iconColor
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.title
                variant: "body"
            }

            Label {
                Layout.fillWidth: true
                text: root.subtitle
                variant: "caption"
                muted: true
                visible: root.subtitle !== ""
            }
        }

        Item {
            id: trailingSlot
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
            visible: children.length > 0
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        z: -1
    }
}
```

`z: -1` にしているのは、`trailing` に置いたボタンのクリックを行のクリックが奪わないようにするため
（`BluetoothPopout:416-421` が同じ理由で `z: -1` にしていた）。

- [ ] **Step 6: `ui/EmptyState.qml` を作る**

`AudioPopout:209-218` はアイコンなし、`BluetoothPopout:426-446` はアイコンあり、
`NotificationList:299-328` はアイコンありだった。アイコンありに揃える。

```qml
import QtQuick 6.10
import QtQuick.Layouts 6.10
import "../theme" as QsTheme

// 一覧が空のときの表示。3 箇所でばらばらだった見た目を揃える。
ColumnLayout {
    id: root

    property string icon
    property string message

    spacing: QsTheme.Appearance.spacing.s

    IconText {
        Layout.alignment: Qt.AlignHCenter
        text: root.icon
        size: QsTheme.Appearance.typography.headlineLarge.size
        color: QsTheme.Theme.textVariant
    }

    Label {
        Layout.alignment: Qt.AlignHCenter
        text: root.message
        variant: "label"
        muted: true
    }
}
```

`AudioPopout` の空状態にはアイコンが増える。これは意図した統一。
使うアイコンは `󰓃`（スピーカー）とする。

- [ ] **Step 7: `ui/qmldir` を完成させる**

```
module qs.ui
IconText 1.0 IconText.qml
Label 1.0 Label.qml
Divider 1.0 Divider.qml
StateLayer 1.0 StateLayer.qml
IconButton 1.0 IconButton.qml
TextIconButton 1.0 TextIconButton.qml
PillButton 1.0 PillButton.qml
Surface 1.0 Surface.qml
FloatingPanel 1.0 FloatingPanel.qml
Slider 1.0 Slider.qml
Toggle 1.0 Toggle.qml
ListRow 1.0 ListRow.qml
EmptyState 1.0 EmptyState.qml
PopoutCard 1.0 PopoutCard.qml
PopoutHeader 1.0 PopoutHeader.qml
```

- [ ] **Step 8: 両ポップアウトを新部品で書き直す**

`AudioPopout.qml` の 13〜18 行目の重複プロパティ宣言のうち、
`cardPadding` / `headerIconSize` / `buttonHeight` は各部品が持つので削除する。
`panelWidth` は `FloatingPanel` の必須プロパティなので残す。

110〜131 の背景 Rectangle を `PopoutCard` に、
134〜177 のヘッダーを `PopoutHeader` に、
48〜108 の `component DeviceRow` を `ListRow` に、
209〜218 の空状態を `EmptyState` に、
257〜289 の設定ボタンを Task 8 で `TextIconButton` に置き換え済み。

`BluetoothPopout.qml` も同様に、41〜62 を `PopoutCard`、65〜141 を `PopoutHeader`
（トグルは `trailing` へ）、211〜422 の delegate を `ListRow`（3 ボタンは `trailing` へ）、
426〜446 を `EmptyState` に置き換える。

- [ ] **Step 9: 型名の変更を参照元に反映する**

| 置換前            | 置換後      | 対象                                     |
| ----------------- | ----------- | ---------------------------------------- |
| `AuroraSurface {` | `Surface {` | `ControlCenterWindow.qml`                |
| `QuickToggle {`   | `Toggle {`  | `ControlCenterWindow.qml`（6 箇所）      |
| `VolumeTrack {`   | `Slider {`  | `VolumeSlider.qml`, `AppVolumeMixer.qml` |

`modules/controlcenter/components/qmldir` から次の行を削除する。

```
QuickToggle 1.0 QuickToggle.qml
VolumeTrack 1.0 VolumeTrack.qml
```

- [ ] **Step 10: 参照漏れを確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "AuroraSurface\|VolumeTrack\|QuickToggle\|components/containers\|component DeviceRow" --include='*.qml' --include=qmldir .
```

期待: 何も出力されない。

- [ ] **Step 11: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。特に `Slider is not a type` が出ないこと。

目視で次を確認する。

- audio ポップアウトが開き、出力・入力のデバイス一覧が出て、選択できる
- bluetooth ポップアウトが開き、デバイス一覧と 3 ボタンが出て、トグルが効く
- デバイスが無いとき、両ポップアウトで同じ形の空状態（アイコン + メッセージ）が出る
- Control Center の 6 トグルと音量スライダーが動く

- [ ] **Step 12: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): 構造部品を ui/ に集約しポップアウトの重複を解消"
```

---

## Task 10: 通知の重複解消と実バグ 2 件の修正

トーストとリストで通知 1 件の描画が二重実装になっている。
実装差から生じている挙動の食い違い 2 件も併せて直す。

**Files:**

- Create: `features/notifications/AppIconTile.qml`, `features/notifications/NotifIcon.qml`
- Modify: `modules/notifications/NotificationPopups.qml`
- Modify: `modules/controlcenter/components/NotificationList.qml`

**Interfaces:**

- Consumes: Task 9 の `ui` モジュール
- Produces:
  - `AppIconTile { size: real, iconSize: real, tintColor: color, fallbackGlyph: string, source: string }`
  - `NotifIcon`（シングルトン）: `function resolve(notif): string` — アイコン URL の正規化
  - `NotifIcon.urgencyColor(urgency): color` — 緊急度から色を引く

- [ ] **Step 1: バグ 1 を確認する（アイコン URL 正規化の不一致）**

`NotificationPopups.qml:91-98` と `NotificationList.qml:197-201` を読み比べる。

トースト側は `image://` スキームと `modelData.image` のフォールバックまで扱っているが、
リスト側は `appIcon` に `/` が含まれるかだけを見ており、`file://` の前置がない。
このためリスト側では `image://icon/` 形式のアイコンが表示されない。

再現手順:

```bash
notify-send -i firefox "test" "body"
```

トーストにはアイコンが出るが、Control Center の通知リストには出ないことを確認する。
（出方はアイコンテーマに依存するため、出ない場合は別のアプリ名で試す。）

- [ ] **Step 2: バグ 2 を確認する（通知クリック時の挙動の不一致）**

`NotificationPopups.qml:547-559` は「アクションが 1 つのときだけ実行、複数なら展開」。
`NotificationList.qml:172-177` は「アクションがあれば常に先頭を実行」。

同じ通知をトーストとリストでクリックすると違う結果になる。
リスト側の「複数アクションがあるのに先頭を勝手に実行する」ほうが誤りなので、
トースト側の挙動に揃える。

- [ ] **Step 3: `features/notifications/NotifIcon.qml` を作る**

正規化と緊急度色を 1 箇所に集約する。

```qml
pragma Singleton

import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import "../../theme" as QsTheme

// 通知アイコンの URL 正規化と緊急度の色。
// トーストとリストで実装が分かれてリスト側がアイコンを拾えていなかったため集約した。
Singleton {
    id: root

    function resolve(notif) {
        if (!notif)
            return ""

        const icon = notif.appIcon ?? ""

        if (icon.startsWith("image://") || icon.startsWith("file://"))
            return icon
        if (icon.startsWith("/"))
            return "file://" + icon
        if (icon !== "")
            return "image://icon/" + icon

        return notif.image ?? ""
    }

    function urgencyColor(urgency) {
        switch (urgency) {
        case NotificationUrgency.Critical:
            return QsTheme.Theme.error
        case NotificationUrgency.Low:
            return QsTheme.Theme.textVariant
        default:
            return QsTheme.Theme.accent
        }
    }
}
```

実際の分岐は `NotificationPopups.qml:91-98` の既存ロジックを正として書き写すこと。
上は構造の見本であり、既存が扱っているケースを落とさないよう突き合わせる。

`features/notifications/qmldir` に追加する。

```
singleton NotifIcon NotifIcon.qml
```

- [ ] **Step 4: `features/notifications/AppIconTile.qml` を作る**

`NotificationPopups.qml:582-618` と `NotificationList.qml:186-213` を統合する。

```qml
import QtQuick 6.10
import "../../theme" as QsTheme
import "../../ui"

// 通知のアプリアイコン。読み込み失敗時はフォールバック文字を出す。
Rectangle {
    id: root

    property real size: 34
    property real iconSize: 18
    property color tintColor: QsTheme.Theme.accent
    property string fallbackGlyph: "󰂞"
    property string source: ""

    implicitWidth: root.size
    implicitHeight: root.size
    radius: QsTheme.Appearance.radius.s
    color: root.tintColor
    opacity: 0.12

    Image {
        id: img
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.source
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
    }

    IconText {
        anchors.centerIn: parent
        text: root.fallbackGlyph
        size: root.iconSize
        color: root.tintColor
        visible: !img.visible
    }
}
```

`opacity: 0.12` を Rectangle 全体に掛けると中身のアイコンまで薄くなる。
背景だけを薄くするため、背景用の子 Rectangle に分ける。

```qml
Item {
    id: root

    property real size: 34
    property real iconSize: 18
    property color tintColor: QsTheme.Theme.accent
    property string fallbackGlyph: "󰂞"
    property string source: ""

    implicitWidth: root.size
    implicitHeight: root.size

    Rectangle {
        anchors.fill: parent
        radius: QsTheme.Appearance.radius.s
        color: root.tintColor
        opacity: 0.12
    }

    Image {
        id: img
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.source
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready
    }

    IconText {
        anchors.centerIn: parent
        text: root.fallbackGlyph
        size: root.iconSize
        color: root.tintColor
        visible: !img.visible
    }
}
```

こちらの `Item` 版を採用する。

`features/notifications/qmldir` に追加する。

```
AppIconTile 1.0 AppIconTile.qml
```

- [ ] **Step 5: トースト側を差し替える**

`NotificationPopups.qml:582-618` を次に置き換える。

```qml
                            AppIconTile {
                                size: 34
                                iconSize: 18
                                tintColor: QsNotifications.NotifIcon.urgencyColor(modelData.urgency)
                                fallbackGlyph: "󰂞"
                                source: QsNotifications.NotifIcon.resolve(modelData)
                            }
```

91〜98 のローカルな正規化関数と、40〜44 の `_urgencyColor` 関数を削除する。
削除後、`_urgencyColor` の呼び出し箇所（363, 400, 434, 615）を
`QsNotifications.NotifIcon.urgencyColor(modelData.urgency)` に置き換える。

同じ式が 4 回出るので、カードのルートに 1 つプロパティを置いてまとめる。

```qml
                        readonly property color urgencyColor: QsNotifications.NotifIcon.urgencyColor(modelData.urgency)
```

- [ ] **Step 6: リスト側を差し替える（バグ 1 の修正）**

`NotificationList.qml:186-213` を次に置き換える。

```qml
                            AppIconTile {
                                size: 42
                                iconSize: 24
                                tintColor: QsTheme.Theme.accent
                                fallbackGlyph: "󰂚"
                                source: QsNotifications.NotifIcon.resolve(modelData)
                            }
```

197〜201 のローカルな正規化を削除する。
これでリスト側でも `image://icon/` 形式のアイコンが表示されるようになる。

211 行目の `!parent.children[0].visible` という暗黙参照も、
`AppIconTile` 内部の `img.status` 判定に置き換わって消える。

- [ ] **Step 7: バグ 2 を修正する**

`NotificationList.qml:172-177` のクリック処理を、トースト側の挙動に揃える。

置換前:

```qml
                        onClicked: {
                            if (modelData.actions.length > 0)
                                modelData.actions[0].invoke()
                        }
```

置換後:

```qml
                        // アクションが 1 つのときだけ実行する。複数あるとき勝手に先頭を選ばない。
                        onClicked: {
                            if (modelData.actions.length === 1)
                                modelData.actions[0].invoke()
                        }
```

- [ ] **Step 8: トースト内の退場アニメ重複を統合する**

`NotificationPopups.qml:175-198`（`exitRight`）と `:201-224`（`exitLeft`）は
符号違いのほぼ完全な重複だった。到達点と回転角を property で受ける 1 つにまとめる。

```qml
                    SequentialAnimation {
                        id: exitAnim

                        property int direction: 1

                        ParallelAnimation {
                            NumberAnimation {
                                target: card
                                property: "dragX"
                                to: exitAnim.direction * root.config.notifications.popupWidth
                                duration: QsTheme.Appearance.anim.durations.fast
                                easing.bezierCurve: QsTheme.Appearance.anim.curves.emphasizedAccel
                            }
                            NumberAnimation {
                                target: card
                                property: "rotation"
                                to: exitAnim.direction * 4
                                duration: QsTheme.Appearance.anim.durations.fast
                            }
                            NumberAnimation {
                                target: card
                                property: "opacity"
                                to: 0
                                duration: QsTheme.Appearance.anim.durations.fast
                            }
                        }

                        ScriptAction {
                            script: root.dismiss(modelData)
                        }
                    }
```

既存の 175〜224 の中身（対象プロパティ・duration・easing）を正として書き写すこと。
上は構造の見本。

269〜275 の `swipeDismiss` の左右分岐を次に置き換える。

```qml
                    function swipeDismiss(direction) {
                        exitAnim.direction = direction
                        exitAnim.start()
                    }
```

呼び出し側は `swipeDismiss(1)` / `swipeDismiss(-1)` になる。

- [ ] **Step 9: トースト内の反復式をまとめる**

`:455` と `:459` に同一の一時停止条件がある。カードのルートに 1 つ置く。

```qml
                        readonly property bool paused: card.isHovered || card.isDragging
```

`:493`, `:509`, `:540` に同じ閾値計算がある。同じくルートに置く。

```qml
                        readonly property real dismissThreshold: root.config.notifications.popupWidth * root.swipeThreshold
```

- [ ] **Step 10: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

バグ 1 の修正を確認する。

```bash
notify-send -i firefox "icon test" "body"
```

期待: トーストと Control Center の通知リストの**両方**に同じアイコンが出る。
Step 1 では リスト側に出なかったものが出るようになっていること。

バグ 2 の修正を確認する。

```bash
notify-send -A "yes=Yes" -A "no=No" "action test" "two actions"
```

期待: 通知リストで本体をクリックしても、勝手に "Yes" が実行されない。
アクションが 1 つだけの通知では、クリックで実行されること。

```bash
notify-send -A "ok=OK" "single action" "one action"
```

その他の目視確認:

- 通知トーストを左右にスワイプして消せる（両方向とも）
- スワイプ中にホバーするとタイムアウトが止まる
- 緊急度 critical の通知が赤く出る（`notify-send -u critical "urgent" "body"`）

- [ ] **Step 11: コミット**

```bash
git add -A
git commit -m "fix(quickshell): 通知アイコンの解決とクリック挙動の不一致を修正"
```

---

## Task 11: 色のデータフロー修正（alpha 全廃）

matugen が生成済みのコンテナ色と surface 階調を `Theme` が受け取り、
alpha 合成で作っていた色をすべて実トークン参照に置き換える。

`Qt.rgba` と `withAlpha` はこのタスクで根絶する。
透過が必要な箇所は、色ではなく要素側の `shadowOpacity` / `opacity` で表現する。

文字色は `text`（本文）と `textVariant`（副次）の 2 段のみに統一する。
現在は 6 段（0.5 / 0.55 / 0.6 / 0.7 / 0.72 / 1.0）に散っているが、
M3 の on-surface テキストは `onSurface` と `onSurfaceVariant` の 2 つしか定義がない。

Task 7〜10 で部品が `ui/` と `features/notifications/` に集約されているため、
着手前の 13 ファイルではなく、主に `ui/` の 15 ファイルを直せば済む。

**Files:**

- Modify: `home-manager/desktop/matugen/templates/quickshell-colors.json`（リポジトリルートからのパス）
- Modify: `theme/Colours.qml`
- Modify: `theme/Theme.qml`
- Modify: `ui/*.qml`（15 ファイル）
- Modify: `features/notifications/AppIconTile.qml`
- Modify: 残る呼び出し元（`ControlCenterWindow.qml`, `MediaCard.qml`, `NotificationList.qml`, `NotificationPopups.qml`, 両ポップアウト, `VolumeSlider.qml`, `AppVolumeMixer.qml`）

**Interfaces:**

- Consumes: Task 10 完了状態
- Produces: `Theme` の公開トークン。**alpha 合成関数は持たない。**
  - 面: `background` / `inset` / `panel` / `card` / `cardHigh`
  - コンテナ: `accentContainer` / `secondaryContainer` / `tertiaryContainer` / `errorContainer`
  - 文字: `text` / `textVariant` （**この 2 つのみ**）
  - 文字（色面上）: `onAccent` / `onError` / `onAccentContainer` / `onSecondaryContainer` / `onTertiaryContainer` / `onErrorContainer`
  - 線: `border` / `outline`
  - アクセント: `accent` / `secondary` / `tertiary`
  - 状態: `error` / `warning` / `success` / `info`
  - 効果: `shadow` / `scrim`
  - 関数: `onColor(c)` のみ（`withAlpha` は削除）

- [ ] **Step 1: matugen テンプレートに不足トークンを追加する**

`home-manager/desktop/matugen/templates/quickshell-colors.json` を編集する。
コンテナ色の上に載せる文字色が 3 つ足りないため追加する。

`"secondaryContainer": ...` の行の直後に追加する。

```json
  "onSecondaryContainer": "{{colors.on_secondary_container.default.hex}}",
```

`"tertiaryContainer": ...` の行の直後に追加する。

```json
  "onTertiaryContainer": "{{colors.on_tertiary_container.default.hex}}",
```

`"errorContainer": ...` の行の直後に追加する。

```json
  "onErrorContainer": "{{colors.on_error_container.default.hex}}",
```

追加後、JSON として妥当であることを確認する。

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
sed 's/{{[^}]*}}/"x"/g' home-manager/desktop/matugen/templates/quickshell-colors.json | python3 -m json.tool > /dev/null 2>&1 && echo OK || echo "JSON 不正"
```

`python3` が無い環境では目視で末尾カンマを確認する。

- [ ] **Step 2: テンプレートを反映して実出力を確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#switch
```

壁紙を再適用して matugen を走らせる。

```bash
matugen image "$(find ~/Pictures -type f \( -name '*.jpg' -o -name '*.png' \) | head -1)"
```

新しいキーが出力されたことを確認する。

```bash
grep -oE '"on(Secondary|Tertiary|Error)Container"' ~/.cache/quickshell/matugen-colors.json
```

期待: 3 行すべて出力される。
出力されない場合は matugen がそのキーに対応していないので、作業を止めて報告すること。

- [ ] **Step 3: `theme/Colours.qml` の自作派生を実トークンに差し替える**

`on*` 派生ブロックを見る。`onSurfaceVariant` を `Qt.rgba` で自作しているが、
matugen は実値（例 `#d4c4b5`）を出力している。
`onSurfaceMuted` は M3 に存在しない独自トークンなので削除する。

置換前:

```qml
    // text-on-color（readonly 派生：on* は writable にすると signal-handler 文法に衝突するため）
    readonly property color onPrimary: background
    readonly property color onPrimaryContainer: foreground
    readonly property color onSecondary: background
    readonly property color onTertiary: background
    readonly property color onSurface: foreground
    readonly property color onSurfaceVariant: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.75)
    readonly property color onSurfaceMuted: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.68)
    readonly property color onSuccess: background
    readonly property color onWarning: background
    readonly property color onError: background
```

置換後（すべて matugen の実値を受ける writable プロパティにする）:

```qml
    property color onPrimary: "#462a00"
    property color onPrimaryContainer: "#ffddb7"
    property color onSecondary: "#3f2d17"
    property color onSecondaryContainer: "#f3dec2"
    property color onTertiary: "#263514"
    property color onTertiaryContainer: "#d6e9ba"
    property color onSurface: "#eee0d4"
    property color onSurfaceVariant: "#d4c4b5"
    property color onError: "#690005"
    property color onErrorContainer: "#ffdad6"
    property color onSuccess: "#18120c"
    property color onWarning: "#18120c"
```

元コードのコメントは「`on*` を writable にするとシグナルハンドラ文法に衝突する」と述べているが、
衝突するのは `onXChanged` 形式であり `onPrimary` では起きない。
実際に読み込みエラーが出た場合のみ、`loadColors()` 側で
`root["onPrimary"] = d.onPrimary` の添字代入に切り替える。

- [ ] **Step 4: `loadColors()` に新キーを追加する**

`set(...)` 列挙を次に置き換える。

置換前:

```qml
            set("primary"); set("primaryContainer");
            set("secondary"); set("secondaryContainer");
            set("tertiary"); set("tertiaryContainer");
```

置換後:

```qml
            set("primary"); set("onPrimary");
            set("primaryContainer"); set("onPrimaryContainer");
            set("secondary"); set("onSecondary");
            set("secondaryContainer"); set("onSecondaryContainer");
            set("tertiary"); set("onTertiary");
            set("tertiaryContainer"); set("onTertiaryContainer");
```

置換前:

```qml
            set("outline"); set("outlineVariant");
            set("success"); set("warning"); set("error"); set("errorContainer"); set("info");
```

置換後:

```qml
            set("onSurface"); set("onSurfaceVariant");
            set("outline"); set("outlineVariant");
            set("success"); set("onSuccess");
            set("warning"); set("onWarning");
            set("error"); set("onError");
            set("errorContainer"); set("onErrorContainer");
            set("info");
```

- [ ] **Step 5: `theme/Theme.qml` を全面的に書き換える**

ファイル全体を次の内容で置き換える。`withAlpha` は存在しない。

```qml
pragma Singleton

import Quickshell
import QtQuick

// 意味色トークンの単一定義層。プリミティブ(Colours=matugen)から派生し、全コンポーネントはここだけを参照する。
// alpha 合成はしない。透過が要る箇所は要素側の opacity / shadowOpacity で表す。
Singleton {
    id: root

    readonly property var p: Colours

    // ── Surfaces (elevation 低→高) ──
    readonly property color background: p.background
    readonly property color inset: p.surfaceContainerLow
    readonly property color panel: p.surfaceContainer
    readonly property color card: p.surfaceContainerHigh
    readonly property color cardHigh: p.surfaceContainerHighest

    // ── Containers (アクセント面) ──
    readonly property color accentContainer: p.primaryContainer
    readonly property color secondaryContainer: p.secondaryContainer
    readonly property color tertiaryContainer: p.tertiaryContainer
    readonly property color errorContainer: p.errorContainer

    // ── Text (2 段のみ。3 段目を作らない) ──
    readonly property color text: p.onSurface
    readonly property color textVariant: p.onSurfaceVariant

    // ── Text (色面上) ──
    readonly property color onAccent: p.onPrimary
    readonly property color onError: p.onError
    readonly property color onAccentContainer: p.onPrimaryContainer
    readonly property color onSecondaryContainer: p.onSecondaryContainer
    readonly property color onTertiaryContainer: p.onTertiaryContainer
    readonly property color onErrorContainer: p.onErrorContainer

    // ── Accent ──
    readonly property color accent: p.primary
    readonly property color secondary: p.secondary
    readonly property color tertiary: p.tertiary

    // ── State ──
    readonly property color error: p.error
    readonly property color warning: p.warning
    readonly property color success: p.success
    readonly property color info: p.info

    // ── Lines ──
    readonly property color border: p.outlineVariant
    readonly property color outline: p.outline

    // ── Effects (不透明。濃さは利用側の opacity で与える) ──
    readonly property color shadow: p.shadow
    readonly property color scrim: p.scrim

    // 任意のアクセント色上の可読な前景色 (輝度で自動コントラスト)
    function onColor(c) {
        return (0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b) > 0.55 ? Qt.rgba(0.05, 0.06, 0.08, 1) : Qt.rgba(1, 1, 1, 1)
    }
}
```

`onColor` の中の `Qt.rgba` は、色を合成しているのではなく不透明な黒と白を作っているだけなので残す。
第 4 引数は常に 1 で、透過は生じない。

- [ ] **Step 6: 置換表に従って全ファイルを直す**

`QsTheme.` 接頭辞が付いている場合はそれを保つ。

面と state layer:

| 置換前                              | 置換後           |
| ----------------------------------- | ---------------- |
| `Theme.withAlpha(Theme.text, 0.06)` | `Theme.card`     |
| `Theme.withAlpha(Theme.text, 0.08)` | `Theme.card`     |
| `Theme.withAlpha(Theme.text, 0.1)`  | `Theme.cardHigh` |
| `Theme.withAlpha(Theme.text, 0.12)` | `Theme.cardHigh` |
| `Theme.hover`                       | `Theme.cardHigh` |
| `Qt.rgba(1, 1, 1, 0.05)`            | `Theme.card`     |
| `Qt.rgba(1, 1, 1, 0.15)`            | `Theme.cardHigh` |

線:

| 置換前                                | 置換後          |
| ------------------------------------- | --------------- |
| `Theme.withAlpha(Theme.text, 0.15)`   | `Theme.border`  |
| `Theme.withAlpha(Theme.text, 0.2)`    | `Theme.border`  |
| `Theme.withAlpha(Theme.text, 0.3)`    | `Theme.outline` |
| `Theme.withAlpha(Theme.outline, 0.7)` | `Theme.outline` |
| `Theme.borderFaint`                   | `Theme.border`  |

文字（2 段に畳む）:

| 置換前                              | 置換後              |
| ----------------------------------- | ------------------- |
| `Theme.withAlpha(Theme.text, 0.4)`  | `Theme.textVariant` |
| `Theme.withAlpha(Theme.text, 0.5)`  | `Theme.textVariant` |
| `Theme.withAlpha(Theme.text, 0.55)` | `Theme.textVariant` |
| `Theme.withAlpha(Theme.text, 0.6)`  | `Theme.textVariant` |
| `Theme.withAlpha(Theme.text, 0.7)`  | `Theme.textVariant` |
| `Theme.withAlpha(Theme.text, 0.72)` | `Theme.textVariant` |
| `Theme.textMuted`                   | `Theme.textVariant` |
| `Theme.textDim`                     | `Theme.textVariant` |

コンテナ:

| 置換前                                 | 置換後                    |
| -------------------------------------- | ------------------------- |
| `Theme.withAlpha(Theme.accent, 0.15)`  | `Theme.accentContainer`   |
| `Theme.withAlpha(Theme.error, 0.1)`    | `Theme.errorContainer`    |
| `Theme.withAlpha(Theme.error, 0.15)`   | `Theme.errorContainer`    |
| `Theme.withAlpha(Theme.tertiary, 0.2)` | `Theme.tertiaryContainer` |

`Theme.textMuted` / `Theme.textDim` / `Theme.borderFaint` / `Theme.hover` は
Step 5 の新 `Theme.qml` に存在しないため、置換漏れがあればビルド時に検知できる。

- [ ] **Step 7: `ui/Toggle.qml` のハードコード色と自前輝度計算を除去する**

旧 `QuickToggle` のデフォルト値をリテラルから Theme トークンに変える。

置換前:

```qml
    property color activeColor: "#a6e3a1"
    property color surfaceColor: Qt.rgba(0.15, 0.15, 0.18, 1)
    property color textColor: "#e6e6e6"
```

置換後:

```qml
    property color activeColor: QsTheme.Theme.accent
    property color surfaceColor: QsTheme.Theme.card
    property color textColor: QsTheme.Theme.text
```

`onActiveColor` の自前輝度計算を `Theme.onColor` に委譲する。
元は 2 行にまたがる三項演算子なので、続く行ごと次の 1 行に差し替える。

```qml
    readonly property color onActiveColor: QsTheme.Theme.onColor(root.activeColor)
```

同ファイル内に `onActiveColor` を `Qt.rgba(..., 0.78)` / `0.16` / `0.10` で薄めている箇所が
3 箇所ある。これらは「アクティブ面の上の副次要素」なので、
色はそのまま使い、薄さは要素の `opacity` で与える。

置換前:

```qml
                color: Qt.rgba(root.onActiveColor.r, root.onActiveColor.g, root.onActiveColor.b, 0.78)
```

置換後:

```qml
                color: root.onActiveColor
                opacity: 0.78
```

- [ ] **Step 8: `ControlCenterWindow` の Toggle 呼び出しを簡素化する**

`Toggle` の既定値が Theme から来るようになったので、6 箇所すべてで
次の 2 行が不要になる（`surfaceColor` と `textColor` は全 6 個で同一値だった）。

削除する行:

```qml
                        surfaceColor: QsConfig.Theme.card
                        textColor: QsConfig.Theme.text
```

`activeColor` は Caffeine が `Theme.info`、Screenshot と Record が
`Theme.secondary` / `Theme.error` と異なるので残す。
既定の `Theme.accent` と同じ値になる Wi-Fi / Bluetooth / DND の 3 箇所は削除してよい。

- [ ] **Step 9: `MediaCard` のスクリムを opacity に分離する**

アルバムアート上の覆いを、色の alpha ではなく要素の `opacity` で表す。

置換前:

```qml
        color: QsTheme.Theme.withAlpha(QsTheme.Theme.background, 0.4)
```

置換後:

```qml
        color: QsTheme.Theme.scrim
        opacity: 0.4
```

同ファイルの `textDim` 中継も直す。

置換前:

```qml
    readonly property color textDim: QsTheme.Theme.withAlpha(QsTheme.Theme.text, 0.7)
```

置換後:

```qml
    readonly property color textDim: QsTheme.Theme.textVariant
```

- [ ] **Step 10: 影を shadowOpacity に統一する**

`Qt.rgba` で影の濃さを作っている箇所をすべて `shadowOpacity` に分離する。

対象は `ui/Surface.qml`、`ui/PopoutCard.qml`（Task 9 で作成済み。既に対応）、
`NotificationPopups.qml` の独自影、`MediaCard.qml` のテキスト影 2 箇所。

置換前の形:

```qml
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: Qt.rgba(0, 0, 0, 0.18)
                            shadowBlur: 0.4
                            shadowVerticalOffset: 4
                        }
```

置換後:

```qml
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: QsTheme.Theme.shadow
                            shadowOpacity: 0.18
                            shadowBlur: 0.4
                            shadowVerticalOffset: 4
                        }
```

`MediaCard.qml` のテキスト影 2 箇所は同一値の連続コピーなので、
片方を消して共通の値にできるか確認する。できない場合は両方とも上の形に直す。

- [ ] **Step 11: alpha が根絶されたことを検証する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
echo "--- withAlpha の残存 ---"
grep -rn "withAlpha" --include='*.qml' .
echo "--- Qt.rgba の残存 ---"
grep -rn "Qt\.rgba" --include='*.qml' .
echo "--- 色リテラルの残存 ---"
grep -rnE '"#[0-9a-fA-F]{3,8}"' --include='*.qml' .
echo "--- 削除したトークンへの参照 ---"
grep -rnE "Theme\.(textMuted|textDim|borderFaint|hover)" --include='*.qml' .
```

期待:

- 1 本目は何も出力されない
- 2 本目は `theme/Theme.qml` の `onColor` 内 2 箇所のみ（どちらも第 4 引数が `1`）
- 3 本目は `theme/Colours.qml` のフォールバック値のみ
- 4 本目は何も出力されない

これ以外が残っていたら、Step 6 の表に追記して置換する。
表に該当が無い新しい組み合わせが出た場合は、面なら surface 階調、文字なら `textVariant`、
アクセント面ならコンテナ色に寄せる。判断が付かない場合は作業を止めて報告すること。

- [ ] **Step 12: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。特に `Unable to assign [undefined] to QColor` が出ないこと。
出た場合は matugen の新キーが読めていないので Step 2 に戻る。

目視で次を確認する。

- Control Center の各カードに色が付いており、文字が読める
- Toggle の ON 状態が matugen のアクセント色になっている
- ホバー時に面が一段明るくなる（`card` → `cardHigh`）
- 通知トーストの枠線と本文の階調が破綻していない
- MediaCard のアルバムアート上の文字が読める（スクリムが効いている）
- 影が黒板ではなく影として出ている
- 壁紙を変えて `qs -c shell ipc call theme reload` を呼ぶと、コンテナ色も追従する

**この時点で見た目は変わる。** 主な変化は 3 つで、いずれも意図したもの。

1. トグルの ON 状態とエラー表示の彩度が上がる（alpha 合成 → コンテナ色）
2. 副次テキストが 1 段に統一され、以前より濃くなる箇所がある
3. ホバーの面が透過ではなく不透明な一段明るい面になる

濃すぎる・薄すぎる場合は `Theme.qml` の割当だけを直す。
個別のコンポーネントに `opacity` や色を足して調整してはいけない。
（`opacity` を使ってよいのは Step 7 / 9 で明示した箇所と、`AppIconTile` の背景だけ。）

- [ ] **Step 13: コミット**

```bash
git add -A
git commit -m "fix(quickshell): 色から alpha 合成を排し matugen トークンに一本化"
```

---

## Task 12: features/ への再編

サービスと、その機能固有の UI を同居させる。`services/` 層は消える。

**Files:**

- Create: `features/{audio,bluetooth,media,network,notifications,power,screenshot}/qmldir`
- Move: 各サービスと機能固有コンポーネント
- Delete: `services/qmldir`, `modules/controlcenter/components/qmldir`
- Modify: 参照元の import

**Interfaces:**

- Consumes: Task 11 完了状態
- Produces: 各 feature が独立したモジュールとして自分のサービスと UI を公開する
  - `features/audio`: `Audio`, `AudioStreams`, `AudioIcon`（シングルトン）、`VolumeRow`, `AppVolumeMixer`（型）
  - `features/bluetooth`: `Bluetooth`
  - `features/media`: `Players`, `MediaCard`
  - `features/network`: `Network`
  - `features/notifications`: `Notifs`, `NotifIcon`, `NotificationList`, `AppIconTile`
  - `features/power`: `IdleInhibitor`
  - `features/screenshot`: `Screenshot`

- [ ] **Step 1: ディレクトリを作ってファイルを移動する**

`VolumeSlider` は「デバイス音量の 1 行」なので `VolumeRow` に改名する。
`ui/Slider.qml`（汎用スライダー）との役割の違いを名前で示すため。

`features/notifications/` は Task 10 で既に作成済みなので、そこへ追加で移動する。

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
mkdir -p features/{audio,bluetooth,media,network,power,screenshot}

git mv services/Audio.qml features/audio/Audio.qml
git mv services/AudioStreams.qml features/audio/AudioStreams.qml
git mv modules/controlcenter/components/VolumeSlider.qml features/audio/VolumeRow.qml
git mv modules/controlcenter/components/AppVolumeMixer.qml features/audio/AppVolumeMixer.qml

git mv services/Bluetooth.qml features/bluetooth/Bluetooth.qml

git mv services/Players.qml features/media/Players.qml
git mv modules/controlcenter/components/MediaCard.qml features/media/MediaCard.qml

git mv services/Network.qml features/network/Network.qml

git mv services/Notifs.qml features/notifications/Notifs.qml
git mv modules/controlcenter/components/NotificationList.qml features/notifications/NotificationList.qml

git mv services/IdleInhibitor.qml features/power/IdleInhibitor.qml
git mv services/Screenshot.qml features/screenshot/Screenshot.qml

git rm services/qmldir modules/controlcenter/components/qmldir
```

- [ ] **Step 2: 音量アイコンの三項式を関数に切り出す**

`VolumeRow.qml` と `AppVolumeMixer.qml` に同一の三項式がある。

```qml
root.isMuted ? "󰝟" : (root.currentVolume > 66 ? "󰕾" : (root.currentVolume > 33 ? "󰖀" : "󰕿"))
```

`features/audio/AudioIcon.qml` を作る。

```qml
pragma Singleton

import Quickshell
import QtQuick

// 音量アイコンの選択。VolumeRow と AppVolumeMixer で同一式が重複していたため集約した。
Singleton {
    function forVolume(percentage, muted) {
        if (muted)
            return "󰝟"
        if (percentage > 66)
            return "󰕾"
        if (percentage > 33)
            return "󰖀"
        return "󰕿"
    }
}
```

両ファイルの三項式を次に置き換える。

```qml
            icon: AudioIcon.forVolume(root.currentVolume, root.isMuted)
```

- [ ] **Step 3: 各 feature の qmldir を作る**

`features/audio/qmldir`:

```
module qs.features.audio
singleton Audio Audio.qml
singleton AudioStreams AudioStreams.qml
singleton AudioIcon AudioIcon.qml
VolumeRow 1.0 VolumeRow.qml
AppVolumeMixer 1.0 AppVolumeMixer.qml
```

`features/bluetooth/qmldir`:

```
module qs.features.bluetooth
singleton Bluetooth Bluetooth.qml
```

`features/media/qmldir`:

```
module qs.features.media
singleton Players Players.qml
MediaCard 1.0 MediaCard.qml
```

`features/network/qmldir`:

```
module qs.features.network
singleton Network Network.qml
```

`features/notifications/qmldir`（Task 10 で作った 2 行に追加）:

```
module qs.features.notifications
singleton Notifs Notifs.qml
singleton NotifIcon NotifIcon.qml
NotificationList 1.0 NotificationList.qml
AppIconTile 1.0 AppIconTile.qml
```

`features/power/qmldir`:

```
module qs.features.power
singleton IdleInhibitor IdleInhibitor.qml
```

`features/screenshot/qmldir`:

```
module qs.features.screenshot
singleton Screenshot Screenshot.qml
```

- [ ] **Step 4: 移動したファイルの import を直す**

`features/<name>/` はルートから 2 階層下なので、theme と ui と utils は `../../` で参照する。

```qml
import "../../theme" as QsTheme
import "../../ui"
import "../../utils" as QsUtils
import "../../config" as QsConfig
```

各ファイルで実際に使っているものだけ書く。

`features/audio/AppVolumeMixer.qml` は `AudioStreams` を同じディレクトリから参照するので、
`import "../../services" as QsServices` を削除し、`QsServices.AudioStreams` を
`AudioStreams` に直す。

`features/media/MediaCard.qml` と `features/notifications/NotificationList.qml` は
サービスを property 経由で受け取っているため、import の削除のみでよい。

- [ ] **Step 5: `ControlCenterWindow.qml` の参照を直す**

import を次に置き換える。

```qml
import "../../ui"
import "../../theme" as QsTheme
import "../../config" as QsConfig
import "../../utils" as QsUtils
import "../../features/audio" as QsAudio
import "../../features/bluetooth" as QsBluetooth
import "../../features/media" as QsMedia
import "../../features/network" as QsNetwork
import "../../features/notifications" as QsNotifications
import "../../features/power" as QsPower
import "../../features/screenshot" as QsScreenshot
```

削除する行:

```qml
import "../../services" as QsServices
import "components"
```

サービス参照のプロパティを次に置き換える。

```qml
    readonly property var network: QsNetwork.Network
    readonly property var bluetooth: QsBluetooth.Bluetooth
    readonly property var audio: QsAudio.Audio
    readonly property var mpris: QsMedia.Players
    readonly property var notifs: QsNotifications.Notifs
    readonly property var screenshot: QsScreenshot.Screenshot
    readonly property var idleInhibitor: QsPower.IdleInhibitor
```

型の利用箇所を修飾付きに直す。

| 置換前               | 置換後                               |
| -------------------- | ------------------------------------ |
| `VolumeSlider {`     | `QsAudio.VolumeRow {`                |
| `AppVolumeMixer {`   | `QsAudio.AppVolumeMixer {`           |
| `MediaCard {`        | `QsMedia.MediaCard {`                |
| `NotificationList {` | `QsNotifications.NotificationList {` |

- [ ] **Step 6: `shell.qml` と残りの参照元を直す**

`shell.qml` の import を次に置き換える。

```qml
import "theme" as QsTheme
import "config" as QsConfig
import "features/notifications" as QsNotifications
import "features/power" as QsPower
import "modules/controlcenter"
import "modules/popouts"
```

削除する行:

```qml
import "services" as QsServices
```

本文の置換:

| 置換前                        | 置換後                     |
| ----------------------------- | -------------------------- |
| `QsServices.Notifs`           | `QsNotifications.Notifs`   |
| `QsServices.Colours.reload()` | `QsTheme.Colours.reload()` |
| `QsServices.IdleInhibitor`    | `QsPower.IdleInhibitor`    |

`modules/notifications/NotificationPopups.qml` の import:

```qml
import "../../features/notifications" as QsNotifications
import "../../theme" as QsTheme
import "../../ui"
```

`QsServices.Notifs` を `QsNotifications.Notifs` に置換する。

`modules/popouts/BluetoothPopout.qml` の import:

```qml
import "../../features/bluetooth" as QsBluetooth
```

`QsServices.Bluetooth` を `QsBluetooth.Bluetooth` に置換する。

`modules/popouts/AudioPopout.qml` は Pipewire を直接見ているが、
Task 5 で `Audio` サービスが Pipewire バインディングになったため、
デバイス一覧の取得も `features/audio/Audio.qml` に寄せられる。
ただし今回は移動のみとし、統合は積み残しとする。

- [ ] **Step 7: 参照漏れを確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "QsServices\|\"services\"\|/services\|VolumeSlider" --include='*.qml' --include=qmldir .
ls services 2>&1
```

期待: 1 本目は何も出力されない。2 本目は `No such file or directory`。

- [ ] **Step 8: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。目視で全機能を確認する。

- Control Center の 6 トグルすべて
- 音量スライダーとアプリ音量ミキサーの展開（アイコンが音量に応じて変わること）
- MediaCard の再生制御
- 通知リストの表示と削除
- audio / bluetooth ポップアウト
- 通知トーストの表示（`notify-send test body`）

- [ ] **Step 9: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): サービスと機能 UI を features/ へ同居"
```

---

## Task 13: windows/ の確立

PanelWindow を `windows/` へ集め、`modules/` を廃止する。

**Files:**

- Move: `modules/controlcenter/ControlCenterWindow.qml` → `windows/ControlCenterWindow.qml`
- Move: `modules/popouts/AudioPopout.qml` → `windows/AudioPopout.qml`
- Move: `modules/popouts/BluetoothPopout.qml` → `windows/BluetoothPopout.qml`
- Move: `modules/notifications/NotificationPopups.qml` → `windows/NotificationToasts.qml`
- Create: `windows/qmldir`
- Modify: `shell.qml`

**Interfaces:**

- Consumes: Task 12 の features モジュール群
- Produces: `windows` モジュールが `ControlCenterWindow`, `AudioPopout`, `BluetoothPopout`, `NotificationToasts` を公開する

- [ ] **Step 1: ファイルを移動する**

`NotificationPopups` は `NotificationToasts` に改名する。
`features/notifications/NotificationList`（CC 内のリスト）との役割の違いを名前で示すため。

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
mkdir -p windows
git mv modules/controlcenter/ControlCenterWindow.qml windows/ControlCenterWindow.qml
git mv modules/popouts/AudioPopout.qml windows/AudioPopout.qml
git mv modules/popouts/BluetoothPopout.qml windows/BluetoothPopout.qml
git mv modules/notifications/NotificationPopups.qml windows/NotificationToasts.qml
rmdir modules/controlcenter/components modules/controlcenter modules/popouts modules/notifications modules 2>/dev/null || true
```

- [ ] **Step 2: `windows/qmldir` を作る**

```
module qs.windows
ControlCenterWindow 1.0 ControlCenterWindow.qml
AudioPopout 1.0 AudioPopout.qml
BluetoothPopout 1.0 BluetoothPopout.qml
NotificationToasts 1.0 NotificationToasts.qml
```

- [ ] **Step 3: 移動した 4 ファイルの import を 1 階層分浅くする**

`windows/` はルート直下なので、すべての相対パスが `../../` から `../` になる。

```qml
import "../ui"
import "../theme" as QsTheme
import "../config" as QsConfig
import "../utils" as QsUtils
import "../features/audio" as QsAudio
import "../features/bluetooth" as QsBluetooth
import "../features/media" as QsMedia
import "../features/network" as QsNetwork
import "../features/notifications" as QsNotifications
import "../features/power" as QsPower
import "../features/screenshot" as QsScreenshot
```

各ファイルで実際に使っているものだけ書く。

- [ ] **Step 4: `shell.qml` を更新する**

import を次に置き換える。

```qml
import "theme" as QsTheme
import "config" as QsConfig
import "features/notifications" as QsNotifications
import "features/power" as QsPower
import "windows"
```

削除する行:

```qml
import "modules/controlcenter"
import "modules/popouts"
```

トーストの Loader を、改名後のパスに直す。

置換前:

```qml
    Loader {
        source: "modules/notifications/NotificationPopups.qml"
    }
```

置換後:

```qml
    Loader {
        source: "windows/NotificationToasts.qml"
    }
```

- [ ] **Step 5: 参照漏れを確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -rn "modules/\|NotificationPopups" --include='*.qml' --include=qmldir .
ls modules 2>&1
find . -type d | sort
```

期待: 1 本目は何も出力されない。2 本目は `No such file or directory`。
3 本目は次の通り。

```
.
./config
./features
./features/audio
./features/bluetooth
./features/media
./features/network
./features/notifications
./features/power
./features/screenshot
./theme
./ui
./utils
./windows
```

- [ ] **Step 6: 検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change
nix run .#build
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell --since "10 seconds ago" --no-pager
```

期待: エラーなし。Task 12 Step 8 と同じ全機能の目視確認を行う。

IPC も全経路を確認する。

```bash
qs -c shell ipc call cc toggle
qs -c shell ipc call cc toggle
qs -c shell ipc call audio toggle
qs -c shell ipc call audio toggle
qs -c shell ipc call bluetooth toggle
qs -c shell ipc call bluetooth toggle
qs -c shell ipc call theme reload
qs -c shell ipc call idle toggle
qs -c shell ipc call idle toggle
qs -c shell ipc call cc status
```

期待: すべてエラーなく実行され、`cc status` が JSON を返す。

- [ ] **Step 7: コミット**

```bash
git add -A
git commit -m "refactor(quickshell): PanelWindow を windows/ へ集約し modules/ を廃止"
```

---

## Task 14: README 更新と最終検証

**Files:**

- Modify: `shell/README.md`

**Interfaces:**

- Consumes: Task 13 完了状態
- Produces: なし

- [ ] **Step 1: `shell/README.md` の構成図を差し替える**

「## 構成」節のコードブロックを次に置き換える。

```
shell.qml        エントリポイント。ウィンドウの組み立てと IPC 配線のみ
config/          Config(shell.json 読込)。最下層
theme/           Colours(matugen読込) / Theme(意味色) / Appearance(寸法・タイポ・モーション)
ui/              ヘッドレス部品。Label / IconText / IconButton / ListRow / Surface ほか
features/        機能単位。状態(サービス)とその機能固有 UI を同居
windows/         PanelWindow。features を並べる器
utils/           純粋ヘルパー（Logger）
```

「## 設計ルール」節に次の 3 項目を追加する。

```markdown
- 依存は `windows → features → ui → theme → config` の一方向。features どうしは参照しない。
- 色に alpha を埋め込まない。`Qt.rgba` と alpha 合成は禁止で、matugen の実トークンをそのまま使う。
  透過が要る箇所は要素側の `opacity` / `MultiEffect.shadowOpacity` で表す。
- 文字色は `Theme.text` と `Theme.textVariant` の 2 段のみ。3 段目を作らない。
```

- [ ] **Step 2: 削除した機能の記述を消す**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
grep -n "SystemUsage\|Brightness\|PowerProfiles\|Lock\|Captures" README.md
```

該当があれば削除する。
「スクリーンショットと録画の実装は `hyprland/scripts/{screenshot,record}.sh` が正」の行は
Screenshot サービスが残るので削除しない。

- [ ] **Step 3: 最終の全体検証**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles
nix run .#fmt -- --fail-on-change
nix run .#build
systemctl --user restart quickshell && sleep 5
journalctl --user -u quickshell --since "20 seconds ago" --no-pager
```

- [ ] **Step 4: 常時プロセス生成が止まったことを確認する**

```bash
for i in $(seq 1 15); do
  printf "%s wpctl=%s sh=%s nvidia=%s\n" "$i" \
    "$(pgrep -c wpctl || echo 0)" \
    "$(pgrep -cf 'sh -c cat /proc' || echo 0)" \
    "$(pgrep -c nvidia-smi || echo 0)"
  sleep 1
done
```

期待: 15 行すべて `wpctl=0 sh=0 nvidia=0`。
`nmcli` は Network が 10 秒間隔で残しているため、これのみ断続的に現れてよい。

- [ ] **Step 5: 規約違反が残っていないことを確認する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
echo "--- alpha 合成 ---"; grep -rn "withAlpha" --include='*.qml' .
echo "--- Qt.rgba（onColor 内 2 件のみ可）---"; grep -rn "Qt\.rgba" --include='*.qml' .
echo "--- インライン component（データ型は可）---"; grep -rn "^\s*component " --include='*.qml' .
echo "--- 削除済みトークン ---"; grep -rnE "Theme\.(textMuted|textDim|borderFaint|hover)" --include='*.qml' .
echo "--- 旧モジュール参照 ---"; grep -rn "QsServices\|modules/\|Material3Anim\|Elevation" --include='*.qml' .
```

期待:

- alpha 合成: 出力なし
- `Qt.rgba`: `theme/Theme.qml` の 2 件のみ
- インライン component: `features/network/Network.qml` の `AccessPoint` と
  `features/notifications/Notifs.qml` の `Notif` のみ（どちらも `QtObject` のデータ型なので可）
- 削除済みトークン: 出力なし
- 旧モジュール参照: 出力なし

- [ ] **Step 6: 削減量を記録する**

```bash
cd /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/quickshell/shell
find . -name '*.qml' | xargs wc -l | tail -1
find . -name '*.qml' | wc -l
```

着手前は 7940 行 / 29 ファイル。
期待: 4300〜4800 行。ファイル数は部品抽出で増えて 40 前後。

行数が 5500 を超えている場合は削除漏れか置換漏れがあるので、Step 5 の検査を見直す。

- [ ] **Step 7: コミット**

```bash
git add -A
git commit -m "docs(quickshell): README を新構成に更新"
```

---

## 積み残し（この計画では扱わない）

- `Network.qml`（287 行）の nmcli ポーリング。`nmcli m`（monitor）によるイベント駆動化の余地があるが、
  代替 API が無く 10 秒間隔で影響も小さいため今回は据え置く。
- `windows/AudioPopout.qml` の Pipewire 直接参照。Task 5 で `Audio` サービスが
  Pipewire バインディングになったので統合できるが、デバイス一覧の取得は
  ポップアウト固有のため今回は移動のみとした。
- `windows/NotificationToasts.qml` の残り行数。Task 10 で重複は解消したが、
  スタック配置・進捗バー・スワイプ処理は 1 箇所でしか使わないため分割していない。
- `features/notifications/NotifCard.qml` によるトーストとリストの完全統合。
  Task 10 で `AppIconTile` と `NotifIcon` は共通化したが、カード全体の統合は
  レイアウトの差（メタ情報の位置、進捗バーの有無）が大きいため見送った。
- `ui/Toggle.qml` の `Repeater` 化。`ControlCenterWindow` の 6 個の Toggle は
  model 駆動にできるが、`activeColor` と `onClicked` が個別なので効果が薄い。
