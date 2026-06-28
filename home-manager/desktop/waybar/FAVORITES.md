# Waybar お気に入りテーマメモ

noro custom styles を巡る中で気に入ったやつの記録。新しく試したやつをここに足していく。

## 評価フォーマット

- **★★★** メイン候補 (常用したい)
- **★★** 場面で切り替え候補
- **★** 気になる点ありだが捨て難い
- **NG** 不採用

---

## ピン留め

### `capsule-nobg.css` ★★

- ws ボタンの形が好み
- 背景透過なので壁紙が透ける軽さ
- `capsule.css` の `group/sysstats` drawer 不具合 (idle_inhibitor がカプセル外にハミ出る) は **このテーマでは修正済み**
- 改造したい点:
  - `hyprland/window` がカプセル化されていない: capsule.css と同様にカプセル内に入れる調整が要る

### `glass-modern.css` ★★

- (後で評価メモ追記)

### `modern-tabs.css` ★★

- (後で評価メモ追記)

### `soft-gradient.css` ★★

- (後で評価メモ追記)

### `background-no-border.css` ★★

- (後で評価メモ追記)
- 注意: pulseaudio の左角が squared で浮く要修正系。entry で override すれば解消可

### `island.css` ★★

- (後で評価メモ追記)
- 注意: pulseaudio の左角が squared で浮く要修正系

### `capsule.css` ★

- 一応キープ (capsule-nobg の背景あり版)
- 注意: pulseaudio の左角が squared で浮く要修正系
- 改造したい点:
  - `group/sysstats` の drawer が壊れてる: `idle_inhibitor` がカプセル外にハミ出る
  - `{icon}` 系モジュール (`pulseaudio`, `sysstats`) はアイコンとカプセル枠の間にもう少し padding 欲しい
  - `hyprland/window` がカプセル化されていない: 使う時はカプセル内に入れる調整が要る

### `floating-glass-pills.css` ★★

- (後で評価メモ追記)

---

## 候補保留

(試したけど決めかねてるやつ。「次」で別を見たいけど捨てたくない時に残す)

---

## NG

(試して合わなかったやつ。理由メモしておくと後で重複試行を避けられる)

---

## まだ試してない

(全 20 種試行完了 ✓)

---

## 試した style

| # | style | 結果 |
|---|---|---|
| 1 | aurora-ribbon | (要評価) |
| 2 | capsule | **★ 一応キープ** (要修正系) |
| 3 | capsule-nobg | **★★ ピン留め** ws の形が好み |
| 4 | cyber-duo | (要評価) |
| 5 | floating-glass-pills | **★★ ピン留め** |
| 6 | glass-modern | **★★ ピン留め** |
| 7 | modern-glass | (要評価) |
| 8 | modern-tabs | **★★ ピン留め** |
| 9 | neon-glow-islands | (要評価) |
| 10 | soft-gradient | **★★ ピン留め** |
| 11 | zen | (要評価) |
| 12 | back-alllnoth-bor | (要評価) |
| 13 | back-alllnoth-nobor | (要評価) |
| 14 | back-noth-nbor | (要評価) |
| 15 | background-bordered | (要評価) |
| 16 | background-no-border | **★★ ピン留め** (要修正系: pulseaudio 左角張る) |
| 17 | island | **★★ ピン留め** (要修正系: pulseaudio 左角張る) |
| 18 | island-squared | (要評価) |
| 19 | styles3 | (要評価) |
| 20 | original | (移植デフォ、要修正系) |
