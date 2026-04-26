# anom-dotfiles Waybar 構成分析

## 設定ファイル構成

```
.config/waybar/
├── config.jsonc                      # アクティブな設定 (Material Pills とほぼ同一)
├── style.css                         # アクティブなスタイル
├── colors.css                        # matugen 生成 (壁紙連動)
├── reloadwb.sh                       # waybar リロードスクリプト
├── scripts/
│   └── reloadwb.sh
└── themes/
    ├── Material Pills/               # テーマ 1: モジュールごとに丸ピル状の塊
    │   ├── config.jsonc
    │   └── style.css
    └── Minimal Bar/                  # テーマ 2: グループ化 + セパレータの細身バー
        ├── config.jsonc
        └── style.css
```

`config.jsonc` がアクティブで、`themes/<theme-name>/` がテーマ切替候補。リロードは `reloadwb.sh` (テーマ切替スクリプト相当)。

## バー全体属性

| 属性 | Material Pills (= default) | Minimal Bar |
|---|---|---|
| `position` | `top` | `top` |
| `margin-top` | 4 | 2 |
| `font-family` | (style.css で指定) | `JetBrainsMono Nerd Font Propo` |

## モジュール一覧 (両テーマ共通)

| モジュール | カテゴリ | 役割 |
|---|---|---|
| `custom/apps` | カスタム | ランチャー起動。クリックで `~/.config/rofi/scripts/menu.sh` を実行 |
| `clock` | 標準 | 時計。format-alt で日付に切替 (12時間/24時間 をコメントで切替可能) |
| `mpris` | 標準 | メディアプレイヤー (playerctl)。クリック・ホイールで操作、`zen` ブラウザは無視 |
| `hyprland/workspaces` | 標準 | ワークスペース表示。**window-rewrite で開いてるアプリのアイコンを ws 内に表示** (約 80 種のアプリ class/title マッピング) |
| `custom/notification` | カスタム | swaync の通知状態を icon で表示。click で `swaync-client -t -sw` (toggle) |
| `tray` | 標準 | システムトレイ |
| `pulseaudio` | 標準 | 音量。click で `pulsemixer` 起動、scroll で 5%刻み |
| `network` | 標準 | wifi/ethernet 状態。click で `omarchy-launch-wifi` |
| `custom/screenrecording-indicator` | カスタム | 録画中インジケーター (定義はあるが modules-* リストに未登録 = 表示されない、シグナル 8 で動的表示する設計) |
| `custom/seprator#line` | カスタム (Minimal Bar 専用) | グループ内の `\|` セパレータ |

`hyprland/workspaces` の `window-rewrite` には Firefox/Zen/Brave 等のブラウザ群、Telegram/Discord/Slack 等のメッセンジャー、VS Code/Zed/IntelliJ 等の IDE、mpv/VLC/Spotify 等のメディアプレイヤーまで網羅され、ws 内に各ウィンドウの Nerd Font アイコンが並ぶようになっている。

## グループ分け / レイアウト

### Material Pills (default と同形)

```
┌─ modules-left ──────────────┐ ┌─ modules-center ──────────────────┐ ┌─ modules-right ─────────┐
│ custom/apps  clock  mpris   │ │ hyprland/workspaces  notification │ │ tray  pulseaudio  network │
└─────────────────────────────┘ └───────────────────────────────────┘ └─────────────────────────┘
```

各モジュールがそのまま `modules-left/center/right` に並ぶ平坦な構造。スタイル側で個別に丸ピル状に装飾される (CSS が見た目を担う)。

### Minimal Bar

```
┌─ modules-left ──────────────────────────┐ ┌─ modules-center ─────────────────┐ ┌─ modules-right ──────────────────┐
│ ┌── group/left ─────────────┐           │ │                                  │ │       ┌── group/right ──────────┐ │
│ │ custom/apps │ clock       │   mpris   │ │ hyprland/workspaces  notification│ │ tray  │ pulseaudio │ network    │ │
│ └────────────^──────────────┘           │ │                                  │ │       └────────────^────────────┘ │
│              └ custom/seprator#line     │ │                                  │ │                    └ seprator     │
└─────────────────────────────────────────┘ └──────────────────────────────────┘ └──────────────────────────────────┘
```

