# pyprland プラグイン群 導入 設計書

- 日付: 2026-07-04
- 対象: `home-manager/desktop/pyprland/` および `home-manager/desktop/hyprland/`（keybind / monitors / mode.sh）
- 前提: `wallpapers` プラグインは 2026-07-02 の設計で導入済み。本設計はその `config.toml` を拡張する。

## 目的

todo「pyprland の導入」の残プラグインを導入する。ワークスペースをモニターから切り離し（1モニターで複数WSを保持）、
scratchpad / 窓退避 / 迷子窓救出 / fcitx5 自動切替を追加する。

## スコープ

導入する5つ:

- `workspaces_follow_focus` … WS↔モニター固定を解き、フォーカス中モニターへWSを引き寄せる（純follow）
- `scratchpads` … btop / ドロップダウン端末 / vesktop をキー一発トグル
- `toggle_special` … フォーカス窓を special へ退避/復帰（native の SUPER+S 置換）
- `lost_windows` … 画面外に消えた窓を現WSへ集める
- `fcitx5_switcher` … 端末/ゲームで日本語入力を自動 OFF

## スコープ外（今回やらないこと）

- **`monitors` プラグイン**: 見送り。理由は下記「monitors を見送る判断」。bed/desk 切替は現行 `mode.sh` を維持し、follow_focus 導入に伴い軽量化する。
- 壁紙 / 色パイプライン（`wallpapers` は導入済み。変更しない）。
- scratchpad へのメモ/電卓など追加アプリ（枠だけ作らず、必要になったら追加）。

## monitors を見送る判断（記録）

- bed(HDMI-A-1 の TV) と desk(DP-1/2/3 の3枚) は**常時同時接続**され、`mode.sh` は「どのモニターを enable/disable するか」を切り替えるプロファイルトグルである。
- pyprland `monitors` は**モニターの接続イベント(hotplug)に反応**して配置・スケールを当てるプラグインで、常時接続下ではイベントが発火せず、キーバインドでのプロファイルトグルは守備範囲外。
- 現 `mode.sh` は enable/disable に加え、reload 後の **awww/waybar 再生成 + workspace 復元**という非自明な後処理を持つ。`monitors` はそこを代替しないため、置換は機能退行になる。
- 結論: `monitors` は導入しない。todo の当該項目は「プラグイン実態と不一致のため見送り」としてクローズする。

## 決定事項（確定）

| 論点                | 決定                                                                                                                                            |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| config 構造         | 既存 `pyprland/default.nix` が生成する**単一 `config.toml` を拡張**（pyprland は単一 toml しか読まないため分割しない）                          |
| systemd             | 追加サービス無し。常駐中の `pyprland.service` が全プラグインを動かす                                                                            |
| follow_focus の挙動 | **純follow（A）**: 他モニター表示中の WS を選ぶと、その WS が手元（フォーカス中モニター）へ来る                                                 |
| WS↔モニター固定     | `monitors/*.lua` の `workspace_rule` から `monitor`/`default`/`persistent` を撤去。初期WSは Hyprland のデフォルト割当（モニター宣言順）に委ねる |
| 相対WS移動          | `SUPER+I/O` を `pypr change_workspace -1/+1` に変更（follow 尊重）                                                                              |
| SUPER+数字          | 変更なし（プラグインが hook する）                                                                                                              |
| scratchpads 対象    | term(wezterm `--class scratch-term`) / btop / vesktop                                                                                           |
| scratchpads keybind | `SUPER+Z`=term / `SUPER+X`=btop / `SUPER+D`=vesktop                                                                                             |
| SUPER+D             | vesktop の起動 exec を廃止し scratchpad トグルへ置換                                                                                            |
| toggle_special      | `SUPER+S` を native `toggle_special("magic")` → `pypr toggle_special` に置換                                                                    |
| SUPER+SHIFT+S       | **削除**（stash/unstash は SUPER+S の toggle_special に一本化）                                                                                 |
| lost_windows        | `SUPER+SHIFT+M` → `pypr lost_windows`（config 不要）                                                                                            |
| fcitx5 自動OFF      | `inactive_classes` = 端末(wezterm / scratch-term / scratch-btop) + ゲーム(nikke)。ブラウザは対象外（手動）                                      |

## アーキテクチャ

### config.toml（拡張後イメージ）

