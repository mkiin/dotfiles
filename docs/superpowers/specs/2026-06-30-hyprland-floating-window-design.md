# Hyprland タイルウィンドウ「浮遊感」リファクタ 設計書

作成日: 2026-06-30

## 目的

[atif-1402/anom-dots](https://github.com/atif-1402/anom-dots) のHyprlandウィンドウデザインが持つ「影」と「浮いている感じ」を、自分の設定に取り入れる。不透明でフラットな現状から、すりガラス状に透ける窓・大きく柔らかい影・光る縁を持つ「背景から持ち上がった」見た目へ変更する。

## スコープ

### 対象

- `home-manager/desktop/hyprland/lua/appearance.lua` の `general` と `decoration` セクションのみ

### 対象外（変更しない）

- アニメーション設定（既存の凝った bezier / animation 定義はそのまま尊重）
- `color-scheme.lua` の色・グラデーション定義（既に primary→tertiary のグラデーションボーダーが定義済み）
- その他すべての設定ファイル

## 背景・分析

atif-1402 の浮遊感は主に4要素の組み合わせで成立している。自分の現状と比較した結果が以下。

| 要素            | 現状                     | atif-1402                     | 浮遊感への寄与       |
| --------------- | ------------------------ | ----------------------------- | -------------------- |
| 影 (shadow)     | range=8, power=3, 色付き | range=15, power=5, offset 0 0 | ★★★ 最大             |
| 透過 (opacity)  | なし (=不透明)           | active=0.93, inactive=0.92    | ★★★                  |
| ボーダー        | border_size=0 (非表示)   | size=1 グラデーション         | ★★                   |
| 角丸 (rounding) | 10                       | 14                            | ★                    |
| ブラー          | size=3, passes=2         | size=1, passes=4 + 質感調整   | 透過時の背景ガラス感 |

なお、グラデーションボーダー（primary→tertiary, 45deg）は `color-scheme.lua` に定義済みだが、`appearance.lua` の `border_size = 0` により非表示になっている。素材は揃っている状態。

## ビルド機構

`default.nix` で `wayland.windowManager.hyprland.configType = "lua"` を使用。`hl.config()` のネストテーブルはそのまま Hyprland の設定キーにマップされるため、新規キー（`offset` / `contrast` / `vibrancy` / `noise` 等）はすべて表現可能。

注意: ベクトル値の `offset` は文字列 `"0 0"` として渡す。

## 設計詳細

### general

| キー          | 現状 | 変更後        | 備考                           |
| ------------- | ---- | ------------- | ------------------------------ |
| `gaps_in`     | 3    | 3（据え置き） | 影を見せる余白を確保           |
| `gaps_out`    | 8    | 8（据え置き） | 同上                           |
| `border_size` | 0    | **1**         | 定義済みグラデーションを有効化 |

### decoration

| キー                 | 現状       | 変更後                                |
| -------------------- | ---------- | ------------------------------------- |
| `rounding`           | 10         | **14**                                |
| `active_opacity`     | (なし=1.0) | **0.93**（新規）                      |
| `inactive_opacity`   | (なし=1.0) | **0.92**（新規）                      |
| `fullscreen_opacity` | (なし)     | **1.0**（新規・全画面は不透明に戻す） |

### decoration.shadow

| キー             | 現状           | 変更後            |
| ---------------- | -------------- | ----------------- |
| `enabled`        | true           | true              |
| `range`          | 8              | **15**            |
| `render_power`   | 3              | **5**             |
| `offset`         | (なし)         | **"0 0"**（新規） |
| `color`          | rgba(00000080) | **削除**          |
| `color_inactive` | rgba(00000033) | **削除**          |

影の色を削除することで Hyprland デフォルトの濃い影になり、atif の見た目に揃う。

### decoration.blur

| キー                | 現状   | 変更後            |
| ------------------- | ------ | ----------------- |
| `enabled`           | true   | true              |
| `size`              | 3      | **1**             |
| `passes`            | 2      | **4**             |
| `contrast`          | (なし) | **1.1**（新規）   |
| `brightness`        | (なし) | **1.1**（新規）   |
| `vibrancy`          | (なし) | **0.2**（新規）   |
| `vibrancy_darkness` | (なし) | **0.2**（新規）   |
| `noise`             | (なし) | **0.03**（新規）  |
| `ignore_opacity`    | true   | true（据え置き）  |
| `new_optimizations` | true   | true（据え置き）  |
| `xray`              | false  | false（据え置き） |

## 期待される結果

不透明でフラットだった現状から、すりガラス状に透けるウィンドウ・大きく柔らかい影・primary→tertiary の光る縁を持つ状態になり、各タイルが背景から持ち上がって浮いて見える。ギャップは現状維持のため影がしっかり視認できる。

## 検証方法

1. `home-manager switch`（または通常のリビルド手順）を実行
2. Hyprland に反映されることを確認
3. 透過が強すぎる場合は `active_opacity`、影が濃すぎる場合は `shadow.range` を微調整

## 決定事項の記録

- 透過: atif準拠（active=0.93 / inactive=0.92）
- ギャップ: 現状維持（in=3 / out=8）
- ボーダー: 有効化（size=1、定義済みグラデーション利用）
- 影: atif準拠（range=15 / power=5 / offset 0 0、色はデフォルト化）
- ブラー: atif準拠（質感調整キーを追加）
- 角丸: 14
