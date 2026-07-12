# quickshell 大規模リファクタリング実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** quickshell の 3 設定（shell/audio/bluetooth、約 23,000 行）を、生存コードのみの単一設定（約 7,000 行、caelestia 構造）へ移植する。

**Architecture:** 死蔵コードの削除 → audio/bluetooth のポップアウト統合 → 色レイヤの Colours 改名と Theme 統一 → utils/components 再編 → Appearance トークン一本化と全面適用 → 空リスト対策 → Screenshot 縮小、の順で段階コミットする。仕様は `docs/superpowers/specs/2026-07-12-quickshell-refactor-design.md`。

**Tech Stack:** QML (Quickshell), Nix (home-manager), matugen, waybar

## Global Constraints

- 作業ディレクトリ: `home-manager/desktop/quickshell/`（リポジトリ: `/home/mkiin/ghq/github.com/mkiin/dotfiles`）。以下の相対パスはすべて quickshell ディレクトリ基準。
- QML は `lnk`（out-of-store symlink）で配線されているため、QML のみの変更は `systemctl --user restart quickshell` で反映される。`default.nix`, `waybar/modules.nix`, `matugen/config.toml`, `shell.json` の変更は `nix run .#switch` が必要。
- QML に自動テストは無い。各タスクの検証プロトコルは次の 3 点：(1) `nix run .#fmt -- --fail-on-change` が通る、(2) Nix を触ったタスクは `nix run .#build` が通る、(3) `systemctl --user restart quickshell && sleep 3 && journalctl --user -u quickshell -n 80 --no-pager | grep -iE 'error|warning'` の出力が 0 件。
- サイズ語彙は xs / s / m / l / xl / full に統一する。tiny / small / medium / large / huge / extraLarge は残さない。
- コメントは「なぜ」だけを 1〜2 行。逐条コメント禁止。パッケージ宣言の追加は無い（既存 `programs`/`services` 機構のみ）。
- 各タスク末に必ずコミットする。リポジトリには別作業（fastfetch）が staged で残っているため、コミットは**必ずパス指定**（`git commit -m "..." -- <paths>`）で行い、`git add` も対象パスのみ指定する。

---

### Task 1: 死蔵コード削除と通知モジュールの昇格

**Files:**

- Move: `shell/modules/bar/components/NotificationPopups.qml` → `shell/modules/notifications/NotificationPopups.qml`
- Modify: `shell/shell.qml`, `shell/services/qmldir`, `shell/components/qmldir`
- Delete: `shell/modules/bar/`, `shell/modules/sidebar/`, `shell/modules/dashboard/`, `shell/modules/osd/`, `shell/modules/BatteryMonitor.qml`, `shell/modules/qmldir`, 死蔵 services、死蔵 components

**Interfaces:**

- Produces: 通知トーストの新パス `modules/notifications/NotificationPopups.qml`（Task 3, 5 が参照）。生存 services 13 個と生存 components 3 個（AuroraSurface, Elevation, effects/Material3Anim）。

- [ ] **Step 1: 生存集合を確定する参照解析**

事前調査で確定済みの生存集合は次のとおり。削除前に下のコマンドで反証が無いことを確認する。

- 生存 modules: `modules/controlcenter/` 全部, `modules/bar/components/NotificationPopups.qml`
- 生存 services: Audio, AudioStreams, Bluetooth, Brightness, IdleInhibitor, Logger, Network, Notifs, Players, PowerProfiles, Pywal, Screenshot, SystemUsage
- 死蔵 services: Time, Hypr, LauncherUsage, GamingMode, UIState, Settings
- 生存 components: AuroraSurface, Elevation, effects/Material3Anim
- 死蔵 components: Anim, IconButton, Material3Popup, NetworkGraph, PopupButton, StateLayer, StyledFlickable, StyledListView, SwipeGesture, effects/RippleEffect

```bash
cd home-manager/desktop/quickshell/shell
# 死蔵候補が生存側から参照されていないこと（ヒット 0 件が期待値）
grep -rnE 'QsServices\.(Time|Hypr|LauncherUsage|GamingMode|UIState|Settings)\b' \
  shell.qml modules/controlcenter modules/bar/components/NotificationPopups.qml \
  services/{Audio,AudioStreams,Bluetooth,Brightness,IdleInhibitor,Logger,Network,Notifs,Players,PowerProfiles,Pywal,Screenshot,SystemUsage}.qml \
  components/AuroraSurface.qml components/Elevation.qml components/effects/Material3Anim.qml
grep -rnE '\b(Anim|IconButton|Material3Popup|NetworkGraph|PopupButton|StateLayer|StyledFlickable|StyledListView|SwipeGesture|RippleEffect)\s*\{' \
  shell.qml modules/controlcenter modules/bar/components/NotificationPopups.qml \
  components/AuroraSurface.qml components/Elevation.qml components/effects/Material3Anim.qml
```

ヒットした場合、その参照先は生存側へ移し、削除対象から外す（削除リストを実態に合わせて縮める。追加の死蔵化はしない）。