`home-manager/desktop/pyprland/default.nix` の `xdg.configFile."pypr/config.toml".text` を拡張。
パスは Nix 補間（`${config.home.homeDirectory}` / `${dotfilesDir}`）で埋める。

```toml
[pyprland]
plugins = [
  "wallpapers",
  "workspaces_follow_focus",
  "scratchpads",
  "toggle_special",
  "lost_windows",
  "fcitx5_switcher",
]

# --- 既存: wallpapers（変更なし） ---
[wallpapers]
path = "<dotfilesDir>/images/wallpaper"
interval = 30
extensions = ["jpg", "jpeg", "png", "webp"]
command = "<home>/.config/hypr/scripts/wallpaper/set.sh [file]"
post_command = "<home>/.config/hypr/scripts/wallpaper/post.sh [file]"

[workspaces_follow_focus]
# change_workspace の巡回上限（このプラグインの唯一のオプション）
max_workspaces = 10

[toggle_special]
# フォーカス窓を special:stash へ退避/復帰
name = "stash"

[scratchpads.term]
command = "wezterm start --class scratch-term"
class = "scratch-term"
match_by = "class"
size = "60% 60%"
position = "20% 5%"
lazy = true

[scratchpads.btop]
command = "wezterm start --class scratch-btop -- btop"
class = "scratch-btop"
match_by = "class"
size = "70% 70%"
position = "15% 5%"
lazy = true

[scratchpads.vesktop]
command = "vesktop"
class = "vesktop"
match_by = "class"
size = "60% 70%"
position = "20% 5%"
lazy = true

[fcitx5_switcher]
inactive_classes = ["scratch-term", "scratch-btop", "org.wezfurlong.wezterm", "<nikke の class（実装時採取）>"]
active_classes = []
inactive_titles = []
active_titles = []
```

> `workspaces_follow_focus` のオプションは `max_workspaces` のみ（`default_workspaces` は存在しない）。
> 初期WS配置は Hyprland のデフォルト割当（宣言順のモニターに WS1,2,3… が付く）に委ねる。desk では宣言順 DP-3→WS1, DP-2→WS2, DP-1→WS3 になり従来と同等。
> `[toggle_special]` の `name` は native の `special:magic` と衝突しない名前（`stash`）にする。run 側は引数優先で config `name` を読まないため keybind でも `stash` を明示する。
> scratchpad は wezterm の mux 接続で PID 追跡が外れうるため `match_by = "class"` を明示する。

### 責務分担

| プラグイン              | 役割                               | ユーザー操作           |
| ----------------------- | ---------------------------------- | ---------------------- |
| workspaces_follow_focus | WSをフォーカス中モニターへ引き寄せ | SUPER+数字 / SUPER+I,O |
| scratchpads             | ドロップダウン窓の出し入れ         | SUPER+Z,X,D            |
| toggle_special          | フォーカス窓の退避/復帰            | SUPER+S                |
| lost_windows            | 画面外の窓を現WSへ集める           | SUPER+SHIFT+M          |
| fcitx5_switcher         | 窓に応じIME自動ON/OFF              | 自動（無操作）         |

## コンポーネント詳細

### 1. 変更: `home-manager/desktop/pyprland/default.nix`

- `xdg.configFile."pypr/config.toml".text` の `plugins` に5プラグインを追加し、上記の各セクションを追記。
- systemd サービスは変更なし。
- `[scratchpads.*].command` / `[fcitx5_switcher]` の class は Nix 補間不要（固定文字列）。

### 2. 変更: `home-manager/desktop/hyprland/monitors/desk.lua`

現状:

```lua
hl.workspace_rule({ workspace = "1", monitor = "DP-3", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-2", default = true, persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", default = true, persistent = true })
```

→ **`workspace_rule` を全撤去**（monitor 定義のみ残す）。初期WS配置は Hyprland のデフォルト割当（モニター宣言順に WS1,2,3…）に委ねる。
follow_focus 下で `monitor`/`default`/`persistent` 固定は follow の挙動と競合するため。

### 3. 変更: `home-manager/desktop/hyprland/monitors/bed.lua`

現状の `for i=1,10 ... workspace_rule(... monitor="HDMI-A-1" ...)` ループを撤去（monitor 定義のみ残す）。
単一モニターかつ follow_focus なので固定は不要。

### 4. 変更: `home-manager/desktop/hyprland/lua/keybinds.lua`

