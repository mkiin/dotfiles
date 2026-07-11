# rofi キャプチャモードピッカー（BlackNode 風 島 UI）設計

作成日: 2026-07-12
参照: todo.md「スクリーンショットの画面範囲セレクトを…quickshell によるUIで選択させる方式にする」（項目94）/ BlackNode（`ghq/github.com/zhaleff/BlackNode`）

## 背景と目的

スクリーンショット／画面録画のモード（region / window / output など）を、これまで
キーバインドの組み合わせで使い分けてきた。これを **1 つのキーで島型の rofi メニューを
出し、その中でモードを選ぶ方式**へ置き換える。BlackNode の `rofi/hyprshot`・
`rofi/wf-recorder` が採用している「薄いメニュー層」を踏襲する。

### BlackNode の実際の設計（調査結果）

BlackNode の島 UI は quickshell ではなく **rofi -dmenu** である。かつ「範囲選択そのもの」を
UI 化しているのではなく、**キャプチャ種別（モード）を選ぶピッカー**にすぎない。範囲の
ドラッグ選択は、モード選択後に `slurp`（hyprshot 内部）が従来どおり担う。構造は
1 機能あたり `script.sh`（`printf` でアイコンを列挙 → `rofi -dmenu` → 連想配列でコマンド分岐）
＋ `style.rasi`（右端に浮く縦型の島レイアウト、`location: east`）と極めて薄い。

## 方針

撮影・録画の本体（`screenshot.sh` / `record.sh`）はロジックを温存し、その手前に
rofi 製の島型モードピッカーを 1 枚かぶせる。keybind はピッカー起動へ集約する。

```
Super+P → screenshot/menu.sh → 島(region/window/output) → screenshot.sh <mode>（既存・無改修）
Super+R → record/menu.sh    → 島(全体/範囲/停止)      → record.sh <...>（region 対応を追加）
```

## 構成要素

### 1. スクリーンショットピッカー `rofi/screenshot/`

- `menu.sh` … `rofi -dmenu` でアイコン 3 つ（region / window / output）を出し、選択を
  連想配列で `~/.config/hypr/scripts/screenshot.sh region|window|output` に振る。
  BlackNode の `hyprshot/script.sh` とほぼ同型。`screenshot.sh` は**無改修**（内部で
  `slurp` を呼び範囲選択する挙動は変わらない）。
- `theme.rasi` … 右端に浮く縦型の島。BlackNode の `style.rasi` を土台にする。

### 2. 録画ピッカー `rofi/record/`

- `menu.sh` … 録画状態を `record.sh` と同じ `pid_file`（`$XDG_RUNTIME_DIR/gpu-screen-recorder.pid`）
  ／`kill -0` で判定して**出し分ける**。
  - 非録画中: 「全体」「範囲」の 2 択を出す。
  - 録画中: 「停止」だけを出す。
  - BlackNode は 3 択常時表示＋no-op だが、状態出し分けの方が誤操作しにくいため採用する。
- `theme.rasi` … スクリーンショット側と同レイアウト（行数だけ状態で変わる）。

### 3. `record.sh` への region 対応追加

現状の `record.sh` はフォーカスモニタ全体録画のトグルのみ。範囲録画を新設する。

- 第 1 引数（または専用フラグ）で region モードを受け、`slurp` で領域を取得してから
  `gpu-screen-recorder` の領域指定で録画する。
- **【要実機検証】** `gpu-screen-recorder` の領域指定フラグはバージョン依存
  （`-w region -region WxH+X+Y` 等）。この設計を書いた WSL 環境には gsr が無く検証
  できていない。実装時に実機で `gpu-screen-recorder --help` を確認し、対応フラグを
  確定する。もし gsr が領域録画に非対応なら、region のときだけ `wf-recorder -g "$(slurp)"`
  へフォールバックする案を代替とする（その場合 `wf-recorder` を packages に追加）。