- [ ] **Step 2: 通知トーストを modules/notifications/ へ移動**

```bash
mkdir -p modules/notifications
git mv modules/bar/components/NotificationPopups.qml modules/notifications/NotificationPopups.qml
```

移動後、ファイル内の相対 import の深さを 1 段浅くする：

```
import "../../../services" as QsServices  →  import "../../services" as QsServices
import "../../../config" as QsConfig      →  import "../../config" as QsConfig
```

- [ ] **Step 3: shell.qml の Loader パスを更新**

```qml
// 変更前
Loader {
    source: "modules/bar/components/NotificationPopups.qml"
}
// 変更後
Loader {
    source: "modules/notifications/NotificationPopups.qml"
}
```

- [ ] **Step 4: 死蔵コードを削除**

```bash
git rm -r modules/bar modules/sidebar modules/dashboard modules/osd
git rm modules/BatteryMonitor.qml modules/qmldir
git rm services/{Time,Hypr,LauncherUsage,GamingMode,UIState,Settings}.qml
git rm components/{Anim,IconButton,Material3Popup,NetworkGraph,PopupButton,StateLayer,StyledFlickable,StyledListView,SwipeGesture}.qml
git rm components/effects/RippleEffect.qml
git rm shell.json 2>/dev/null; git checkout shell.json 2>/dev/null  # shell.json は触らない（誤削除防止の確認のみ）
```

最後の行は保険であり、`shell.json` が誤って消えていないことの確認を兼ねる。

- [ ] **Step 5: qmldir を生存集合に合わせて書き直す**

`services/qmldir` を次の内容にする（生存 13 個の完全列挙）：

```
module qs.services
singleton Audio Audio.qml
singleton AudioStreams AudioStreams.qml
singleton Bluetooth Bluetooth.qml
singleton Brightness Brightness.qml
singleton IdleInhibitor IdleInhibitor.qml
singleton Logger Logger.qml
singleton Network Network.qml
singleton Notifs Notifs.qml
singleton Players Players.qml
singleton PowerProfiles PowerProfiles.qml
singleton Pywal Pywal.qml
singleton Screenshot Screenshot.qml
singleton SystemUsage SystemUsage.qml
```

`components/qmldir` を次の内容にする：

```
module qs.components
AuroraSurface 1.0 AuroraSurface.qml
Elevation 1.0 Elevation.qml
```

`components/effects/qmldir` は Material3Anim（と削除した RippleEffect の行の除去）だけになっていることを確認する。

- [ ] **Step 6: 動作検証**

```bash
nix run .#fmt -- --fail-on-change
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell -n 80 --no-pager | grep -iE 'error|warning'   # 0 件
notify-send "test" "toast check"                                              # トーストが右上に出る
qs -c shell ipc call cc toggle                                                # CC が開く（再実行で閉じる）
```

- [ ] **Step 7: コミット**

```bash
git add -A home-manager/desktop/quickshell/shell
git commit -m "refactor(quickshell): 死蔵モジュール(bar/sidebar/dashboard/osd)と未参照services/componentsを削除、通知をmodules/notificationsへ昇格" -- home-manager/desktop/quickshell/shell
```

---

### Task 2: audio/bluetooth の shell 統合（ポップアウト常駐化）

**Files:**

- Create: `shell/modules/popouts/AudioPopout.qml`（元: `audio/modules/bar/components/AudioPopupWindow.qml`）
- Create: `shell/modules/popouts/BluetoothPopout.qml`（元: `bluetooth/modules/bar/components/BluetoothPopupWindow.qml`）
- Modify: `shell/shell.qml`, `default.nix`, `../waybar/modules.nix`, `../matugen/config.toml`
- Delete: `audio/`, `bluetooth/`

**Interfaces:**

- Consumes: Task 1 後の `shell/services/`（QsServices.\* シングルトン）。
- Produces: `AudioPopout` / `BluetoothPopout` 型（`property bool shouldShow` を持つ PanelWindow）。IPC `qs -c shell ipc call audio toggle` / `bluetooth toggle`（waybar が使用）。

- [ ] **Step 1: ポップアウト 2 ファイルを移設**

```bash
mkdir -p shell/modules/popouts
git mv audio/modules/bar/components/AudioPopupWindow.qml shell/modules/popouts/AudioPopout.qml
git mv bluetooth/modules/bar/components/BluetoothPopupWindow.qml shell/modules/popouts/BluetoothPopout.qml
```

両ファイルの相対 import を shell ツリー内の深さに合わせる（popouts は modules 直下の 1 階層下なので深さは変わらず 3 段だが、参照先が shell/ になる）：

```
import "../../../services" as QsServices   # そのままで shell/services を指すことを確認
```

`audio/shell.qml` にあった終了用 Timer（`quitTimer`）は移植しない。常駐化するため「閉じたらプロセス終了」の機構は不要になる。

- [ ] **Step 2: shell.qml にポップアウトと IPC を配線**

