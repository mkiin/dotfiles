# デスクトップ仕様書

## シェル
- バー: Waybar
- 通知 / コントロールセンター: Swaync
- ロック画面: Hyprlock
- ログイン画面: SDDM（カスタムテーマ）
- ランチャー: Rofi
- 壁紙: awww
- 電源メニュー: Wlogout

## カラーテーマ
- 壁紙から自動生成 (Matugen / Wallust)
- 壁紙切替時のアニメーション: 同心円状に広がるトランジション (awww `--transition-type grow`)

---

## バー

### 基本設定
- 位置: 上
- スタイル: BlackNode参考（左右グループ配置、明確な中央セクションなし）
- グループ展開: あり（クリックでバー内スライド展開/折畳）

### 配置

- グループ1
  - CachyOS / Arch Linux アイコン
- グループ2
  - ワークスペース表示
- グループ3
  - メディア表示（クリック → 別ポップアップ）
- グループ4
  - グループ4.1
    - 音量(スピーカ) - フォーマット アイコン 音量%
    - 補足 : Bluetoothの場合, {icon} 󰂰 {volume}%
  - グループ4.2
    - ネットワーク状態 フォーマット アイコン
      - 補足 ： wifiとethernetで分けるように
    - bluetooth - フォーマット アイコン 
      - 補足：bluetoothのON・OFFでアイコンを分けるように
- グループ5
  - 日付 - フォーマット未定
  - 時間 - フォーマットhh:mm
  - 気温 - 天気アイコン 温度
- グループ6
  - CPU - フォーマット アイコン %
  - CPU温度 - フォーマット アイコン %
  - メモリ - フォーマット アイコン %
- グループ7
  - 通知 - フォーマット 数字 通知ベルアイコン
  - discord - フォーマット アイコン
  - アイドルモード移行ボタン - フォーマット アイコン
- グループ8
 - 電源ボタン - フォーマット アイコン

### 参考
- BlackNode, arch-hyprland

---

## コントロールセンター（ドロワー）

### 基本設定
- 展開位置: 右端からスライド
- 参考: dotfiles-Hyprland, dots-hyprland, kurusaka

### 内部ウィジェット
- 電源ボタン（シャットダウン / 再起動 / サスペンド / ロック）
- Bluetooth デバイス管理（完結）
- 音量スライダー（下三角矢印 → 接続デバイス選択、hyprzepyx参考）
- マイク音量スライダー（同上）
- 明るさスライダー（デスクトップで機能するか要検証）
- 通知リスト
- カレンダー

---

## メディアプレーヤーポップアップ

### 基本設定
- バーのメディア表示をクリックで開く
- 形状: 正方形
- バーとは別の独立ポップアップ

### 内容
- アルバムアート
- 再生コントロール（再生/停止/前/次）
- アーティスト / 曲名
- オーディオビジュアライザー

### 対応ソース
- Discord, YouTube

---

## システムモニターポップアップ

### 基本設定
- バーのCPU/メモリ表示をクリックで開く

### 表示項目
- CPU使用率
- メモリ使用率
- GPU使用率 / 温度
- ディスク使用量
- ネットワーク帯域（上り / 下り）
- 稼働時間（uptime）

---

## ロック画面

### 表示内容
- 時計
- 日付
- アニメ画像 or アバター
- 迎える言葉（BlackNode, botti-the-lock参考）
- パスワード入力

### 参考
- BlackNode, botti-the-lock

---

## 通知

### ポップアップ通知
- 位置: 右上
- アニメーション: ニュルっとスライドイン
- イベント発火で自動表示

### 通知リスト
- コントロールセンター内に配置

---

## 壁紙セレクタ

### 基本設定
- キーバインドで開く
- UI: 左に壁紙プレビュー、右にセレクタ

### 参考
- arch-hyprland

---

## ランチャー

### 基本設定
- ツール: Rofi

### 参考
- arch-hyprland, BlackNode

---

## スクリーンショット
- ツール: Hyprshot
- 操作: キーバインドのみ

---

## アイドル管理
- ツール: Hypridle
- 段階設定は後で決定

---

## 電源メニュー

### アクション
- シャットダウン
- 再起動
- サスペンド
- ロック

### アクセス方法
- バーの電源ボタン（単一ボタン）
- コントロールセンター内の電源ボタン

---

## ログイン画面 (SDDM)

### 基本設定
- QMLカスタムテーマ
- Hyprlock と雰囲気を統一
- 詳細は後で決定

