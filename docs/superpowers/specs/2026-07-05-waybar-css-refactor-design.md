# waybar 表示密度と CSS クラス構造の再設計

日付：2026-07-05
状態：ユーザー承認済みの設計を文書化したもの

## 背景と目的

現在の waybar は、モジュール間 24px と島間 18px の間隔が広すぎて島同士が圧迫し合い、center と right の島が衝突しやすい。
また CSS には、`hyprland/window` だけ島の質感を ID 直指定で複製する例外と、primary 色を持つモジュールを ID で列挙する記述が残っている。
本設計では、表示密度の調整と、「役割はクラス、個体は ID」を原則とする CSS クラス構造の再設計を行う。

## 前提（waybar ソースで確認した事実）

waybar のソース（`ghq/github.com/Alexays/Waybar`）で、CSS 命名の機構を確認した。

- 設定キーの `#` サフィックス（`<module>#<id>` と `group/<name>#<id>`）は、可視ノードに **CSS クラス**として付与される（`src/ALabel.cpp:41`、`src/group.cpp:35`）。
- 全モジュールの可視ノードには **`.module` クラス**が必ず付く（`include/AModule.hpp:20`）。
- privacy モジュールは例外で、`#` サフィックスの id クラスを可視ノードに付けない（`src/modules/privacy/privacy.cpp` は `box_.set_name(name_)` のみ）。
- eventbox の入れ子（島の eventbox の中に各モジュールの eventbox が並ぶ構造）は、クリック処理のための waybar 本体の実装であり、設定と CSS からは変更できない。本設計の対象外とする。

## 変更内容

### 1. 間隔トークンの縮小

`style/tokens.nix` の 2 トークンを縮小する。

- `gapModule`：12px から 7px へ（モジュール間の実効間隔 24px から 14px へ）
- `gapIsland`：9px から 6px へ（島間の実効間隔 18px から 12px へ）

### 2. sysstats の drawer 廃止と temperature の削除

`group/sysstats#island` の `drawer` 設定を削除し、hover 展開をやめて常時表示にする。
表示モジュールは cpu と memory の 2 つとし、temperature はモジュール定義ごと削除する（`settings/modules.nix` の定義と、CSS の `#temperature.critical` ルールも消す）。

### 3. マイク表示の pulseaudio への統合

pulseaudio の `format` に `{format_source}` を加え、スピーカーとマイクを 1 モジュール内に併記する（表示例：`󰕾 40% 󰍬 35%`）。

- `format-source`：`󰍬 {volume}%`
- `format-source-muted`：`󰍭`（ミュート時はアイコンのみ）
- `format-bluetooth` と `format-muted` にも同様に `{format_source}` を付加する

クリック動作（audio セレクタ起動）は現状のまま変えない。

### 4. network のアイコン化

`format-wifi` と `format-ethernet` をアイコンのみにする（「󰈀 ethernet」から「󰈀」へ）。
SSID とインターフェース名は既存の tooltip で確認できる。

### 5. CSS レイヤ構造

`style/mk-style.nix` を、カスケード順に単方向の 7 層へ再構成する。
下の層は上の層の寸法を上書きしない。色だけを持つ層（Role/State）に寸法を書かない。

| 層 | セレクタ | 責務 |
|---|---|---|
| 0 Reset | `*` | box-model の初期化のみ（margin、padding、border のゼロ化） |
| 1 Bar | `window#waybar` | タイポグラフィと基調色、透明背景 |
| 2 Island | `.island` | ガラス質感、角丸、`padIslandX`、`gapIsland` |
| 3 Module | `.module` | 透明化と `gapModule` |
| 4 Component | `#workspaces button` 系 | workspaces 固有の形状と状態 |
| 5 Role/State | `.accent`、`#<id>.<状態>` | 色のみ |
| 6 Surface | `tooltip` | 別サーフェスの装飾 |

現在 `*` リセットに混ざっている font 指定は、層 1 の `window#waybar` へ移す。
font 系プロパティは GTK CSS で継承されるため、`*` に置く必要がない。

### 6. 例外の解消

**`#window` の島例外の廃止**：`hyprland/window` を `hyprland/window#island` に改名する。
`#` サフィックスにより label 自体に `.island` クラスが乗るため、島の質感を `.island, #window` と列挙していた箇所が `.island` 単独になる。
空タイトル時のリセット（`window#waybar.empty #window`）だけは残す。

**`#workspaces` の名前衝突の解消**：group を `group/workspaces#island` から `group/ws#island` に改名する。
現在は group の box とモジュールの box が同名（どちらも `#workspaces`）で、セレクタが両方に当たりうる。
改名後は `#workspaces` がモジュール専用の一意な ID になる。

### 7. `.accent` ロールクラスの導入

静的に primary 色を持つモジュールを、ID 列挙からロールクラスへ集約する。

- `custom/nix#accent` と `custom/power#accent` に改名し、CSS は `.accent { color: @primary; }` の 1 ルールにする。
- privacy は id クラス非対応（前提の節を参照）のため、`#privacy` の ID ルールのまま残す。
- 状態依存の色（`.muted`、`.disconnected`、`.dnd-*`、`.activated`）は waybar が動的に付けるクラスなので、従来どおり `#<id>.<状態>` で書く。

## 影響ファイル

- `home-manager/desktop/waybar/style/tokens.nix`：間隔トークン 2 つの変更
- `home-manager/desktop/waybar/style/mk-style.nix`：レイヤ再構成、例外の解消、`.accent` 導入、temperature ルール削除
- `home-manager/desktop/waybar/style.css`：`style/render.sh` による再生成（手編集しない）
- `home-manager/desktop/waybar/settings/bar.nix`：drawer 削除、group とモジュールの改名
- `home-manager/desktop/waybar/settings/modules.nix`：temperature 削除、pulseaudio と network の format 変更、`custom/nix` と `custom/power` と `hyprland/window` のキー改名（`#` サフィックス付きの設定キーに合わせる）

## 検証

- `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。
- switch 後に実表示で確認する：島とモジュールの間隔、sysstats の常時 2 モジュール表示、マイク音量の併記、network のアイコン化、`custom/nix` と `custom/power` の primary 色維持、window 島の質感と空タイトル時の消灯。