`shell/shell.qml` に import を追加：

```qml
import "modules/popouts"
```

`ShellRoot` 内に以下を追加する（`ControlCenterWindow { id: cc }` の近く）：

```qml
AudioPopout { id: audioPopout; shouldShow: false }
BluetoothPopout { id: bluetoothPopout; shouldShow: false }

// パネルは同時に 1 つだけ開く（別プロセス時代は重なりが起きていた）
function openPanel(name: string): void {
    const next = { cc: cc.shouldShow, audio: audioPopout.shouldShow, bluetooth: bluetoothPopout.shouldShow }[name]
    cc.shouldShow = false
    audioPopout.shouldShow = false
    bluetoothPopout.shouldShow = false
    if (name === "cc") cc.shouldShow = !next
    else if (name === "audio") audioPopout.shouldShow = !next
    else if (name === "bluetooth") bluetoothPopout.shouldShow = !next
}

IpcHandler {
    target: "audio"
    function toggle(): void { root.openPanel("audio") }
}
IpcHandler {
    target: "bluetooth"
    function toggle(): void { root.openPanel("bluetooth") }
}
```

既存 `IpcHandler { target: "cc" }` の `toggle()`/`open()` も排他に通す：

```qml
function toggle(): void { root.openPanel("cc") }
function open(): void { cc.shouldShow = false; root.openPanel("cc") }   // 必ず開く側に倒す
```

- [ ] **Step 3: 旧設定の削除と Nix 配線の縮小**

```bash
git rm -r audio bluetooth
```

`default.nix` の `xdg.configFile` から 2 行を削除：

```nix
"quickshell/audio".source = lnk ./audio;        # 削除
"quickshell/bluetooth".source = lnk ./bluetooth; # 削除
```

- [ ] **Step 4: waybar と matugen の呼び出しを更新**

`home-manager/desktop/waybar/modules.nix`：

```nix
# bluetooth モジュール
on-click = "qs -c shell ipc call bluetooth toggle";   # 旧: "qs -c bluetooth -n"
# pulseaudio モジュール
on-click = "qs -c shell ipc call audio toggle";       # 旧: "qs -c audio -n"
```

`home-manager/desktop/matugen/config.toml`：

```toml
post_hook = "qs -c shell ipc call theme reload 2>/dev/null; true"
# 旧: for c in shell audio bluetooth; do ...; done ループ
```

- [ ] **Step 5: ビルドと切替**

```bash
nix run .#fmt -- --fail-on-change
nix run .#build     # PASS を確認してから
nix run .#switch
```

- [ ] **Step 6: 動作検証**

```bash
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell -n 80 --no-pager | grep -iE 'error|warning'  # 0 件
qs -c shell ipc call audio toggle       # 即時表示（起動ラグなし）
qs -c shell ipc call bluetooth toggle   # audio が閉じて bluetooth が開く（排他）
qs -c shell ipc call cc toggle          # bluetooth が閉じて CC が開く
```

waybar のオーディオアイコンと Bluetooth アイコンのクリックでも同じ動作になることを目視確認する。

- [ ] **Step 7: コミット**

```bash
git add -A home-manager/desktop/quickshell home-manager/desktop/waybar/modules.nix home-manager/desktop/matugen/config.toml
git commit -m "refactor(quickshell): audio/bluetooth別configを廃止しshell常駐のpopouts+IPCへ統合" -- home-manager/desktop/quickshell home-manager/desktop/waybar/modules.nix home-manager/desktop/matugen/config.toml
```

---

### Task 3: 色レイヤの再構築（Colours 改名と Theme 参照統一）

**Files:**

- Move: `shell/services/Pywal.qml` → `shell/services/Colours.qml`
- Modify: `shell/services/qmldir`, `shell/config/Theme.qml`, `shell/config/Config.qml`, `shell.json`, `shell/shell.qml`, `shell/modules/popouts/*.qml`, `shell/modules/controlcenter/**/*.qml`, `shell/modules/notifications/NotificationPopups.qml`, `shell/components/AuroraSurface.qml`
- Delete（ファイル内）: legacy `color0..15`, `colors` マップ, `glass*`, `stateLayer*` エイリアス

**Interfaces:**

- Consumes: matugen 生成物 `~/.cache/quickshell/matugen-colors.json`（変更なし）。
- Produces: `QsServices.Colours`（M3 パレットのみ公開）。UI が色を参照する唯一の点としての `QsConfig.Theme`。新 Theme トークン `hover`, `borderFaint`。shell.json キー `paths.colours`。

- [ ] **Step 1: 改名と legacy 削除**

```bash
cd home-manager/desktop/quickshell/shell
git mv services/Pywal.qml services/Colours.qml
```

`services/Colours.qml` から以下を削除する：