waybar の `group/<name>` モジュール機能を使い、関連モジュールを **`|` セパレータ込みで束ねた塊** にしている。

```jsonc
"group/left":  { "modules": ["custom/apps",  "custom/seprator#line", "clock"] }
"group/right": { "modules": ["pulseaudio",   "custom/seprator#line", "network"] }
```

CSS 側で外側の塊 (`#group-left`, `#group-right`) に共通の枠を当てて、内部のモジュールはセパレータでだけ仕切る = 1 つの「セル」として見せるパターン。

### 比較

| | Material Pills | Minimal Bar |
|---|---|---|
| モジュール構造 | フラット (全モジュール独立) | `group/*` で関連モジュールを束ねる |
| セパレータ | なし (CSS マージン/丸枠で分離) | `\|` テキストセパレータあり |
| 装飾の主担当 | CSS (style.css 側) | config (group) + CSS の両方 |
| `hyprland/workspaces` の format | `{windows}` (ws 内のアプリアイコン羅列) | `{icon}` (ws 状態の点・dot) |
| persistent-workspaces | `{"*": [1,2,3,4,5]}` 全 output 共通 | 各 ws 別キーの空配列 (持続だけ確保) |

## 設計のポイント

### 1. アプリアイコンつき workspace 表示 (Material Pills 方式)

`hyprland/workspaces.format = "{windows}"` + `window-rewrite` で、各 ws に「中で開いているアプリのアイコン」を並べる方式。Nerd Font グリフをアプリの class/title に正規表現マッチで割り当てる:

```jsonc
"window-rewrite": {
    "class<firefox|...>": "",
    "class<zen>": "󰰷",
    "class<com.mitchellh.ghostty>": "",
    "class<dev.zed.Zed>": "󰵁",
    ...
}
```

ts 番号より中身を優先する UX。同種アプリを揃えるため、`firefox|librewolf|floorp|cachy-browser` のような OR 集約パターンが多用されている。

### 2. ドット型 workspace 表示 (Minimal Bar 方式)

`format: "{icon}"` + `format-icons` でステータス別のドットを出す:

```jsonc
"format-icons": {
    "default": "",
    "active":  "",
    "urgent":  "",
    "empty":   ""
}
```

シンプルで widthが安定するのが利点。アプリアイコン方式とは対照的に「ws の数だけわかればいい」運用向け。

### 3. group モジュールでの装飾セル化 (Minimal Bar)

```jsonc
"group/left":  { "modules": ["custom/apps", "custom/seprator#line", "clock"] }
```

CSS で `#group-left { background, border-radius, padding }` を当てれば、左側 3 モジュールが 1 つの丸枠カプセルに見える。Pills スタイルでも近い見た目は CSS だけで作れるが、group を使うと **「どのモジュールが論理的に同じ塊か」が config 側に明示される** ので可読性が上がる。

### 4. orphan モジュール `custom/screenrecording-indicator`

`modules-left/center/right` のどこにも入っていない定義済みモジュール。`signal: 8` で SIGRTMIN+8 を受けて表示状態が更新される設計のはずで、おそらく recording 開始スクリプトから呼び出される動的表示用。ただし参照されてないので現在は dead code 扱い (バグ or 未統合)。

## 参考情報

- waybar group モジュール: <https://github.com/Alexays/Waybar/wiki/Module:-Group>
- waybar hyprland/workspaces window-rewrite: <https://github.com/Alexays/Waybar/wiki/Module:-Hyprland>
- mpris モジュール: <https://github.com/Alexays/Waybar/wiki/Module:-MPRIS>
