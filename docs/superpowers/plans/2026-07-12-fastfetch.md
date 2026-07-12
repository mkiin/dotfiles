# fastfetch 導入 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** fastfetch を導入し、`ff` 直叩き（両環境）と pyprland scratchpad トグル（実機のみ）の 2 経路で表示できるようにする。

**Architecture:** fastfetch 本体と設定は `home-manager/cli/`（両環境が import）に置き、配色は ANSI 色名指定で wallust テーマ済み端末に追従させる（パターン B、専用テンプレート不要）。scratchpad 配線は `home-manager/desktop/`（実機のみ）に置き、WSL では desktop 非 import により自動的に不在になる。

**Tech Stack:** Nix / home-manager, fastfetch (jsonc config), pyprland (scratchpads plugin, TOML), Hyprland (lua config via hl DSL)

## Global Constraints

- パッケージ宣言は集約 `packages.nix` のみ。機能ディレクトリの `default.nix` は設定専用（`xdg.configFile` 等）。`home.packages` 直書き禁止。
- `../` で親へ遡る相対パス参照は禁止。同階層コロケーションは `lnk ./file` を使う。
- コメントは「なぜ」だけ 1〜2 行。逐条コメント禁止。
- エイリアスは zsh-abbr（`abbr`）で定義する（shellAliases ではなく initContent の abbr 群）。
- 配色は fastfetch 側で ANSI 色名のみ指定（wallust テンプレートは追加しない）。
- ロゴは fastfetch 内蔵 `nixos`。
- scratchpad の geometry は pyprland 側で指定。Hyprland の `rules.lua` に見た目 rule は追加しない（本体 appearance.lua の rounding=14 / border=0 / blur / 不透明運用を継承）。
- 検証は `nix run .#build`（実機）と WSL 構成のドライビルド、`nix run .#fmt -- --fail-on-change`。

---

## File Structure

- `home-manager/cli/packages.nix` — `fastfetch` を集約宣言に追加（Modify）
- `home-manager/cli/fastfetch/default.nix` — config.jsonc を配置する設定専用モジュール（Create）
- `home-manager/cli/fastfetch/config.jsonc` — fastfetch 設定本体（Create）
- `home-manager/cli/default.nix` — imports に `./fastfetch` 追加（Modify）
- `home-manager/cli/zsh/default.nix` — abbr 群に `abbr ff="fastfetch"` 追加（Modify）
- `home-manager/desktop/pyprland/default.nix` — scratchpads プラグイン + `[scratchpads.fetch]`（Modify）
- `home-manager/desktop/hyprland/lua/keybinds.lua` — トグルキーバインド追加（Modify）

---

### Task 1: fastfetch 本体・設定・cli 配線・ff abbr（両環境）

**Files:**

- Create: `home-manager/cli/fastfetch/default.nix`
- Create: `home-manager/cli/fastfetch/config.jsonc`
- Modify: `home-manager/cli/packages.nix`
- Modify: `home-manager/cli/default.nix`
- Modify: `home-manager/cli/zsh/default.nix`

**Interfaces:**

- Produces: `~/.config/fastfetch/config.jsonc` を配置。`fastfetch` コマンドと `ff` abbr が両環境で使用可能になる。この config は Task 2 の scratchpad が起動する fastfetch も共有する（追加の受け渡しは無し）。

- [ ] **Step 1: fastfetch 設定本体を作成**

`home-manager/cli/fastfetch/config.jsonc` を作成する。色は ANSI 色名のみ（端末=wallust テーマに追従）。ロゴは内蔵 `nixos`。

```jsonc
{
  "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
  "logo": {
    "source": "nixos",
    "color": {
      "1": "blue",
      "2": "cyan",
    },
  },
  "display": {
    "separator": "  ",
    "color": {
      "keys": "blue",
    },
    "key": {
      "type": "icon",
    },
  },
  "modules": [
    {
      "type": "title",
      "color": {
        "user": "cyan",
        "at": "blue",
        "host": "cyan",
      },
    },
    "separator",
    "os",
    "host",
    "kernel",
    "uptime",
    {
      "type": "packages",
      "key": "Packages",
    },
    "shell",
    "wm",
    "terminal",
    "cpu",
    "gpu",
    "memory",
    "disk",
    "break",
    {
      "type": "colors",
      "symbol": "circle",
    },
  ],
}
```

- [ ] **Step 2: 設定専用モジュールを作成**

`home-manager/cli/fastfetch/default.nix` を作成する（本体パッケージは書かない＝集約側で宣言）。

```nix
{ lnk, ... }:
{
  xdg.configFile."fastfetch/config.jsonc".source = lnk ./config.jsonc;
}
```

- [ ] **Step 3: パッケージを集約宣言に追加**

`home-manager/cli/packages.nix` の `# dev tools` ブロック付近（例: `gh` の下）に `fastfetch` を 1 行追加する。

```nix
      # dev tools
      gh
      fastfetch
      lazydocker
```

- [ ] **Step 4: cli の imports に fastfetch を追加**

`home-manager/cli/default.nix` の imports 配列に `./fastfetch` を追加する。

```nix
  imports = [
    ./packages.nix
    ./zsh
    ./git
    ./mise
    ./lazygit
    ./herdr
    ./starship
    ./sheldon
    ./yazi
    ./goclipboard
    ./python
    ./rbw
    ./direnv
    ./fastfetch
  ];
```

- [ ] **Step 5: ff abbr を追加**

`home-manager/cli/zsh/default.nix` の initContent 内、abbr 群（`abbr lg="lazygit"` 付近）に 1 行追加する。