- `// Legacy flat palette (color0..15)` ブロック（`property color color0` 〜 `color15`）
- `property var colors: ({...})` マップ
- `// Compatibility aliases` ブロック（`glassLow`, `glassHigh`, `glassHighest`, `glassBorder`, `glassBorderStrong`, `stateLayerLight`, `stateLayerDark`）
- `loadColors()` 内の `const c = d.colors; if (c) {...}` ブロック

ログタグ文字列 `"Pywal"` は `"Colours"` に変える。JSON 不在時のフォールバック（ハードコード既定値 + warn ログ）と `reload()`（matugen の atomic 書込対策）は残す。

- [ ] **Step 2: 参照の一括更新**

```bash
grep -rl 'QsServices\.Pywal' . | xargs sed -i 's/QsServices\.Pywal/QsServices.Colours/g'
sed -i 's/singleton Pywal Pywal.qml/singleton Colours Colours.qml/' services/qmldir
grep -rn -i 'pywal' . && echo "残骸あり" || echo "OK"
```

最後の grep が `OK` になるまで残骸（変数名 `pywal`, コメント等）を潰す。`AudioPopout.qml` の `readonly property var pywal: QsServices.Pywal` のような別名プロパティは Step 4 の Theme 置換で消えるため、ここでは名前だけ `colours` に揃える。

- [ ] **Step 3: shell.json と Config.qml のキー改名**

`shell.json`：

```json
"paths": {
  "colours": "~/.cache/quickshell/matugen-colors.json",
  "screenshotsDir": "~/Pictures/Screenshots"
}
```

`config/Config.qml`：

```qml
readonly property var paths: ({
    colours: _expandHome(data.paths?.colours ?? "~/.cache/quickshell/matugen-colors.json"),
    screenshotsDir: _expandHome(data.paths?.screenshotsDir ?? "~/Pictures/Screenshots")
})
```

`Colours.qml` の FileView も `path: QsConfig.Config.paths.colours` に更新する。あわせて `Config.qml` から死蔵セクション（`osd`, `launcher`, `sidebar`, `dashboard`）の property 定義を削除し、`shell.json` からも `launcher`, `sidebar`, `dashboard` キーを削除する。

- [ ] **Step 4: UI の色参照を Theme に統一**

`config/Theme.qml` の `readonly property var p: QsServices.Pywal` は Step 2 の sed で `QsServices.Colours` になっている。ここに不足トークンを 2 つ追加する：

```qml
// ── Interaction ──
readonly property color hover: withAlpha(p.foreground, 0.06)
readonly property color borderFaint: withAlpha(p.foreground, 0.08)
```

次の各ファイルで `Colours`（旧 Pywal）直参照とローカル色定数を Theme トークンへ置換する：

| ファイル                                                   | 現状                                                                                                                                         | 置換先                                                                                                           |
| ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `modules/popouts/AudioPopout.qml`                          | `cSurface`=surfaceContainer, `cSurfaceContainer`=surfaceContainerHigh, `cPrimary`, `cText`, `cSubText`(0.6), `cBorder`(0.08), `cHover`(0.06) | `Theme.panel`, `Theme.card`, `Theme.accent`, `Theme.text`, `Theme.textMuted`, `Theme.borderFaint`, `Theme.hover` |
| `modules/popouts/BluetoothPopout.qml`                      | 同上のローカル定数群                                                                                                                         | 同上                                                                                                             |
| `modules/controlcenter/ControlCenterWindow.qml`            | `root.cSurfaceContainerHigh`, `root.cOnSurface`, `root.cSecondary` 等のローカル別名                                                          | `Theme.card`, `Theme.text`, `Theme.secondary` 等（別名 property を削除し直接 Theme 参照）                        |
| `modules/controlcenter/sections/*.qml`, `components/*.qml` | 同様のローカル別名や直参照                                                                                                                   | Theme トークン                                                                                                   |
| `modules/notifications/NotificationPopups.qml`             | 直参照があれば                                                                                                                               | Theme トークン                                                                                                   |
| `components/AuroraSurface.qml`                             | `QsServices.Colours` 直参照                                                                                                                  | `QsConfig.Theme` 参照（import 追加: `import "../config" as QsConfig`）                                           |
| `shell.qml`                                                | `QsServices.Colours.reload()`（theme reload IPC）                                                                                            | これは例外として直参照のまま（プリミティブ層の管理操作であり色の消費ではない）                                   |

置換の判定基準：surface 系は「面の意味」（panel=パネル背景 / card=カード / cardHigh=ホバー・最上位 / inset=凹み）で選ぶ。マッピングが自明でない色（例: tertiaryContainer の装飾用途）は Theme に意味トークンを追加してから使う。**modules と components に `QsServices.Colours` の参照が残らないこと**を完了条件とする：

```bash
grep -rn 'QsServices\.Colours' modules components   # shell.qml 以外 0 件
```

- [ ] **Step 5: 動作検証**

```bash
nix run .#fmt -- --fail-on-change
nix run .#build && nix run .#switch    # shell.json が変わったため switch 必要
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell -n 80 --no-pager | grep -iE 'error|warning'  # 0 件
qs -c shell ipc call theme reload                                            # エラーなし
```