### 参考
- kurusaka-dotfiles (Astronaut テーマ), botti-the-lock

---

## ドキュメント参照順

| ツール | 一次ソース | 補助 |
|--------|-----------|------|
| Waybar | `man 5 waybar`, `man 5 waybar-styles` | GitHub Wiki (モジュール別ページ), `/etc/xdg/waybar/` サンプル |
| Swaync | `man 5 swaync` | GitHub README, `/etc/xdg/swaync/` デフォルト設定 |
| Rofi | `rofi(1)`, `rofi-theme(5)`, `rofi-script(5)` | https://davatorium.github.io/rofi/ |
| Wlogout | `man 5 wlogout` | `/etc/wlogout/layout` サンプル |
| SDDM | `man 5 sddm.conf`, `docs/THEMING.md` | GitHub Wiki, ArchWiki |
| Hyprlock | Hyprland Wiki | サンプル設定 |
| Hypridle | Hyprland Wiki | サンプル設定 |
| Hyprshot | GitHub README | - |
| awww | `man awww-img` | GitHub README |

---

## ファイル構成

```
config/
├── hypr/
│   ├── hyprland.conf              # メイン（sourceで各confを読み込み）
│   ├── monitors.conf              # モニター設定
│   ├── autostart.conf             # 起動プログラム（waybar, awww, swaync等）
│   ├── appearance.conf            # 見た目（gap, border, animation, blur）
│   ├── keybinds.conf              # キーバインド
│   ├── input.conf                 # 入力設定
│   ├── rules.conf                 # ウィンドウルール
│   ├── colors.conf                # Matugen/Wallust自動生成カラー
│   ├── hypridle.conf              # アイドル管理
│   ├── hyprlock.conf              # ロック画面
│   └── scripts/
│       └── switchwall.sh          # 壁紙切替（awww grow トランジション）
│
├── waybar/
│   ├── config.jsonc               # メインレイアウト（モジュール配置+グループ定義）
│   ├── style.css                  # メインスタイル
│   ├── colors.css                 # Matugen/Wallust自動生成カラー
│   ├── modules/                   # モジュール個別定義（BlackNode方式）
│   │   ├── clock.jsonc
│   │   ├── workspaces.jsonc
│   │   ├── cpu.jsonc
│   │   ├── memory.jsonc
│   │   ├── network.jsonc
│   │   ├── battery.jsonc
│   │   ├── pulseaudio.jsonc       # 音量 + マイク
│   │   ├── temperature.jsonc
│   │   ├── weather.jsonc          # 札幌気温（customモジュール）
│   │   ├── mpris.jsonc            # メディア表示
│   │   └── power.jsonc            # 電源ボタン（→ wlogout起動）
│   └── scripts/
│       └── weather.sh             # 天気取得スクリプト
│
├── swaync/
│   ├── config.json                # 通知 + コントロールセンター
│   └── style.css                  # スタイル（Matugen連携）
│
├── rofi/
│   ├── config.rasi                # ランチャー設定
│   └── theme.rasi                 # テーマ
│
├── wlogout/
│   ├── layout                     # 電源メニューボタン定義
│   └── style.css                  # スタイル
│
├── sddm/                          # SDDMカスタムテーマ
│   └── themes/
│       └── custom/
│           ├── Main.qml           # エントリポイント
│           ├── metadata.desktop   # テーマメタデータ（QtVersion=6含む）
│           ├── theme.conf         # テーマ設定
│           └── Assets/            # 背景画像、アイコン等
│
├── matugen/
│   ├── config.toml                # Matugen設定
│   └── templates/                 # 各アプリ向けカラーテンプレート
│       ├── hyprland-colors.conf
│       ├── waybar-colors.css
│       ├── swaync-colors.css
│       └── wlogout-colors.css
│
└── awww/                          # awww設定（必要に応じて）
```

### 設計方針
- **Waybar**: モジュール分割（BlackNode方式）。config.jsoncでは配置とグループのみ定義、各モジュールの詳細は modules/ に分離
- **Hypr**: 既存の分割構成を維持。autostart.conf の中身を Waybar/awww/swaync 起動に変更
- **Matugen テンプレート**: waybar-colors.css, swaync-colors.css, wlogout-colors.css を追加して壁紙連動テーマを実現
- **SDDM テーマ**: /usr/share/sddm/themes/ にシンボリンクまたはコピーして配置。dotfiles リポジトリで管理