```
      abbr lg="lazygit"
      abbr ff="fastfetch"
```

- [ ] **Step 6: 整形チェック**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで PASS（deadnix / 未使用束縛なし）

- [ ] **Step 7: WSL 構成のドライビルド**

Run: `nix build '.#homeConfigurations."mkiin@wsl".activationPackage' --no-link`
Expected: エラーなくビルド完了（fastfetch が home.packages に入り config が評価される）

- [ ] **Step 8: 実機構成ビルド**

Run: `nix run .#build`
Expected: エラーなくビルド完了

- [ ] **Step 9: コミット**

```bash
git add home-manager/cli/fastfetch home-manager/cli/packages.nix home-manager/cli/default.nix home-manager/cli/zsh/default.nix
git commit -m "feat(fastfetch): fastfetch 導入・ANSI 配色設定・ff abbr を追加"
```

---

### Task 2: pyprland scratchpad とトグルキーバインド（実機のみ）

**Files:**

- Modify: `home-manager/desktop/pyprland/default.nix`
- Modify: `home-manager/desktop/hyprland/lua/keybinds.lua`

**Interfaces:**

- Consumes: Task 1 が配置した `~/.config/fastfetch/config.jsonc`（scratchpad の wezterm 内で `fastfetch` を実行すると自動的に読む）。
- Produces: `pypr toggle fetch` で `fetch-scratch` クラスの wezterm をトグル表示する scratchpad。`SUPER + SHIFT + F` にバインド。

- [ ] **Step 1: scratchpads プラグインと fetch scratchpad を追加**

`home-manager/desktop/pyprland/default.nix` の config.toml テキストを編集する。(1) `plugins` に `"scratchpads"` を追加、(2) 末尾の「scratchpads プラグインは見送り」コメントを差し替えて `[scratchpads.fetch]` を定義する。

plugins 配列を次にする:

```nix
    plugins = [
      "scratchpads",
      "wallpapers",
      "workspaces_follow_focus",
      "toggle_special",
      "lost_windows",
      "fcitx5_switcher",
    ]
```

末尾の既存コメント（`# scratchpads プラグインは見送り。…`）を次の scratchpad 定義へ置き換える:

```nix
    # fetch 用は行儀のよい単一 wezterm ウィンドウなので scratchpads を採用。
    # vesktop(Electron 単一インスタンス)は窓追跡が不安定なため引き続き除外。
    [scratchpads.fetch]
    command = "wezterm start --class fetch-scratch -- sh -c 'fastfetch; exec $SHELL'"
    class = "fetch-scratch"
    size = "50% 55%"
    position = "25% 22%"
    animation = "fromTop"
    lazy = true
    unfocus = "hide"
```

- [ ] **Step 2: トグルキーバインドを追加**

`home-manager/desktop/hyprland/lua/keybinds.lua` の scratchpad/special 系バインド付近（`SUPER + SHIFT + M` = lost_windows の行の後）に追加する。

```lua
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("pypr lost_windows"))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("pypr toggle fetch"))
```

- [ ] **Step 3: 整形チェック**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで PASS

- [ ] **Step 4: 実機構成ビルド**

Run: `nix run .#build`
Expected: エラーなくビルド完了

- [ ] **Step 5: 実機へ反映**

Run: `nix run .#switch`
Expected: 反映完了。`X-Restart-Triggers` により pypr unit が再起動し、config.toml の変更が反映される。

- [ ] **Step 6: ランタイム動作確認（実機・手動）**

Hyprland セッション上で `SUPER + SHIFT + F` を押す。
Expected:

- 初回押下で wezterm が spawn し fastfetch が 1 回描画される（画面上部からスライドイン、50%×55%、25%/22% 位置）。
- 再度押下で非表示、もう一度で再表示（同一ウィンドウ、再計算なし）。
- フォーカスを外すと自動的に隠れる。
- rounding 14 / border なし / blur が本体設定どおり適用されている。

確認コマンド（scratchpad が認識されているか）: `pypr scratchpads` で `fetch` が一覧に出る。

- [ ] **Step 7: コミット**

```bash
git add home-manager/desktop/pyprland/default.nix home-manager/desktop/hyprland/lua/keybinds.lua
git commit -m "feat(fastfetch): pyprland scratchpad と SUPER+SHIFT+F トグルを追加"
```

---

## Self-Review

- **Spec coverage:**
  - 表示経路 2 つ（`ff` 直叩き / scratchpad）→ Task 1 / Task 2。
  - パターン B（ANSI 委譲・テンプレート追加なし）→ Task 1 Step 1 の色指定、wallust は触らない。
  - scratchpad 静止（lazy）→ Task 2 Step 1 の `lazy = true`。
  - host 端末 wezterm → Task 2 Step 1 command。
  - キーバインド SUPER+SHIFT+F → Task 2 Step 2。
  - ロゴ内蔵 nixos → Task 1 Step 1 logo.source。
  - abbr で ff → Task 1 Step 5。
  - 見た目 rule 追加しない（本体継承）→ rules.lua 変更なし（両タスクとも触らない）。
  - WSL は scratchpad 不在 → desktop 非 import のため Task 2 は自動的に WSL 対象外。
  - 検証（build / fmt）→ 各タスクの Step に含む。
- **Placeholder scan:** TBD/TODO 等なし。全 Step に実コード/実コマンドあり。
- **Type consistency:** scratchpad 名 `fetch`、クラス `fetch-scratch`、`pypr toggle fetch` が Task 2 内で一貫。config パス `~/.config/fastfetch/config.jsonc` が Task 1/2 で一致。
