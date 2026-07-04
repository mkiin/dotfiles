# 起動時WS配置 + workspaces_follow_focus 設計書

- 日付: 2026-07-04
- 対象: `home-manager/desktop/hyprland/monitors/desk.lua`（workspace_rule 復活）
- 前提: pyprland `workspaces_follow_focus` は導入済み・稼働中。モニター物理入替対応（DP-1↔DP-3 の位置入替）は commit `34626e3` で反映済み。

## 目的

起動時に各モニターが決まったワークスペースを表示する（中央 DP-2=メインに WS1）。加えて `workspaces_follow_focus` の恩恵をフルに得るため `persistent` は付けず（`default` のみ）、WS1..10 すべてがフォーカス/マウスに追従できるようにする。

## 背景（なぜ今こうなっているか）

以前の pyprland 導入時（Task 2）に、follow_focus のために `workspace_rule`（monitor 指定 + default）を撤去した。これが行き過ぎで、起動時のWS割り当てが Hyprland のデフォルト任せになり、左から 1,2,3 に揃わなくなっていた。follow_focus は「起動時の割り当て」を決めるプラグインではない（後述）ため、初期配置は workspace_rule で別途固定する必要がある。

## workspaces_follow_focus の役割（ソース確認済み）

`workspaces_follow_focus.py` が行うのは2つだけ:

1. **`event_focusedmon`**: フォーカスするモニターが変わると、他モニターに表示されていない「空きWS」をそのモニターへ集める（`follow_mouse=1` なのでマウス移動でも発火＝"follow the mouse"）。
2. **`run_change_workspace`（`pypr change_workspace ±1` / SUPER+I/O）**: 現在のモニター上で、他モニターに出ているWSを飛ばして空きWSを順送りする。

**番号キー（SUPER+数字）はフックしない。** 起動時の割り当ても決めない。

## 固定と follow_focus は両立する（根拠）

`_handle_focusedmon` は「他モニターの activeWorkspace（busy）」を移動対象から除外する。したがって WS1/2/3 が各モニターの active であれば busy 扱いで**動かされない**。移動されるのは WS4 以降の空きWSのみ。よって「基準の1,2,3はモニター固定、余りは追従」が成立する。

## 決定事項（確定）

| 論点             | 決定                                                                                                                       |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------- |
| 起動時WS配置     | 中央DP-2(メイン)=WS1 / 左DP-1=WS2 / 右DP-3=WS3                                                                             |
| workspace_rule   | `default = true` のみ（persistent なし）。初期配置は決めるが空WSは消え、follow_focus の追従対象に戻る（フル follow_focus） |
| 起動時フォーカス | **後回し**（本スコープ外）。初期配置固定と follow_focus 試用を先に入れる                                                   |
| follow_focus     | **残す**（試用）。persistent を付けないので WS1..10 すべてが追従・順送りの対象になる                                       |
| SUPER+数字       | 当面 native のまま（WS2/3を押すとそのモニターへフォーカス移動）。将来 `focusworkspaceoncurrentmonitor` に変える余地        |

## アーキテクチャ / コンポーネント

### 1. 変更: `monitors/desk.lua`

monitor 定義（既存・入替済み）の下に workspace_rule を追加:

```lua
hl.monitor({ output = "DP-1", mode = "1920x1080@60", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@180", position = "1920x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@100", position = "4480x0", scale = 1 })
hl.monitor({ output = "HDMI-A-1", disabled = true })

hl.workspace_rule({ workspace = "1", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", default = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-3", default = true })
```

### 2. 起動時フォーカス（後回し）

「起動時にメインへフォーカスを乗せる」は**本スコープ外（後回し）**。まず workspace_rule による初期配置固定と follow_focus 試用を先に入れ、フォーカス制御は使い勝手を見てから別途検討する。

### 3. bed.lua は対象外

bed は HDMI-A-1 単一モニターのため、WS↔モニター固定の論点は無い。変更しない。

## 使い方レクチャー（試用ガイド。plan / README 相当に残す）

`workspaces_follow_focus` を「単一モニター的自由度」として体感するための操作:

- **基準運用**: 起動直後、中央=WS1 / 左=WS2 / 右=WS3。ここからメインで作業開始。
- **今の画面でWSをめくる**: `SUPER+O`（次の空きWS）/ `SUPER+I`（前の空きWS）。他画面に出ているWSは自動で飛ばす。これが「単一モニターのようにパラパラめくる」体験。
- **WSを手元に呼ぶ（追従）**: フォーカス（またはマウス）を別モニターへ移すと、空いているWS（4以降）がその画面に寄ってくる。
- **試すときの着目点**: (a) SUPER+I/O で中央画面だけでWS4,5,6…を回せるか、(b) マウスを別画面へ動かしたとき空きWSが付いてくる感覚が「便利」か「うるさい」か。この2点で follow_focus を残すか外すかを判断する。
- **うるさい場合の退避**: follow_focus だけ外せば追従は止まり、`default` による起動時の 1,2,3 初期配置だけが残る。

## 既知のエッジ / リスク

1. **空になったWSは消える（意図した挙動）**: `persistent` を付けないので、WS2/WS3 をそのモニターの active から外す（例: 左DP-1で SUPER+O して WS5 にする）と、WS2 は空になり消える。これは「全WSを follow_focus 対象にする」ための仕様であり、常時 1,2,3 が並ぶ保証は無い。
2. **mode.sh 連携**: bed/desk 切替時にも desk の workspace_rule が効く。切替後にWS配置が固定通りに戻るか実機確認。

## 検証手順

1. `nix run .#build` 通過、`nix run .#fmt -- --fail-on-change` 通過。
2. `nix run .#switch` 後、`~/.config/hypr/scripts/mode.sh desk`（or `hyprctl reload`）:
   - 中央DP-2=WS1 / 左DP-1=WS2 / 右DP-3=WS3 になっている。
   - `hyprctl monitors -j | jq '.[]|{name,activeWorkspace:.activeWorkspace.name,focused}'` で確認。
   - SUPER+I/O で中央画面上を空きWSでめくれる。
   - マウスを別画面へ移すと空きWSが追従する。
3. `journalctl --user -u pyprland -f` にエラーが出ない。

## ロールアウト後の残タスク（スコープ外）

- 使い勝手判断の結果、follow_focus を外す / SUPER+数字を `focusworkspaceoncurrentmonitor` に変える、等の調整。
- todo.md「pyprland の導入 / workspace_follow_focus」項目の更新。
  </content>