壁紙を変更し（既存のランダム壁紙キーバインド）、CC とポップアウトの配色が追従することを目視確認する。

- [ ] **Step 6: コミット**

```bash
git add -A home-manager/desktop/quickshell
git commit -m "refactor(quickshell): PywalをColoursへ改名、legacy color0..15/glass*を廃止、UIの色参照をThemeへ統一" -- home-manager/desktop/quickshell
```

---

### Task 4: ツリー再編（utils 分離と components サブ分類）

**Files:**

- Move: `shell/services/Logger.qml` → `shell/utils/Logger.qml`
- Move: `shell/components/AuroraSurface.qml` → `shell/components/containers/AuroraSurface.qml`
- Move: `shell/components/Elevation.qml` → `shell/components/effects/Elevation.qml`
- Create: `shell/utils/qmldir`, `shell/components/containers/qmldir`
- Modify: `shell/services/qmldir`, `shell/components/qmldir`（削除）, `shell/components/effects/qmldir`, Logger 参照元すべて

**Interfaces:**

- Produces: `import "../utils" as QsUtils` 経由の `QsUtils.Logger`。`components/containers/AuroraSurface`, `components/effects/{Elevation, Material3Anim}`。

- [ ] **Step 1: Logger を utils へ分離**

```bash
cd home-manager/desktop/quickshell/shell
mkdir -p utils
git mv services/Logger.qml utils/Logger.qml
cat > utils/qmldir <<'EOF'
module qs.utils
singleton Logger Logger.qml
EOF
sed -i '/singleton Logger Logger.qml/d' services/qmldir
```

参照元を一括更新する。services 内（`import "." as QsServices` で Logger を使っている）：

```bash
grep -rl 'QsServices\.Logger' services | xargs sed -i 's/QsServices\.Logger/QsUtils.Logger/g'
# 各ファイルの import 群に追加（QsServices import の直後）
grep -rl 'QsUtils\.Logger' services | xargs sed -i 's|^import "." as QsServices|import "." as QsServices\nimport "../utils" as QsUtils|'
```

modules 側の参照（controlcenter, notifications, popouts）も同様に `QsUtils.Logger` + `import "../../utils" as QsUtils`（深さに応じて調整）へ変える。sed 後に import の重複や深さ違いが無いか各ファイルを目視する。

- [ ] **Step 2: components をサブ分類**

生存 component は 3 つ。空のサブディレクトリは作らない（controls/ は現時点で対象が無いため作成しない）。

```bash
mkdir -p components/containers
git mv components/AuroraSurface.qml components/containers/AuroraSurface.qml
git mv components/Elevation.qml components/effects/Elevation.qml
git rm components/qmldir
cat > components/containers/qmldir <<'EOF'
module qs.components.containers
AuroraSurface 1.0 AuroraSurface.qml
EOF
```

`components/effects/qmldir` に `Elevation 1.0 Elevation.qml` を追記する。

参照元の import を更新する：

- `AuroraSurface.qml` 内の `Elevation {` → `import "../effects"` を追加
- `modules/controlcenter/**` の `import "../../components"` → `import "../../components/containers"`、`import "../../components/effects"` は維持（深さ確認）
- `AuroraSurface.qml` の相対 import（`"../config"` → `"../../config"` に深さ +1）

```bash
grep -rn 'components"' modules | grep import    # containers/effects 以外への import が無いこと
```

- [ ] **Step 3: 動作検証とコミット**

```bash
nix run .#fmt -- --fail-on-change
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell -n 80 --no-pager | grep -iE 'error|warning'  # 0 件
qs -c shell ipc call cc toggle && qs -c shell ipc call audio toggle          # 目視で従来どおり
git add -A home-manager/desktop/quickshell/shell
git commit -m "refactor(quickshell): Loggerをutilsへ分離、componentsをcontainers/effectsへサブ分類" -- home-manager/desktop/quickshell/shell
```

---

### Task 5: Appearance トークン一本化と全面適用

**Files:**

- Rewrite: `shell/config/Appearance.qml`（Config プロキシから実体シングルトンへ）
- Delete: `shell/config/AppearanceConfig.qml`, `shell/config/BarConfig.qml`（bar は削除済みのため）
- Modify: `shell/config/qmldir`, `shell/modules/**/*.qml`, `shell/components/**/*.qml`（生数値の置換）

**Interfaces:**

- Produces: `QsConfig.Appearance` シングルトン。トークン群 `radius.{xs,s,m,l,xl,full}`, `spacing.{xs,s,m,l,xl}`, `padding.{xs,s,m,l,xl}`, `margin.{xs,s,m,l,xl}`, `typography.*`（M3 スケール）, `anim.durations.{fast,normal,medium,slow}`, `anim.curves.*`, `alpha.{hover,border,low,medium,high,full}`。

- [ ] **Step 1: 新 Appearance.qml を書く**

