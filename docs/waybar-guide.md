# Waybar 前提知識ガイド

Waybar の設定を書くために必要な知識をまとめたドキュメント。
公式ドキュメント（man 5 waybar 等）の内容をベースに、自分のデスクトップ仕様に関連する部分を抽出。

---

## 1. ファイル構成

Waybar は **2つのファイル** で構成される。

| ファイル | 役割 | 形式 |
|----------|------|------|
| `config.jsonc` | モジュール配置、動作設定 | JSONC（コメント付きJSON） |
| `style.css` | 見た目（色、サイズ、余白等） | CSS（GTK3サブセット） |

配置場所: `~/.config/waybar/`

Waybar は config.jsonc を変更すると **再起動が必要** だが、style.css は `reload_style_on_change: true` を設定すれば **ホットリロード** できる。

---

## 2. config.jsonc の基本構造

```jsonc
{
    // --- バー全体の設定 ---
    "layer": "top",           // "top"（ウィンドウの前面）or "bottom"（背面）
    "position": "top",        // バー位置: "top", "bottom", "left", "right"
    "height": 30,             // 高さ（px）。省略すると動的
    "spacing": 4,             // モジュール間の隙間（px）
    "exclusive": true,        // 他のウィンドウがバーと重ならないようスペースを確保

    // --- モジュール配置 ---
    "modules-left": ["モジュール名", ...],
    "modules-center": ["モジュール名", ...],
    "modules-right": ["モジュール名", ...],

    // --- 各モジュールの設定 ---
    "clock": {
        "format": "{:%H:%M}",
        ...
    },
    ...
}
```

### 重要なバー設定

| プロパティ | 型 | デフォルト | 説明 |
|-----------|-----|----------|------|
| `layer` | string | "bottom" | "top" にすると他のウィンドウより前面に表示 |
| `position` | string | "top" | バーの位置（top/bottom/left/right） |
| `height` / `width` | integer | 動的 | バーのサイズ。省略推奨 |
| `exclusive` | bool | true | バー分のスペースを確保するか |
| `fixed-center` | bool | true | 中央ブロックを画面中央に固定 |
| `spacing` | integer | - | モジュール間のギャップ（px） |
| `reload_style_on_change` | bool | false | CSSファイル変更時に自動リロード |
| `include` | string/array | - | 外部設定ファイルの読み込み（モジュール分割用） |

### include（設定ファイル分割）

```jsonc
{
    "include": [
        "~/.config/waybar/modules/clock.jsonc",
        "~/.config/waybar/modules/cpu.jsonc"
    ],
    "modules-left": ["clock"],
    "modules-right": ["cpu"]
}
```

重複するプロパティは **先に定義された方が優先** される。ネストした include も可能。

---

## 3. モジュールの種類

### ビルトインモジュール（設定で使うもの）

| モジュール名 | 用途 | 主な format 変数 |
|-------------|------|-----------------|
| `hyprland/workspaces` | ワークスペース表示 | `{id}`, `{name}`, `{icon}` |
| `clock` | 時計 | strftime形式: `{:%H:%M}`, `{calendar}` |
| `pulseaudio` | 音量（PulseAudio） | `{volume}`, `{icon}`, `{format_source}` |
| `wireplumber` | 音量（WirePlumber） | `{volume}`, `{node_name}` |
| `network` | ネットワーク | `{ifname}`, `{essid}`, `{signalStrength}`, `{bandwidthUpBytes}` |
| `battery` | バッテリー | `{capacity}`, `{time}`, `{icon}` |
| `cpu` | CPU使用率 | `{usage}`, `{load}`, `{avg_frequency}`, `{icon}` |
| `memory` | メモリ使用率 | `{percentage}`, `{used}`, `{total}`, `{avail}` |
| `temperature` | 温度 | `{temperatureC}`, `{temperatureF}` |
| `mpris` | メディア再生情報 | `{player}`, `{status}`, `{title}`, `{artist}`, `{dynamic}` |
| `tray` | システムトレイ | - |

### カスタムモジュール

`custom/<name>` で、任意のスクリプトの出力を表示できる。天気表示などに使う。

```jsonc
"custom/weather": {
    "exec": "~/.config/waybar/scripts/weather.sh",
    "return-type": "json",         // スクリプトがJSON出力する場合
    "interval": 600,               // 10分ごとに実行
    "format": "{text}",
    "tooltip-format": "{tooltip}"
}
```

スクリプトの JSON 出力形式:
```json
{"text": "☀ 15°C", "tooltip": "札幌市 晴れ 15°C", "class": "sunny"}
```

---

## 4. グループとドロワー

### グループ（モジュールの束ね）

複数のモジュールを1つのグループにまとめられる。

```jsonc
{
    "modules-right": ["group/hardware", "clock"],

    "group/hardware": {
        "orientation": "horizontal",  // or "vertical", "inherit", "orthogonal"
        "modules": ["cpu", "memory", "temperature"]
    }
}
```

### ドロワー（展開/折畳）★重要

グループに `drawer` プロパティを追加すると、**最初のモジュールだけ表示し、ホバーまたはクリックで残りが展開** される。BlackNode のバーはこれを多用している。

```jsonc
"group/audio": {
    "orientation": "inherit",
    "drawer": {
        "transition-duration": 500,      // アニメーション時間（ms）
        "children-class": "hidden",      // 非表示要素のCSSクラス
        "click-to-reveal": false,        // true: クリックで展開、false: ホバーで展開
        "transition-left-to-right": true // 展開方向
    },
    "modules": [
        "pulseaudio",     // ← 常に表示（グループリーダー）
        "pulseaudio#microphone",  // ← 展開時のみ表示
        "network"                 // ← 展開時のみ表示
    ]
}
```

