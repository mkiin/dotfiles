# hyprfocus 導入 / スクショ貼付 bin 化修正 / gpu 録画検証 設計書

- 日付: 2026-07-03
- 対象: `home-manager/desktop/`（hyprland / cliphist）、`flake.nix`、`todo.md`
- スコープ: 独立した 3 項目を 1 spec にまとめる。いずれも小粒で相互依存なし。
  1. スクリーンショットを Claude Code に貼ると bin 化する問題の修正（`wl-clip-persist` 導入）
  2. hyprfocus プラグイン導入（フォーカス移動時のアニメーション強調）
  3. gpu-screen-recorder（`record.sh`）のトグル検証（＋ `todo.md` 更新）

## 背景と前提の変更

`todo.md` には「wl-screenrec 移行」「hyprfocus」「スクショが Claude Code で bin 化」の 3 項目があった。
事前調査の結果、次の判断で当初想定を変更している。

- **wl-screenrec は見送り**。このマシンは NVIDIA proprietary driver 環境で、wl-screenrec は VA-API 前提のためハードウェアエンコードが実質動かない（`No usable encoding profile` 系。nvidia-vaapi-driver はデコード専用でエンコード不可。NVENC を使う唯一の道は experimental Vulkan でソースビルド必須・不安定）。gpu-screen-recorder は NVENC ネイティブで NVIDIA では明確に上位。よって **録画は gpu-screen-recorder を維持**する。
- **bin 化の真因はコマンドではない**。`screenshot.sh` の `wl-copy --type image/png < file` は hyprshot と完全に同一で、現行 Claude Code (v2.1.196) では実機で正しく画像認識される。bin 化は「貼り付け前に wl-copy の常駐プロセスが死に、クリップボードが空になる」ことが原因。このマシンには永続化デーモンが無く、cliphist は履歴を記録するだけで内容を再提供しない。

## スコープ外（今回やらないこと）

- **quickshell の Screenshot.qml の統合リファクタ**。quickshell は `screenshot.sh` / `record.sh` を呼ばず、`grim`/`slurp` 直呼び + `wf-recorder`（`h264_vaapi`）という完全に別実装を持つ（撮影・録画・コピーが 2 系統重複）。この統合は保存先・命名・UI 状態（`lastScreenshotPath`）・録画バックエンドまで絡むため、todo の「quickshell 大規模リファクタリング」と併せて別 spec で扱う。今回は quickshell を一切触らない。
- wl-screenrec の導入（上記理由で見送り）。
- `screenshot.sh` / `record.sh` 自体の書き換え。

## 決定事項（確定）

| 論点                                | 決定                                                                                                                                                            |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 録画ツール                          | gpu-screen-recorder を維持。wl-screenrec は NVIDIA 非対応のため見送り                                                                                           |
| bin 化の恒久対応                    | `services.wl-clip-persist.enable = true`（home-manager 公式モジュール）                                                                                         |
| wl-clip-persist の置き場所          | 既存 `home-manager/desktop/cliphist/default.nix` に同居（clipboard 概念。新規 dir を作らない）                                                                  |
| quickshell の `wl-copy --type` 追加 | 今回はやらない（wl-clip-persist が root cause を潰すため不要。統合リファクタ側で扱う）                                                                          |
| hyprfocus のパッケージ              | 公式集 `hyprwm/hyprland-plugins` の `hyprfocus`（本体追従が保証され、放置版でない）                                                                             |
| バージョン整合                      | `hyprland-plugins.inputs.hyprland.follows = "hyprland"` で本体と同一 rev に固定                                                                                 |
| プラグインのロード方式              | home-manager の `plugins` オプションは使わない。`hl.plugin.load(...)` 行を含む `plugins.lua` を `xdg.configFile.text` で生成し、`hyprland.lua` の先頭で require |
| hyprfocus 設定の記述場所            | `lua/appearance.lua`（既に animations/curve を持つファイルに同居）                                                                                              |
| hyprfocus 設定スキーマ              | 公式版（`keyboard_focus_animation` 等）。pyt0xic 版の `enabled`/`flash_opacity` 等とは混同しない                                                                |

## なぜ home-manager の `plugins` オプションを使わないか（重要な設計判断）

home-manager の `wayland.windowManager.hyprland` は `settings` / `extraConfig` / `plugins` のいずれかに中身がある時だけ `~/.config/hypr/hyprland.lua` を自動生成する。

現状この repo は `settings` / `extraConfig` / `plugins` をすべて空にしており、home-manager は `hyprland.lua` を生成していない。代わりに `xdg.configFile."hypr/hyprland.lua".source` で自前の lua を**シンボリックリンク**として配置している（lua 直書きスタイルを維持するため）。

ここで `plugins = [ ... ]` を足すと、home-manager が `~/.config/hypr/hyprland.lua` を生成しようとし、**既存のシンボリックリンクと同一パスで衝突して `nix run .#build` が失敗する**。

`settings` / `extraConfig` へ全面移行すれば衝突は避けられるが、lua 移行で得た `hl.dsp.*` などの DSL を捨てて hyprlang 文字列（`"SUPER, H, movefocus, l"` の羅列）に逆戻りするため、だるさだけが増える。

そこで **`plugins` オプションを使わず、プラグインのロード行だけを別ファイルとして Nix 生成する**。store パス補間が必要なロード行のみを `plugins.lua` として吐き、既存の lua 直書き構成には一切手を入れない。増えるのは自動生成の 1 ファイルだけ。

## 変更するファイル