`config/Appearance.qml` を次の内容に置き換える（フォントファミリは Config 由来のまま）：

```qml
pragma Singleton

import Quickshell
import QtQuick

// 寸法・タイポ・アニメの単一情報源。サイズ語彙は xs/s/m/l/xl/full。
// 色は Theme、環境依存値は Config が持つ（このファイルには置かない）。
Singleton {
    readonly property var radius: QtObject {
        property int xs: 6
        property int s: 10
        property int m: 16
        property int l: 22
        property int xl: 32
        property int full: 9999
    }

    readonly property var spacing: QtObject {
        property int xs: 4
        property int s: 8
        property int m: 12
        property int l: 16
        property int xl: 24
    }

    readonly property var padding: QtObject {
        property int xs: 4
        property int s: 8
        property int m: 12
        property int l: 16
        property int xl: 22
    }

    readonly property var margin: QtObject {
        property int xs: 6
        property int s: 10
        property int m: 14
        property int l: 20
        property int xl: 28
    }

    readonly property var typography: QtObject {
        property string family: Config.appearance.fontFamily

        readonly property var displayLarge: QtObject { property int size: 57; property int weight: Font.Normal }
        readonly property var displayMedium: QtObject { property int size: 45; property int weight: Font.Normal }
        readonly property var displaySmall: QtObject { property int size: 36; property int weight: Font.Normal }
        readonly property var headlineLarge: QtObject { property int size: 32; property int weight: Font.Normal }
        readonly property var headlineMedium: QtObject { property int size: 28; property int weight: Font.Normal }
        readonly property var headlineSmall: QtObject { property int size: 24; property int weight: Font.Normal }
        readonly property var titleLarge: QtObject { property int size: 22; property int weight: Font.Normal }
        readonly property var titleMedium: QtObject { property int size: 16; property int weight: Font.Medium }
        readonly property var titleSmall: QtObject { property int size: 14; property int weight: Font.Medium }
        readonly property var labelLarge: QtObject { property int size: 14; property int weight: Font.Medium }
        readonly property var labelMedium: QtObject { property int size: 12; property int weight: Font.Medium }
        readonly property var labelSmall: QtObject { property int size: 11; property int weight: Font.Medium }
        readonly property var bodyLarge: QtObject { property int size: 16; property int weight: Font.Normal }
        readonly property var bodyMedium: QtObject { property int size: 14; property int weight: Font.Normal }
        readonly property var bodySmall: QtObject { property int size: 12; property int weight: Font.Normal }
    }

    readonly property var anim: QtObject {
        readonly property var durations: QtObject {
            property int fast: 120
            property int normal: 180
            property int medium: 260
            property int slow: 340
        }
        readonly property var curves: QtObject {
            property var standard: [0.2, 0.0, 0, 1.0]
            property var standardDecel: [0.0, 0.0, 0, 1.0]
            property var standardAccel: [0.3, 0.0, 1, 1.0]
            property var emphasizedDecel: [0.05, 0.7, 0.1, 1.0]
            property var emphasizedAccel: [0.3, 0.0, 0.8, 0.15]
        }
    }

    readonly property var alpha: QtObject {
        property real hover: 0.06
        property real border: 0.08
        property real low: 0.14
        property real medium: 0.42
        property real high: 0.68
        property real full: 1.0
    }
}
```

注意：`anim.durations` の instant/slower、`anim.easing` 群、`curves.spring*` は現行未使用のため移さない。移行中に実際の参照が見つかったら、その値だけ追加する。

```bash
git rm config/AppearanceConfig.qml config/BarConfig.qml
```

`config/qmldir` から `AppearanceConfig`, `BarConfig` の行を削除し、`Appearance` が singleton として登録されていることを確認する。旧 `Appearance.qml` が `Config.appearance.rounding` 等を参照していた構造は消えるため、`Config.qml` に `appearance.rounding` 等を供給していた箇所があれば fontFamily / materialIconFont だけ残す。

- [ ] **Step 2: 置換規則の確定**

生数値をトークンへ置換する規則（最近傍への丸め。±2 以内はトークン値に寄せてよい。それ以上離れた意図的な値は Step 3 の named property にする）：

| 生数値の種類                              | 規則                                                                                                                                                                       |
| ----------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `radius:`                                 | 6→`radius.xs`, 8〜12→`radius.s`, 13〜18→`radius.m`, 19〜26→`radius.l`, 27 以上→`radius.xl`, 9999→`radius.full`                                                             |
| `spacing:`（RowLayout/ColumnLayout/Flow） | 4→`spacing.xs`, 8→`spacing.s`, 12→`spacing.m`, 16→`spacing.l`, 24→`spacing.xl`                                                                                             |
| `anchors.*Margin`, `Layout.*Margin`       | margin トークン（6/10/14/20/28 へ丸め）                                                                                                                                    |
| padding 系 property                       | padding トークン                                                                                                                                                           |
| `duration:`                               | 120→`anim.durations.fast`, 180→`normal`, 260→`medium`, 340→`slow`（近傍へ丸め）                                                                                            |
| `font.pixelSize:`                         | typography の該当ロール（11〜12→labelMedium/bodySmall, 14→bodyMedium, 16→titleMedium/bodyLarge, 見出しは title/headline）。`font.family` は `Appearance.typography.family` |
| `Qt.rgba(..., 0.06)` 等の生 alpha         | 色トークンで表せるもの（hover/borderFaint）は Theme、透明度だけの合成は `Theme.withAlpha(色, Appearance.alpha.*)`                                                          |

