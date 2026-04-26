# noro-dotfiles Waybar 構成分析

## 設定ファイル構成

```
~/.config/waybar/
├── config.jsonc                # モジュール定義 (唯一手で編集する config 側ファイル)
├── style.css                   # ⚠️ waybar-set が書き換える、手で編集しない
├── colors.css                  # ⚠️ matugen 生成 (壁紙連動)
├── colors-waybar.css           # ⚠️ wallust 生成 (壁紙連動、別パレット系)
├── capsule-nobg.css            # アクティブな custom style への symlink (?)
├── generated                   # ⚠️ 生成されたミニ CSS (style.css の "アクティブ style" の中身を実体化したもの。ファイル名だがディレクトリ風)
├── custom styles/              # 全 style プリセット (1 つだけ active になる)
│   ├── original.css
│   ├── capsule.css / capsule-nobg.css
│   ├── island.css / island-squared.css
│   ├── floating-glass-pills.css
│   ├── modern-glass.css / glass-modern.css
│   ├── modern-tabs.css
│   ├── neon-glow-islands.css
│   ├── aurora-ribbon.css
│   ├── cyber-duo.css
│   ├── soft-gradient.css
│   ├── back-alllnoth-bor.css / back-alllnoth-nobor.css / back-noth-nbor.css
│   ├── background-bordered.css / background-no-border.css
│   ├── styles3.css
│   ├── zen.css
│   └── original.css
├── original backup/            # 初期テンプレ (config.jsonc + style.css)
└── scripts/
    ├── launch.sh               # `killall -9 waybar; waybar &` だけの簡易再起動
    └── waybar-light-controls/  # 部屋の照明/温度を bar 上から制御するスクリプト群
```

## バー全体属性

```jsonc
"layer": "top",
"font": "JetBrains Nerd Font 10",
"margin": "10 8 -5 8",
"reload_style_on_change": true,
```

`margin: "10 8 -5 8"` の **bottom -5** が特徴的 (バーをほんの少しオーバーラップさせる演出)。

## モジュール一覧

| モジュール | カテゴリ | 役割 |
|---|---|---|
| `custom/nix` | カスタム | NixOS ロゴ表示 (`󰣇`)、機能なし |
| `clock` | 標準 | 時刻 + format-alt で曜日/日付フル。**カレンダー tooltip に matugen-風カラー付き月/曜日/週/今日の HTML 装飾** あり |
| `network` | 標準 | wifi: ESSID 表示、ethernet: IP 表示。 `interface: wlo1` 固定 (= ノート PC 想定) |
| `bluetooth` | 標準 | BT デバイス名 + 状態 |
| `hyprland/window` | 標準 | アクティブウィンドウのタイトル (per-output) |
| `custom/temperature` | カスタム | **室内ライトの色温度コントロール**。スクロールで `temperature_control.sh up/down` |
| `custom/light` | カスタム | **室内ライトの明るさコントロール**。スクロールで `light_control.sh up/down` |
| `hyprland/workspaces` | 標準 | `format: "{id}"` (ID をそのまま表示)。persistent 6 個固定 |
| `backlight` | 標準 | 画面バックライト。click +10%、scroll で 1% 刻み |
| `pulseaudio` | 標準 | 音量。`format-icons` で出力デバイス種別 (アナログ/headset/headphone/portable) ごと別アイコン |
| `cava` | 標準 | **音声ビジュアライザー** (▁▂▃▄▅▆▇█ で波形描画、20 bars、60fps) |
| `cpu` `memory` `idle_inhibitor` | 標準 | `group/sysstats` の中で drawer 化 (折り畳み展開) |
| `battery` | 標準 | バッテリー %。warning 30/critical 15。**充電完了/低電力で notify-send** |
| `custom/swaync` | カスタム | swaync 通知トグル (`󰂚`、click で `swaync-client -t`) |
| `tray` | 標準 | システムトレイ |

## グループ分け / レイアウト

```
┌─ modules-left ────────────────────────────┐ ┌─ modules-center ──────────────────────────────┐ ┌─ modules-right ─────────────────────────────┐
│ custom/nix  clock  network  bluetooth     │ │ custom/temperature  custom/light  workspaces  │ │ cava  group/sysstats  battery  swaync  tray │
│   hyprland/window                         │ │      backlight  pulseaudio                    │ │                                             │
└───────────────────────────────────────────┘ └───────────────────────────────────────────────┘ └─────────────────────────────────────────────┘
```

```jsonc
"group/sysstats": {
    "drawer": {
        "transition-duration": 500,
        "children-class": "not-memory",
        "transition-left-to-right": false
    },
    "modules": ["cpu", "memory", "idle_inhibitor"]
}
```

drawer (折り畳み引き出し) を使った group は anom の Minimal Bar の固定 `group/*` と違い、**hover/click で展開する dynamic UI** になる。

## 設計の特徴

### 1. Style 切替アーキテクチャ (動的)

公式 docs (`docs/components/waybar.md`) によると:

```
config.jsonc          ← モジュール定義 (永遠に固定、style 切替で変えない)
style.css             ← waybar-set スクリプトが書き換える薄いファイル
  ├── @import colors.css           ← matugen colors (壁紙連動)
  ├── @import colors-waybar.css    ← wallust colors (壁紙連動、別パレット)
  └── @import custom styles/X.css  ← 現在 active な style プリセット
```

`waybar-set` (キーバインドや `waybar-menu` 経由) を実行すると、`custom styles/` の中から選んだ preset を `style.css` の最後の `@import` に書き込み + waybar reload する。