- 既存の moov atom 対策（SIGINT 停止）・保存先・日本語通知はそのまま踏襲する。

### 4. theme.rasi の配色連動（ハマりどころ）

この dotfiles の rofi は `@import "colors.rasi"`（matugen が実行時に生成）で配色連動して
いる。変数名は `background` / `background-alt` / `foreground` / `selected` / `active` /
`urgent` / `border-color`（`matugen/templates/rofi-colors.rasi` 由来）。
**BlackNode の rasi は `@surface` / `@on-surface` / `@primary` を使うため、そのままコピー
すると未定義変数で壊れる。** theme.rasi はこの dotfiles の変数名に置換して書く。
選択枠は `active`（primary 相当）、地は `background`、文字は `foreground` を使う。

島レイアウトの要点（BlackNode 踏襲）: `window { location: east; anchor: east; width: 100px;
x-offset: -15px; border-radius: 12px; }`、`listview { columns: 1; layout: vertical; }`、
`element-text` はアイコンフォント。行数はスクショ 3・録画は状態依存。

### 5. keybind 変更（`hyprland/lua/keybinds.lua`）

- `Super+P` → `~/.config/rofi/screenshot/menu.sh`（島 UI）
- `Super+R` → `~/.config/rofi/record/menu.sh`（島 UI）
- **削除**: `Super+Shift+P`（window）/ `Super+Ctrl+P`（output）… 島 UI へ一本化。
- **残す（島 UI 外の特殊系）**:
  - `Super+Alt+P` → `screenshot.sh output DP-3`（特定モニタ直撮り）
  - `Super+Ctrl+R` → `record.sh ~/personal/tools/facefusion/media/target`（保存先違いの録画）

### 6. パッケージ集約宣言の是正

`gpu-screen-recorder` が集約 `packages.nix` に未宣言（`record.sh` が参照しているのに）。
CLAUDE.md の集約ルールに従い `home-manager/desktop/packages.nix` へ宣言を追加する。
`rofi` / `grim` / `slurp` は宣言済みで追加不要。

### 7. home-manager 配線（`rofi/default.nix`）

`xdg.configFile` に 4 ファイルを追加する（既存 `launch.sh` と同じ `lnk ./...` 方式。
`launch.sh` が keybind から直接 exec できている前例に倣い実行権限も担保される）。

```
"rofi/screenshot/menu.sh".source  = lnk ./screenshot/menu.sh;
"rofi/screenshot/theme.rasi".source = lnk ./screenshot/theme.rasi;
"rofi/record/menu.sh".source      = lnk ./record/menu.sh;
"rofi/record/theme.rasi".source   = lnk ./record/theme.rasi;
```

サブディレクトリ（`rofi/screenshot/`・`rofi/record/`）は「同種が並ぶ緩い括り」なので
中間集約 `default.nix` は設けず、親 `rofi/default.nix` から直接配線する（CLAUDE.md の
規約 2 に沿う）。

## スコープ外（今回触らない）

- quickshell の `Screenshot.qml` 重複実装と ControlCenter / Dashboard の撮影・録画ボタン
  （todo 項目 62「screen.sh を quickshell に統合」）は現状維持。今回は rofi 島 UI の追加のみ。

## 受け入れ条件

- `Super+P` で右端に島が出て、region / window / output を選ぶと従来と同じ結果
  （保存先・クリップボードコピー・日本語通知）で撮影できる。
- `Super+R` で島が出て、非録画中は「全体 / 範囲」、録画中は「停止」が出る。範囲を選ぶと
  `slurp` で領域選択して録画が始まり、停止で正常な mp4 が保存される。
- 島の配色が現壁紙の matugen テーマに連動している。
- `Super+Alt+P`（DP-3）・`Super+Ctrl+R`（facefusion）は従来どおり動く。
- `nix run .#build` と `nix run .#fmt -- --fail-on-change` が通る。