- [ ] **Step 3: モジュール固有寸法の named property 化**

1 回しか使わない固有寸法（ポップアウト幅、通知幅、CC 幅、グラフ高さ等）は各ファイル冒頭にまとめる：

```qml
// 例: AudioPopout.qml 冒頭
readonly property int popoutWidth: 340
readonly property int rowHeight: 44
```

これにより「ファイルを開いた先頭でそのモジュールの寸法が全部わかる」状態にする。値自体は現状維持（見た目を変えない）。

- [ ] **Step 4: ファイル群ごとに置換 → 検証 → コミット（3 バッチ）**

バッチ (a) `components/` + `modules/notifications/`、(b) `modules/controlcenter/`、(c) `modules/popouts/` + `shell.qml` の順で、各バッチごとに：

```bash
# 置換後
nix run .#fmt -- --fail-on-change
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell -n 80 --no-pager | grep -iE 'error|warning'  # 0 件
# 目視: 対象 UI の見た目が置換前と同等（±2px の丸め差は許容）
git add -A home-manager/desktop/quickshell/shell
git commit -m "refactor(quickshell): <バッチ名>の生数値をAppearanceトークンへ置換" -- home-manager/desktop/quickshell/shell
```

完了条件（バッチ (c) の後）：

```bash
grep -rnE '(radius|spacing|duration):\s*[0-9]' modules components | grep -v 'Appearance\.' | wc -l
```

出力が 0 件（named property 経由の参照は `radius: root.xxx` 形式なので該当しない）。

---

### Task 6: ポップアウトの空リスト対策

**Files:**

- Modify: `shell/modules/popouts/AudioPopout.qml`, `shell/modules/popouts/BluetoothPopout.qml`

**Interfaces:**

- Consumes: Task 5 の `popoutWidth` named property、`Theme`/`Appearance` トークン。

- [ ] **Step 1: 幅の固定と empty-state の追加**

両ポップアウトで、コンテンツ implicit 幅に依存している width 指定を `popoutWidth` 固定にする。デバイスリスト（AudioPopout の sinks/sources、BluetoothPopout のデバイス一覧）それぞれの直下に empty-state を追加する：

```qml
// リスト(Repeater/ListView)と同じ親レイアウト内に置く
Item {
    visible: popupWindow.sinks.length === 0    // 対象リストに合わせる
    Layout.fillWidth: true
    Layout.preferredHeight: root.rowHeight

    Text {
        anchors.centerIn: parent
        text: "デバイスが見つかりません"
        color: Theme.textMuted
        font.family: Appearance.typography.family
        font.pixelSize: Appearance.typography.bodyMedium.size
    }
}
```

BluetoothPopout はスキャン中の表示を分ける：

```qml
text: Bluetooth.scanning ? "スキャン中…" : "デバイスが見つかりません"
```

（`Bluetooth.scanning` に相当する property 名は `services/Bluetooth.qml` の実装を確認して合わせる。無ければ empty-state の文言は 1 種類でよい。）

- [ ] **Step 2: 検証とコミット**

```bash
systemctl --user restart quickshell && sleep 3
bluetoothctl power off
qs -c shell ipc call bluetooth toggle   # 幅・高さが保たれ「デバイスが見つかりません」表示
bluetoothctl power on
git add -A home-manager/desktop/quickshell/shell/modules/popouts
git commit -m "fix(quickshell): popoutの幅をトークン固定にし空リスト時のempty-stateを追加" -- home-manager/desktop/quickshell/shell/modules/popouts
```

AudioPopout の 0 件状態は実機で再現しづらいため、`visible:` の条件を一時的に `true` にして表示を確認してから戻す。

---

### Task 7: Screenshot サービスの縮小（スクリプトへの一本化）

**Files:**

- Rewrite: `shell/services/Screenshot.qml`
- Modify: `shell.json`, `shell/config/Config.qml`, `shell/modules/controlcenter/ControlCenterWindow.qml`（ラベル 1 箇所）

**Interfaces:**

- Consumes: `~/.config/hypr/scripts/screenshot.sh <region|window|output>`, `~/.config/hypr/scripts/record.sh`（トグル動作、pid file は `$XDG_RUNTIME_DIR/gpu-screen-recorder.pid`）。
- Produces: CC 向け互換 API を維持：`screenshotsDir`, `takeScreenshot(mode)`, `recorderAvailable`, `isRecording`, `startRecording()`, `stopRecording()`。