- `SUPER+I` → `hl.dsp.exec_cmd("pypr change_workspace -1")`、`SUPER+O` → `pypr change_workspace +1`（現 `focus({workspace="e-1"/"e+1"})` を置換）。
  - `SUPER+SHIFT+I/O`（窓を隣WSへ move）は現状維持（native）。
- `SUPER+D`（現 vesktop exec）→ `hl.dsp.exec_cmd("pypr toggle vesktop")`（vesktop scratchpad トグル）。
- 追加: `SUPER+Z` → `pypr toggle term`、`SUPER+X` → `pypr toggle btop`。
- `SUPER+S`（現 native `toggle_special("magic")`）→ `hl.dsp.exec_cmd("pypr toggle_special stash")`（引数なしだと既定 `minimized` になるため `stash` を明示）。
- `SUPER+SHIFT+S`（現 window.move special:magic）→ **削除**。
- 追加: `SUPER+SHIFT+M` → `pypr lost_windows`。

> pyprland のトグルコマンドは `pypr toggle <name>`。scratchpad 名は toml のセクション名（term/btop/vesktop）。

### 5. 変更: `home-manager/desktop/hyprland/scripts/mode.sh`

follow_focus 導入で WS↔モニター固定が消えるため、`PREV_WS` 復元まわりを簡素化する。
awww/waybar 再生成の本体は残す（monitors 見送りのため mode.sh の役割は継続）。
具体の削減範囲は実装時に判断（最低限、workspace_rule 前提のコメント整理と `PREV_WS` の必要性再評価）。

## 実装時に確定させる項目（プレースホルダ）

- **nikke（ゲーム）の window class**: `switch` 後に該当ゲームを起動し `hyprctl clients -j | jq '.[].class'` で採取。`[fcitx5_switcher].inactive_classes` の該当行を実値に置換。
- **wezterm の実 class 名**: `hyprctl clients` で確認して確定（上記 `org.wezfurlong.wezterm` は暫定）。
- **scratchpad の wezterm `--class` 対応**: `wezterm start --class <name>` が窓 class に反映されるか実機確認（scratchpad の class マッチに必須）。

## 既知のエッジ / リスク

1. **follow_focus と mode.sh の相互作用**: モード切替時の WS 再割当が follow_focus 前提に変わる。切替直後にアクティブWSが意図とずれる可能性 → 実機確認。
2. **toggle_special の semantics 変化**: 旧＝special の表示トグル、新＝フォーカス窓の退避/復帰。使用感が変わる点を許容済み。
3. **fcitx5_switcher は fcitx5 起動が前提**: fcitx5 は既に nixos/home-manager 側で常駐。pypr が D-Bus 経由で切替を試みる。未起動時は no-op。
4. **class 未確定リスク**: nikke / 端末の class が暫定のままだと fcitx5 自動OFF が効かない。実装時採取で解消。
5. **vesktop の起動方法変更**: SUPER+D が「起動」から「scratchpad トグル」に変わる。初回はトグルで起動（lazy）。
6. **scratchpad の btop 依存**: btop がインストール済みであること（未導入なら `home.packages` に追加が必要 → 実装時確認）。

## 検証手順

1. `nix run .#build` でビルド通過。
2. `nix run .#fmt -- --fail-on-change`（deadnix / toml 整形）。
3. `nix run .#switch` 後:
   - `systemctl --user status pyprland` が active、`journalctl --user -u pyprland` にプラグイン読込エラーが無い。
   - `pypr` のプラグイン一覧に5つが載る。
   - follow_focus: 中央モニターで `SUPER+2` → WS2 が中央へ来る。`SUPER+I/O` で隣接WSへ移動。
   - scratchpads: `SUPER+Z/X/D` で term/btop/vesktop がトグル表示。
   - toggle_special: `SUPER+S` でフォーカス窓が退避→再押下で復帰。
   - lost_windows: `SUPER+SHIFT+M` が no-op でもエラーを吐かない（正常時）。
   - fcitx5_switcher: 端末/ゲームにフォーカスで IME が自動 OFF、他アプリで手動切替可。
   - bed/desk 切替（`mode.sh`）が壁紙・waybar 再生成込みで従来通り動く。

## ロールアウト後の残タスク（本設計スコープ外）

- todo.md「pyprland の導入」の各項目を消化済みにし、`monitors` は「見送り（理由付き）」として整理。
- 暫定 class 値の実値差し替え（nikke / 端末）。
  </content>
  </invoke>