**ポイント:**
- `modules` 配列の最初の要素が「グループリーダー」で常に表示される
- 残りはドロワーが開いたときだけ表示
- `click-to-reveal: true` にするとホバーではなくクリックで展開

---

## 5. モジュールの複数インスタンス

同じモジュールを2つ以上置きたい場合、`#` で名前を付ける。

```jsonc
"modules-right": ["pulseaudio", "pulseaudio#microphone"],

"pulseaudio": {
    "format": "{volume}% {icon}"
},
"pulseaudio#microphone": {
    "format": "{format_source}"
}
```

CSSでは `#pulseaudio` と `#pulseaudio-microphone`（`#` が `-` に変換）でそれぞれスタイル指定。

---

## 6. 共通プロパティ

ほぼすべてのモジュールが持つ共通プロパティ:

| プロパティ | 説明 |
|-----------|------|
| `format` | 表示フォーマット |
| `format-icons` | パーセンテージに応じたアイコン配列（低→高） |
| `max-length` | 最大表示文字数 |
| `tooltip` | ツールチップの有効/無効 |
| `tooltip-format` | ツールチップのフォーマット |
| `on-click` | 左クリック時のコマンド |
| `on-click-right` | 右クリック時のコマンド |
| `on-click-middle` | 中クリック時のコマンド |
| `on-scroll-up` | スクロールアップ時のコマンド |
| `on-scroll-down` | スクロールダウン時のコマンド |
| `rotate` | テキスト回転（0, 90, 180, 270） |
| `expand` | 余ったスペースを消費するか |

---

## 7. states（状態ベースのスタイル切替）

一部モジュール（battery, cpu, memory等）は `states` で閾値を設定でき、CSSクラスとして適用される。

```jsonc
"battery": {
    "states": {
        "warning": 30,    // 30%以下で .warning クラスが付く
        "critical": 15    // 15%以下で .critical クラスが付く
    }
}
```

```css
#battery.warning { color: orange; }
#battery.critical { color: red; }
```

**注意:** battery は「以下」で判定、他のモジュール（cpu, memory等）は「以上」で判定。

---

## 8. style.css の基本

Waybar のCSSは GTK3 の CSS サブセット。Web の CSS と似ているが制約がある（flexbox不可など）。

### セレクタ

```css
/* バー全体 */
window#waybar { }

/* 特定モジュール */
#clock { }
#cpu { }
#memory { }
#battery { }
#network { }
#pulseaudio { }
#tray { }
#custom-weather { }  /* custom/<name> は #custom-<name> */

/* 状態付き */
#battery.charging { }
#battery.warning { }
#network.disconnected { }
#pulseaudio.muted { }

/* ホバー */
#clock:hover { }

/* ワークスペースボタン */
#workspaces button { }
#workspaces button.active { }
#workspaces button.empty { }
#workspaces button.urgent { }
```

### 外部CSSの読み込み

```css
@import url("colors.css");  /* Matugen生成カラーの読み込み等 */
```

### よく使うプロパティ

```css
#module-name {
    background-color: #1e1e2e;
    color: #cdd6f4;
    border-radius: 10px;
    padding: 0 10px;
    margin: 3px 2px;
    font-family: "JetBrainsMono Nerd Font";
    font-size: 14px;
    border: 2px solid #313244;
    transition: all 0.3s ease;   /* アニメーション */
}
```

---

## 9. マルチモニター対応

### 全モニターに同じバーを表示（デフォルト）

`output` を指定しなければ全モニターに表示される。

### 特定モニターのみ

```jsonc
{
    "output": "DP-2",
    ...
}
```

### モニター別に異なるバー

config.jsonc のトップレベルを配列にする:

```jsonc
[
    { "output": "DP-2", "modules-left": [...], ... },
    { "output": "DP-1", "modules-left": [...], ... }
]
```

---

## 10. シグナル（外部からの制御）

```bash
killall -SIGUSR1 waybar  # バーの表示/非表示トグル
killall -SIGUSR2 waybar  # バーのリロード
```

カスタムモジュールのシグナル更新:
```bash
pkill -RTMIN+8 waybar    # signal: 8 のモジュールを更新
```

---

## 11. デスクトップ仕様で使用するモジュール一覧

| バー上の表示 | モジュール | ドロワー |
|-------------|-----------|---------|
| CachyOS/Archアイコン | `custom/logo` | - |
| ワークスペース | `hyprland/workspaces` | - |
| メディア | `mpris` | - (クリック→別ポップアップ) |
| 音量 | `pulseaudio` | グループ展開 |
| ネットワーク | `network` | グループ展開 |
| バッテリー | `battery` | - |
| CPU/メモリ | `cpu`, `memory` | グループ展開 |
| 気温（札幌） | `custom/weather` | - |
| 通知ベル | `custom/notification` | - (swaync-client) |
| 電源ボタン | `custom/power` | - (wlogout起動) |
| 時計 | `clock` | - |

---

## ドキュメント参照先

| 内容 | 参照先 |
|------|--------|
| バー全体の設定 | `man 5 waybar` or `wiki/Waybar/man/waybar.5.scd.in` |
| CSS スタイリング | `man 5 waybar-styles` or `wiki/Waybar/man/waybar-styles.5.scd.in` |
| 各モジュール | `man 5 waybar-<module>` or `wiki/Waybar/man/waybar-<module>.5.scd` |
| states | `man 5 waybar-states` or `wiki/Waybar/man/waybar-states.5.scd` |
| デフォルト設定 | `/etc/xdg/waybar/config.jsonc`, `/etc/xdg/waybar/style.css` |