- [ ] **Step 1: record.sh の起動形態を確認**

```bash
tail -20 home-manager/desktop/hyprland/scripts/record.sh
```

gpu-screen-recorder をバックグラウンド起動して即 exit するなら `Process` でよい。フォアグラウンドで握り続けるなら下のコードの `recordProc` を `Quickshell.execDetached([...])` に差し替える。

- [ ] **Step 2: Screenshot.qml を書き換え**

```qml
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// 撮影・録画の実装は hyprland/scripts/{screenshot,record}.sh が正。
// ここはキーバインド・rofi と同じスクリプトを呼ぶだけの薄い層。
Singleton {
    id: root

    // screenshot.sh の base_dir と一致させる（"Open Captures" ボタン用）
    readonly property string screenshotsDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts"

    property bool isRecording: false
    property bool recorderAvailable: false

    function takeScreenshot(mode: string): void {
        // CC の "screen" はスクリプトの "output"（フォーカス中モニタ全体）
        const m = mode === "screen" ? "output" : mode
        Quickshell.execDetached([`${root.scriptsDir}/screenshot.sh`, m])
    }

    // record.sh は呼ぶたびに開始/停止が切り替わるトグル
    function startRecording(): void { recordProc.running = true }
    function stopRecording(): void { recordProc.running = true }

    Process {
        id: recordProc
        command: [`${root.scriptsDir}/record.sh`]
        onExited: statusProc.running = true
    }

    Process {
        id: probeProc
        command: ["which", "gpu-screen-recorder"]
        onExited: code => root.recorderAvailable = (code === 0)
    }

    Process {
        id: statusProc
        command: ["sh", "-c", 'f="${XDG_RUNTIME_DIR:-/tmp}/gpu-screen-recorder.pid"; test -f "$f" && kill -0 "$(cat "$f")"']
        onExited: code => root.isRecording = (code === 0)
    }

    // 録画中のみ外部停止(キーバインド側からの停止)を拾うためポーリング
    Timer {
        interval: 3000
        repeat: true
        running: root.isRecording
        onTriggered: statusProc.running = true
    }

    Component.onCompleted: {
        probeProc.running = true
        statusProc.running = true
    }
}
```

- [ ] **Step 3: 設定と CC の追従**

- `shell.json` から `paths.screenshotsDir` を削除、`config/Config.qml` の `paths` からも削除する。
- `ControlCenterWindow.qml` の `subLabel: "Install wf-recorder"` を `"Install gpu-screen-recorder"` に、`"Start wf-recorder"` を `"Start recording"` に変える（実体は wf-recorder ではなくなったため）。他のボタン配線（`takeScreenshot("screen")`, `startRecording()`, `stopRecording()`, `screenshotsDir`）は互換 API のため変更不要。

- [ ] **Step 4: 検証とコミット**

```bash
nix run .#fmt -- --fail-on-change
nix run .#build && nix run .#switch    # shell.json 変更のため
systemctl --user restart quickshell && sleep 3
journalctl --user -u quickshell -n 80 --no-pager | grep -iE 'error|warning'  # 0 件
```

実機確認：CC の Screenshot ボタンで全画面撮影（クラス別フォルダに保存され通知が出る＝スクリプト経由の証拠）、Record ボタンで録画開始 → ボタンが Stop 表示 → 停止で mp4 保存。キーバインド（Super+P）経由も従来どおり。

```bash
git add -A home-manager/desktop/quickshell
git commit -m "refactor(quickshell): Screenshotサービスを撮影ロジック持ちからscreenshot.sh/record.sh呼び出しの薄い層へ縮小" -- home-manager/desktop/quickshell
```

---

### Task 8: 最終検証と todo.md 更新

**Files:**

- Modify: `todo.md`

- [ ] **Step 1: 全体検証**

```bash
nix run .#fmt -- --fail-on-change
nix run .#build
grep -rni 'pywal\|wallust' home-manager/desktop/quickshell        # 0 件
grep -rn 'qs -c audio\|qs -c bluetooth' home-manager               # 0 件
find home-manager/desktop/quickshell -name '*.qml' | xargs wc -l | tail -1   # 約 7,000 行に縮小
```

実機チェックリスト（スペックの検証節）：通知トースト、Super+N の CC、waybar からの audio/bluetooth ポップアウト（0 件状態含む）、パネル排他、壁紙変更での色追従、CC からのスクリーンショットと録画。

- [ ] **Step 2: todo.md の該当項目を完了へ更新**

`## quickshellの大規模リファクタリング` セクションを完了記載に書き換える（waybar リデザイン項目と同じ体裁で ✅ とスペック/プランへのリンクを付ける）。「スクリーンショット系をquickshellで自前で持っている。screen.shを統合する」も完了に含める。config ボタンの空メニュー解消は未完のまま残す。

- [ ] **Step 3: コミット**

```bash
git add todo.md
git commit -m "docs: quickshell大規模リファクタリング完了をtodoへ反映" -- todo.md
```
