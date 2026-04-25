# Theming Pipeline

壁紙画像 1 枚から、各コンポーネントの色設定が自動生成されるまでの流れ。

## 全体フロー

```
                    ┌───────────────────┐
                    │   壁紙画像        │
                    │  (.jpg / .png)    │
                    └─────────┬─────────┘
                              │
            ┌─────────────────▼─────────────────┐
            │       wallset-backend.sh <image>        │
            │   (~/.config/hypr/scripts/)       │
            └─────────────────┬─────────────────┘
                              │ 並行実行
              ┌───────────────┴───────────────┐
              │                               │
              ▼                               ▼
     ┌─────────────────┐             ┌─────────────────┐
     │  awww img …     │             │  matugen image  │
     │  (見た目の変更)  │             │  (色生成)        │
     └─────────────────┘             └────────┬────────┘
                                              │
                                              ▼
                              ~/.config/matugen/templates/
                              に基づき各テンプレを fill して書き出し
                                              │
                ┌─────────────────┬───────────┴─────────┬─────────────────┐
                │                 │                     │                 │
                ▼                 ▼                     ▼                 ▼
          colors.conf     CSS/colors.css       walker/themes/         wlogout/
        (Hyprland 用)    (Waybar 用)         matugen/colors.css     colors.css
                │                 │                     │                 │
                │                 ├─ post_hook:         │                 │
                │                 │  waybar-reload-     │                 │
                │                 │  css.sh             │                 │
                │                 │  (style.css を      │                 │
                │                 │   in-place rewrite) │                 │
                │                 │                     │                 │
                ▼                 ▼                     ▼                 ▼
         hyprctl keyword    waybar の          walker 起動時       wlogout 起動時
         source colors.conf  reload_style_     に新色を読込         に新色を読込
                │            on_change で
                │            CSS だけ live
                ▼            reload (surface 維持)
         Hyprland の枠色等
         が即時更新
```

## 起動経路

### 経路 A: 手動 (Super+W)

```
Super+W
  └─▶ walker --provider menus:wallselect (Hyprland keybind)
        └─▶ Elephant の menus/wallselect.lua provider が ~/pictures/wallpaper を列挙
              └─▶ ユーザが画像を選択
                    └─▶ Actions.activate = ~/.config/hypr/scripts/wallset-backend.sh <path>
```

### 経路 B: 起動時 (autostart)

```
Hyprland 起動
  └─▶ exec-once = ~/.config/hypr/scripts/wallset-backend-startup.sh
        ├─▶ awww-daemon を spawn (まだ起きていなければ)
        └─▶ WALLSET_RANDOM_ON_STARTUP の値で分岐:
              ├─ true:  ~/pictures/wallpaper から直前と被らない画像を選択
              │         → exec wallset-backend.sh <picked>  (経路 A の後半と同じ全パイプライン)
              └─ false: awww restore (前回 session の壁紙を per-monitor cache から復元)
                        ※ 色再生成は走らせず、前回の生成物をそのまま使う
```

`WALLSET_RANDOM_ON_STARTUP` は `wallset-backend-startup.sh` 冒頭の変数で切り替える (将来 settings UI から制御予定)。直前と同じ画像を再選択しないよう `~/.cache/last_wallpaper` を読み書きする。

## 各色生成ツール

### matugen

| 項目 | 値 |
|---|---|
| 役割 | Material You 3 パレットを画像から抽出 |
| 設定 | `~/.config/matugen/config.toml` |
| テンプレ | `~/.config/matugen/templates/<app>-<subject>.<ext>` |
| 出力先 | 各 consumer の設定ディレクトリ直下 |

`config.toml` で各 `[templates.<app>]` セクションが input/output を定義:

| App | Input template | Output |
|---|---|---|
| Hyprland | `templates/hyprland-colors.conf` | `~/.config/hypr/colors.conf` |
| Waybar | `templates/waybar-colors.css` | `~/.config/waybar/CSS/colors.css` |
| Walker | `templates/walker-colors.css` | `~/.config/walker/themes/matugen/colors.css` |
| Wlogout | `templates/wlogout-colors.css` | `~/.config/wlogout/colors.css` |

Waybar のみ **`post_hook = "~/.config/hypr/scripts/waybar-reload-css.sh"`** を持つ。詳細は [scripts.md](./scripts.md#waybar-reload-csssh) 参照。

## Hyprland への色適用が「外科的」である理由

Hyprland は `misc:disable_autoreload = true` で **config 自動 reload を無効化**している。matugen が `colors.conf` を書き換えても、Hyprland は何もしない。

`wallset-backend.sh` は最後に明示的に `hyprctl keyword source ~/.config/hypr/colors.conf` を叩いて、**colors.conf だけを再 source** する。これが「外科的 reload」。

なぜ全 reload (`hyprctl reload`) を避けるか:

- `hyprctl reload` は `monitors.conf` も再評価する
- `monitors.conf` は **desk-mode の真**(HDMI-A-1 disable, DP-* enable)
- **bed-mode** 中(=runtime で動的に重ねた状態)に reload すると、bed-mode が吹き飛んで desk-mode に戻ってしまう

色だけを source する方式なら monitor 構成は無傷。

## Waybar の CSS reload trick

waybar には `reload_style_on_change: true` 設定がある。これは **`style.css` の inode 変更**を GIO FileMonitor で監視している。matugen が書く `CSS/colors.css` は `style.css` から `@import` されているだけなので、`colors.css` を書き換えても Waybar の reload は発火しない。

そこで **`waybar-reload-css.sh`** が `style.css` を一旦 truncate して同じ内容で書き戻す。これで `CHANGES_DONE_HINT` イベントが発火し、Waybar が CSS だけを reload する。

`SIGUSR2` を送る方法もあるが、それだと surface を完全再生成するため exclusive_zone が一瞬消えてタイル window が再レイアウトでガクつく。in-place rewrite trick なら surface 維持で滑らか。

## 反映タイミングまとめ

| Consumer | 反映 | レイテンシ |
|---|---|---|
| awww (壁紙) | `awww img` の transition (3 秒) で滑らかに切替 | 即時 |
| Hyprland (枠色) | `hyprctl keyword source` で即時 | 〜100ms |
| Waybar | `style.css` rewrite → reload_style_on_change 発火 | 即時、ガクつき無し |
| Walker | プロセス再起動 / 起動時のみ反映 | 次回起動時 |
| Wlogout | プロセス再起動 / 起動時のみ反映 | 次回起動時 |

Walker と Wlogout は常駐プロセスでないため再起動が必要なケースがあるが、`Super+W` 等で起動時に毎回 CSS を読み直すので実害は小さい。

## bed-mode との独立性

壁紙変更パイプラインは **monitor 構成に一切触らない**。

- ❌ wallset-backend.sh は `hyprctl reload` を呼ばない (`hyprctl keyword source` のみ)
- ❌ matugen は `monitors.conf` を書かない
- ❌ Hyprland autoreload は無効化済み

結果、bed-mode 中に壁紙を変更しても bed-mode が維持される。これが今日確立した最重要の設計不変量。

## 関連ドキュメント

- [Architecture](./architecture.md) — システム全体像
- [File Structure](./file-structure.md) — ファイルレイアウト
- [Scripts Reference](./scripts.md) — 各スクリプトの実装詳細