```
flake.nix                                   # inputs に hyprland-plugins 追加

home-manager/desktop/
├── hyprland/
│   ├── default.nix                         # xdg.configFile に "hypr/plugins.lua".text 生成を追加
│   └── lua/
│       ├── hyprland.lua                    # 先頭に require("plugins")
│       └── appearance.lua                  # hyprfocus 設定 + hyprfocusIn/Out アニメ + focusCurve
└── cliphist/
    └── default.nix                         # services.wl-clip-persist.enable = true 追加

todo.md                                     # 録画・hyprfocus の項目を更新
```

新規のソース `.lua` ファイルは作らない（`plugins.lua` は `default.nix` 内のインライン `text` で生成）。

## 実機に生成される構造（switch 後）

```
~/.config/hypr/
├── hyprland.lua      # 既存シンボリックリンク（先頭に require("plugins") が増える）
├── plugins.lua       # 新規・自動生成: hl.plugin.load("/nix/store/.../lib/libhyprfocus.so")
├── appearance.lua    # 既存シンボリックリンク（hyprfocus 設定が追記される）
├── env.lua / input.lua / keybinds.lua / rules.lua
└── scripts/          # record.sh は変更なし
```

読み込み順は `hyprland.lua` → `require("plugins")`（プラグインロード）→ `require("appearance")`（hyprfocus 設定適用）となり、「ロードしてから設定」の順序を自前で保証する。

## 各項目の詳細

### ① スクショ bin 化修正

`home-manager/desktop/cliphist/default.nix` に追記する。

```nix
_: {
  services.cliphist.enable = true;
  services.cliphist.allowImages = true;
  services.wl-clip-persist.enable = true; # clipboardType は既定 "regular"
}
```

- `wl-clip-persist` は home-manager 公式モジュール（`services.wl-clip-persist`）。`enable` だけでパッケージと systemd ユーザーサービスが有効化される。`clipboardType` は既定 `"regular"` のままで良い。
- これによりコピー元プロセスが終了してもクリップボード内容が保持され、Claude Code が貼り付け時に image/png を検出できる。`screenshot.sh` も quickshell も変更しない。

### ② hyprfocus 導入

**flake.nix（inputs 追加）**

```nix
hyprland-plugins = {
  url = "github:hyprwm/hyprland-plugins";
  inputs.hyprland.follows = "hyprland";
};
```

**hyprland/default.nix（ロード行を生成）**

`xdg.configFile` に 1 エントリ追加する（`.so` 名は実装時にビルドで確認。パッケージの `pname` から `lib<pname>.so` を組む規約）。

```nix
"hypr/plugins.lua".text = ''
  hl.plugin.load("${inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprfocus}/lib/libhyprfocus.so")
'';
```

**lua/hyprland.lua（先頭に追加）**

```lua
require("plugins")
```

（既存の `require("env")` などより前に置く）

**lua/appearance.lua（末尾に追記）**

```lua
hl.config({ plugin = { hyprfocus = {
  enable = true,
  keyboard_focus_animation = "flash",
  mouse_focus_animation = "flash",
  animate_floating = true,
  fade_opacity = 0.8,
} } })

hl.curve("focusCurve", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.0 } } })
hl.animation({ leaf = "hyprfocusIn",  enabled = true, speed = 1.7, bezier = "focusCurve" })
hl.animation({ leaf = "hyprfocusOut", enabled = true, speed = 1.7, bezier = "focusCurve" })
```

- キーは公式版（`hyprwm/hyprland-plugins`）のスキーマ。値は Lua 型（`yes/no` → `true/false`、選択肢 → 文字列 `"flash"`）。
- アニメーションの見た目（`fade_opacity` / `speed` / bezier）は実機確認後に微調整可。

### ③ gpu 録画（現状維持 + 検証）

- `record.sh` は既に PID ファイル + SIGINT + 終了待ちループでトグルを実装済み。**コード変更は原則なし**。
- 実機で Super+R を連打し、二重録画（2 つ目の録画が始まる）が再現しないか検証する。再現した場合のみ、PID 判定/レースの最小修正を行う。
- `todo.md` を更新: 「他パッケージの追加と設定」の wl-screenrec 項を「gpu-screen-recorder 維持・wl-screenrec は NVIDIA 非対応で見送り」に、hyprfocus 項を「導入済み」に書き換える。

## リスクと確認ポイント

- **プラグインの `.so` 名の食い違い**: パッケージは `lib<pname>.so` を期待する。ロード時に「見つからない」エラーが出たら最初にこの `.so` 名を疑う（`ls` で実際のパスを確認）。
- **ロード順序**: `hyprland.lua` 先頭で `require("plugins")` する構成により、`appearance.lua` の hyprfocus 設定より前にロードされることを保証する。万一 hyprfocus 設定が効かない場合は、`appearance.lua` の設定ブロックを `if hl.plugin.hyprfocus ~= nil then ... end` で nil ガードして切り分ける。
- **CI ソースビルド**: `hyprland-plugins` は本体とバージョン一致でソースビルドされる。`follows` で rev を固定しているため、Bot が両 input を同時更新する限り整合は保たれる。CI のビルド時間が伸びる可能性はあるが、hyprland 自体が既に `hyprland.cachix.org` 経由でキャッシュされている前提。

## 検証

- `nix run .#build`（NixOS 構成ビルド）を通す。
- `nix run .#fmt -- --fail-on-change`（treefmt + deadnix。未使用 let 束縛や整形漏れの検出）を通す。
- `nix run .#switch` 後、実機で確認:
  - hyprfocus: ウィンドウフォーカス移動時に強調アニメーション（flash）が出る。
  - bin 修正: スクショ後、少し待ってから Claude Code に貼り付け → `[Image #N]` として画像認識される。
  - 録画: Super+R でトグル（開始 → 再入力で停止、二重録画しない）。
