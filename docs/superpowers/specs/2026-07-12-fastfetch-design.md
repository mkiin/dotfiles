# fastfetch 導入 設計

日付: 2026-07-12
対象 repo: mkiin/dotfiles（NixOS 実機 + WSL home-manager）

## 目的

fastfetch を導入し、次の 2 経路で表示できるようにする。

1. `ff` 直叩き（両環境）
2. pyprland scratchpad をキーでトグル（実機 NixOS のみ）

配色は壁紙連動させたいが、fastfetch 自体は薄い設定に留め、専用のカラーテンプレートや fallback ファイルを増やさない。

## 決定事項と根拠

### 表示経路は 2 つ、レイヤーで住み分ける

- fastfetch 本体と設定は `home-manager/cli/`（両環境が import）。
- scratchpad 配線は `home-manager/desktop/`（実機のみ。WSL は desktop を import しない）。

WSL には Hyprland も pyprland も無いため、scratchpad は自動的に不在になる。追加の分岐は不要。

### scratchpad の挙動: 一度描画して静止

fastfetch は「表示して即終了」するツール。scratchpad では `lazy = true` で初回トグル時に wezterm を spawn し、`fastfetch` を 1 回描画してからシェルへ落としてホールドする。以降のトグルは同一ウィンドウの表示 / 非表示のみで、再計算しない。

### 配色: パターン B（ANSI パレット委譲）

実装調査（saatvik333/hyprland-dotfiles 他）の結果、実運用の主流は「fastfetch は ANSI 色名 / 番号だけ指定し、実際の色は端末の 16 色パレット任せ、その端末を wallust が塗り替える」方式だった。fastfetch は設定の部分 include を持たないため、truecolor 焼き込み（パターン A）は設定まるごと生成になり重い。

本 repo の wallust は既に wezterm.toml / ghostty.conf テンプレートを生成しており、scratchpad の host 端末（wezterm）は wallust テーマ済み。したがって fastfetch を ANSI 色名で書くだけで、テンプレート追加ゼロで壁紙連動する。

WSL では wallust が動かないが、Windows 側 wezterm.exe の端末テーマがそのまま fallback として機能する（ANSI 名が端末パレットに解決されるだけ）。専用 fallback ファイルは不要。

### host 端末: wezterm

wallust テーマ済み。既存の `terminal` 変数とも揃う。

### キーバインド: SUPER + SHIFT + F

`F`（fetch）のニーモニック。`SUPER+F` は fullscreen、`SUPER+I` は workspace 移動で使用中のため SHIFT 付き。

### ロゴ: fastfetch 内蔵 `nixos`

ファイル / メンテ不要。ANSI 色指定で壁紙追従も効く。

### エイリアスは abbr で定義

本 repo の zsh は shellAliases と zsh-abbr を併用。`ff` は abbr 側（`cli/zsh/default.nix` の initContent の abbr 群）に置く。

### 見た目の window_rule は追加しない

Hyprland 本体（appearance.lua）は `rounding = 14` / `border_size = 0` / `blur.enabled = true` を全ウィンドウに適用し、opacity の減衰は掛けていない（不透明運用）。フロートの scratchpad はこれらを自動継承するため、専用の見た目ルールを足すと冗長になるか、opacity を下げれば本体の不透明運用から外れる。「本体設定に合わせる」= 継承に任せる = ルールを書かない、が正解。

geometry（size / position / animation）だけ pyprland scratchpad 側で指定する。pyprland がウィンドウを自動 float 化して geometry を管理するため、Hyprland 側で float / size / position を重ねると競合する。

## ファイル変更

### 共通（cli / 両環境）

| ファイル                                          | 変更                                                                                    |
| ------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `home-manager/cli/packages.nix`                   | `fastfetch` を集約宣言に追加                                                            |
| `home-manager/cli/fastfetch/default.nix`（新規）  | `xdg.configFile."fastfetch/config.jsonc".source = lnk ./config.jsonc;` のみ（設定専用） |
| `home-manager/cli/fastfetch/config.jsonc`（新規） | logo = `nixos`、キー / ロゴ色は ANSI 名、モジュール群                                   |
| `home-manager/cli/default.nix`                    | imports に `./fastfetch` を追加                                                         |
| `home-manager/cli/zsh/default.nix`                | initContent の abbr 群に `abbr ff="fastfetch"` を追加                                   |

### 実機のみ（desktop）

| ファイル                                         | 変更                                                                                                                                                      |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `home-manager/desktop/pyprland/default.nix`      | `plugins` に `"scratchpads"` を追加。`[scratchpads.fetch]` を定義。既存の「scratchpads 見送り」コメントを「fetch 用に採用・vesktop は引き続き除外」へ是正 |
| `home-manager/desktop/hyprland/lua/keybinds.lua` | `SUPER + SHIFT + F` → `pypr toggle fetch`                                                                                                                 |

### 触らない

- `home-manager/desktop/wallust/`（パターン B のためテンプレート追加不要）
- `home-manager/desktop/hyprland/lua/rules.lua`（本体設定を継承）

## 主要スニペット（実装時の指針。最終形はビルドで調整）

### config.jsonc（cli/fastfetch）

- `logo.source = "nixos"`、`logo.color` は ANSI 名（例: `"1": "blue"`）。
- modules: title / separator / OS / host / kernel / uptime / packages(nix) / shell / WM / terminal / CPU / GPU / memory / disk / colors bar。
- `display.color.keys` 等も ANSI 名で指定し、wallust テーマ済み端末に追従させる。

### pyprland `[scratchpads.fetch]`

```toml
[scratchpads.fetch]
command = "wezterm start --class fetch-scratch -- sh -c 'fastfetch; exec $SHELL'"
class = "fetch-scratch"
size = "50% 55%"
position = "25% 22%"
animation = "fromTop"
lazy = true
unfocus = "hide"
```

### keybinds.lua

```lua
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("pypr toggle fetch"))
```

## 動作

- 実機: `SUPER+SHIFT+F` 初回で wezterm 起動 → fastfetch 描画 → ホールド。以降トグルで出し入れ。壁紙変更で端末パレットが変わり、次回起動時に色追従。`ff` 直叩きも同 config。
- WSL: scratchpad は不在。`ff` / `fastfetch` は動作、色は Windows 側 wezterm の端末テーマ = 自動 fallback。

## 既知の注意点

- WSL が NixOS-WSL でない場合、内蔵 `nixos` ロゴが実体と食い違う可能性。その場合は logo を auto 検出へ変える余地を残す。
- `X-Restart-Triggers` により pypr の systemd unit は config 変更で再起動されるため、scratchpad 追加は switch で反映される。

## 検証

- `nix run .#build`（実機構成ビルド）
- `nix run .#fmt -- --fail-on-change`（deadnix / 整形）