`generated` ファイル中身:
```css
@import "colors.css";
/* @import url('../../.cache/wal/colors-waybar.css'); */
@import url('../../.cache/wallust/colors-waybar.css');
@import url('/home/noro18/.config/waybar/custom styles/original.css')
```

### 2. 二重カラーパイプライン (matugen + wallust)

| ジェネレータ | 出力 | 役割 |
|---|---|---|
| matugen | `colors.css` (Material Design 3 トークン) | 主要カラー (`@primary`, `@surface_container_high` 等) |
| wallust | `colors-waybar.css` (Pywal 系のシェル/ターミナル系トークン) | 補助カラー (例: 純粋な hex のアクセント色) |

両方を同時に `@import` して、style 側で適切に使い分ける。matugen + wallust の併用は壁紙からの色抽出を 2 流派で行うことで色彩バリエーションを増やす狙い。

### 3. 1 jsonc / 多 css

anom は theme = jsonc + css のペアを丸ごと差し替えるが、noro は **config.jsonc を固定** で **style.css のみを差し替える**。
モジュール構成 (バーに何を出すか) は変えず、見た目だけ切り替えたい時に向く設計。

### 4. ノート PC 前提のモジュール集

`battery` `backlight` `network.interface=wlo1` 等、ノート PC 環境を強く想定。デスクトップでは多くのモジュールが空表示になる可能性があるので、デスク移植時は要削除/置換。

### 5. 室内 IoT 制御モジュール

`custom/temperature` と `custom/light` は **物理ライトの色温度・明るさ調整** スクリプト (`waybar-light-controls/`)。bar からスクロールで操作するという発想は珍しい。デスク移植時は不要。

## Style プリセットの分類

20 種ある style を分類すると:

| 系統 | プリセット | 特徴 |
|---|---|---|
| **Pill / Capsule** | `capsule.css`, `capsule-nobg.css`, `original.css` | 各モジュールが独立した丸ピル、anom Material Pills と近い |
| **Island** | `island.css`, `island-squared.css` | グループ単位で島状、左/中央/右で 3 つの大塊 |
| **Glass / Blur** | `glass-modern.css`, `modern-glass.css`, `floating-glass-pills.css` | 透過 + ブラー。matugen alpha トークン使用 |
| **Tab / Ribbon** | `modern-tabs.css`, `aurora-ribbon.css` | タブ風帯状装飾 |
| **Neon / Cyber** | `neon-glow-islands.css`, `cyber-duo.css` | グロー/ネオン強調、暗背景前提 |
| **Background base** | `background-bordered.css`, `background-no-border.css`, `back-noth-nbor.css`, `back-alllnoth-*` | バー全体に背景、モジュール個別装飾なし |
| **Other** | `soft-gradient.css`, `styles3.css`, `zen.css` | 単独系 |

## anom との比較

| | anom Material Pills | noro |
|---|---|---|
| **思想** | 1 jsonc + 1 css。テーマ = 全部入れ替え | 1 jsonc 固定 + n style.css。見た目だけ切替 |
| **テーマ切替方式** | 静的 (CLI で別ディレクトリの jsonc を起動時指定) | 動的 (`waybar-set` で style.css 書換 → live reload) |
| **対象環境** | デスクトップ向き (シンプル) | ノート PC + 室内 IoT 込み |
| **モジュール数** | 9 (apps, clock, mpris, ws, notification, tray, pulseaudio, network, screenrecording-indicator) | 16+ (sysstats group, cava, light/temp, battery, backlight, etc.) |
| **ws 表示** | `{windows}` (アプリアイコン羅列) | `{id}` (番号のみ) |
| **カラーパイプ** | matugen のみ | matugen + wallust 併用 |
| **特殊機能** | window-rewrite で 80+ アプリのアイコン化 | drawer (折りたたみ) + IoT 制御 + cava ビジュアライザー |

## 当環境への移植時の注意点

### そのまま使えるもの
- `clock` (formatting + calendar tooltip 装飾)
- `cava`, `pulseaudio`, `tray`, `custom/swaync`, `cpu`/`memory`/`idle_inhibitor`
- `group/sysstats` の drawer パターン
- カスタム style 群 (デスクトップでも装飾だけ流用可)
- matugen 連動の `colors.css` 出力 (**当環境には既存の `[templates.waybar-anom]` がある、流用可**)

### 移植時に削る/変える必要あり
- `battery`, `backlight` → デスクトップでは無効化 or 削除
- `network.interface = wlo1` → DHCP / autodetect に変更 (or 削除)
- `bluetooth` → 当環境で BT 使うなら残す
- `custom/temperature`, `custom/light` → 室内 IoT モジュールなので削除
- `custom/nix` → CachyOS なので `󰣇` (NixOS) は不適切、削除 or `` (Arch) に変更
- wallust 連動 → 当環境に wallust 無し。**matugen のみで完結させる必要あり** (=`colors-waybar.css` の @import を消す or wallust 入れる)
- `waybar-set` 切替スクリプト → 当環境に無い。手動で `style.css` の @import を編集する運用にするか、スクリプト移植

### 当環境に追加で必要かもしれないもの
- 既存 anom 環境では `pulsemixer`/`omarchy-launch-wifi` 等が無くてコメントアウトしていた。noro の `pavucontrol` (pulseaudio 用) はインストール済みなら使える、要確認

## 参考

- noro 自身のドキュメント: `docs/components/waybar.md`
- waybar-set: `~/.local/bin/waybar-set` 等にあるはず (移植する場合は要コピー)
- waybar-menu: 別 keybind 経由の wofi/rofi セレクタ (要確認)
