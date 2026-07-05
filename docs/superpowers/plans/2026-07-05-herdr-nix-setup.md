# herdr Nix 管理・skill 連携・vim 化・マニュアル 実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** herdr（AI エージェント向けターミナルマルチプレクサ）を dotfiles の Nix 管理下に置き、agent skill を配布し、vim ライクなキーバインドと日本語マニュアルを用意する。

**Architecture:** herdr 自前 flake を input として1本追加し、パッケージ本体は `home-manager/cli/packages.nix` に宣言、設定は新設 `home-manager/cli/herdr/default.nix` の `xdg.configFile` で `config.toml` を `pkgs.formats.toml` から生成する。ルート直下の `SKILL.md` は derivation で `herdr/SKILL.md` 構造に包み、既存 `programs.agent-skills` のソースに登録して claude/codex に配布する。

**Tech Stack:** Nix flake, home-manager, agent-skills-nix (`programs.agent-skills`), `pkgs.formats.toml`, treefmt。

## Global Constraints

- パッケージ本体の宣言は集約 `packages.nix` のみ（`home-manager/cli/packages.nix`）。機能ディレクトリ `default.nix` に `home.packages` を書くのは禁止。設定専用。
- 1 機能 = 1 ディレクトリ = 1 `default.nix`。関連ファイルはコロケーション。
- flake input は `inputs.nixpkgs.follows = "nixpkgs"` で nixpkgs を統一する。
- コメントは「なぜ」だけを 1〜2 行。逐条コメント禁止。
- 最終的に `nix run .#fmt -- --fail-on-change` と `nix run .#build` を必ず通す。
- flake.lock の他 input は更新しない（`nix flake lock` で herdr のみ追加。`nix flake update` は使わない）。
- 検証は WSL home 構成（`.#homeConfigurations."mkiin@wsl"`）を eval 対象に使う。これは `home-manager/default.nix` 経由で `./cli` と `./ai` を import するため、パッケージと skill の両方を評価できる。

---

### Task 1: herdr flake input とパッケージ宣言

**Files:**

- Modify: `flake.nix`（inputs ブロック末尾、`anthropic-skills` 定義の直後）
- Modify: `home-manager/cli/packages.nix`

**Interfaces:**

- Produces: flake input `herdr`（`inputs.herdr.packages.${pkgs.system}.default` で herdr パッケージを参照可能）。`home.packages` に herdr が入り PATH に載る。

- [ ] **Step 1: flake.nix に herdr input を追加**

`flake.nix` の `anthropic-skills = { ... };` ブロック（`inputs` 内、閉じ `};` の直前）の後に追記する。既存の該当箇所:

```nix
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };
  };
```

を次に変更する:

```nix
    anthropic-skills = {
      url = "github:anthropics/skills";
      flake = false;
    };

    herdr.url = "github:ogulcancelik/herdr";
    herdr.inputs.nixpkgs.follows = "nixpkgs";
  };
```

- [ ] **Step 2: flake.lock に herdr のみ追加**

Run: `nix flake lock`
Expected: 出力に `• Added input 'herdr':` と、その推移的 input（herdr 側の nixpkgs は follows で解決）が表示される。他 input の行に `Updated` が出ないこと（herdr 追加のみ）。`flake.lock` に `"herdr"` ノードが追加される。

- [ ] **Step 3: cli/packages.nix に herdr パッケージを宣言**

`home-manager/cli/packages.nix` を次のように変更する。関数引数に `inputs` を追加し、`dev tools` 群に herdr を加える（`inputs.herdr.packages.${pkgs.system}.default` は既存の anime-games-launcher の参照パターンに倣う）。

```nix
{ pkgs, inputs, ... }:

{
  home.packages = with pkgs; [
    # essentials
    curl
    ghq
    # search & file utilities
    ripgrep
    fd
    bat
    eza
    jq
    fzf
    zoxide
    # shell
    shellcheck
    shfmt
    mo
    # dev tools
    gh
    lazydocker
    mise
  ]
  ++ [
    # agent 向けターミナルマルチプレクサ（自前 flake を参照）
    inputs.herdr.packages.${pkgs.system}.default
  ];
}
```

- [ ] **Step 4: 評価してパッケージ解決を確認**

Run: `nix eval .#homeConfigurations."mkiin@wsl".config.home.packages --apply 'builtins.length'`
Expected: 数値が返る（eval エラーなし）。herdr の参照解決に失敗すると `attribute 'default' missing` 等でここで落ちる。

- [ ] **Step 5: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なしで正常終了（deadnix / nixfmt 指摘なし）。

- [ ] **Step 6: コミット**

```bash
git add flake.nix flake.lock home-manager/cli/packages.nix
git commit -m "feat(cli): herdrをflake input化してcli packagesに追加"
```

---

### Task 2: config.toml（vim キーバインド）と import 配線

**Files:**

- Create: `home-manager/cli/herdr/default.nix`
- Modify: `home-manager/cli/default.nix`（imports に `./herdr` を追加）

**Interfaces:**

- Consumes: Task 1 で PATH に入った `herdr` バイナリ（`~/.config/herdr/config.toml` を読む）。
- Produces: `xdg.configFile."herdr/config.toml"` を生成。herdr が prefix + `ctrl+alt` 直接 chord の二刀流で動く。

- [ ] **Step 1: herdr 設定モジュールを作成**

`home-manager/cli/herdr/default.nix` を新規作成する。設定専用（`home.packages` は書かない）。`pkgs.formats.toml` で attrset から TOML を生成する。

```nix
{ pkgs, ... }:
let
  tomlFormat = pkgs.formats.toml { };

  settings = {
    onboarding = false;

    keys = {
      # ペイン移動は prefix と ctrl+alt 直接 chord の二刀流（herdr 公式の prefix-free 推奨に準拠）
      focus_pane_left = [
        "prefix+h"
        "ctrl+alt+h"
      ];
      focus_pane_down = [
        "prefix+j"
        "ctrl+alt+j"
      ];
      focus_pane_up = [
        "prefix+k"
        "ctrl+alt+k"
      ];
      focus_pane_right = [
        "prefix+l"
        "ctrl+alt+l"
      ];

      # navigate モードは素の hjkl（prefix+ 不可のフィールド）
      navigate_pane_left = "h";
      navigate_pane_down = "j";
      navigate_pane_up = "k";
      navigate_pane_right = "l";

      new_tab = [
        "prefix+c"
        "ctrl+alt+c"
      ];
      previous_tab = [
        "prefix+p"
        "ctrl+alt+["
      ];
      next_tab = [
        "prefix+n"
        "ctrl+alt+]"
      ];
      split_vertical = [
        "prefix+v"
        "ctrl+alt+d"
      ];
      split_horizontal = [
        "prefix+minus"
        "ctrl+alt+shift+d"
      ];
      zoom = [
        "prefix+z"
        "ctrl+alt+z"
      ];
    };
  };
in
{
  xdg.configFile."herdr/config.toml".source = tomlFormat.generate "herdr-config.toml" settings;
}
```

- [ ] **Step 2: cli/default.nix の imports に配線**

`home-manager/cli/default.nix` の imports リストに `./herdr` を追加する（`./lazygit` の近く、dev tool として）。変更後:

```nix
{ ... }:
{
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
  ];
}
```

- [ ] **Step 3: config.toml の生成を評価**

Run: `nix eval --raw .#homeConfigurations."mkiin@wsl".config.xdg.configFile."herdr/config.toml".source`
Expected: `/nix/store/...-herdr-config.toml` の形式の store パスが1行で返る（eval エラーなし）。

- [ ] **Step 4: 生成内容を目視確認**

Run: `cat "$(nix eval --raw .#homeConfigurations."mkiin@wsl".config.xdg.configFile."herdr/config.toml".source)"`
Expected: 先頭に `onboarding = false`、`[keys]` テーブル、`focus_pane_left = ["prefix+h", "ctrl+alt+h"]` 等の配列と `navigate_pane_left = "h"` 等の文字列が出力される。

- [ ] **Step 5: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なしで正常終了。

- [ ] **Step 6: コミット**

```bash
git add home-manager/cli/herdr/default.nix home-manager/cli/default.nix
git commit -m "feat(cli): herdrのvimライクキーバインドをconfig.tomlで設定"
```

---

### Task 3: herdr agent skill の配線

**Files:**

- Modify: `home-manager/ai/agent-skills/default.nix`

**Interfaces:**

- Consumes: Task 1 の flake input `inputs.herdr`（そのソースツリー直下に `SKILL.md` がある）。
- Produces: `programs.agent-skills.sources.herdr` と `skills.enable` への `"herdr"` 追加。claude/codex の skills に `herdr` が配布される。

- [ ] **Step 1: pkgs を module 引数に追加し、skill を包む derivation を定義**

`home-manager/ai/agent-skills/default.nix` の先頭を変更する。関数引数に `pkgs` を追加し、`let` に `herdr-skill` を追加する。ルート直下 `SKILL.md` を agent-skills-nix が期待する `<dir>/SKILL.md` 構造へ包む（手動コピーせず input に追従）。

変更前:

```nix
{ inputs, ... }:
let
  inherit (inputs)
    superpowers-skill
    cloudflare-skills
    anthropic-skills
    ;
  local-skills = inputs.self + "/home-manager/ai/agent-skills/files/skills";
in
```

変更後:

```nix
{ inputs, pkgs, ... }:
let
  inherit (inputs)
    superpowers-skill
    cloudflare-skills
    anthropic-skills
    ;
  local-skills = inputs.self + "/home-manager/ai/agent-skills/files/skills";

  # herdr の SKILL.md はリポジトリ直下にあり skills/<名前>/SKILL.md 構造でないため包み直す
  herdr-skill = pkgs.runCommand "herdr-skill" { } ''
    mkdir -p $out/herdr
    cp ${inputs.herdr}/SKILL.md $out/herdr/SKILL.md
  '';
in
```

- [ ] **Step 2: sources に herdr を追加**

`programs.agent-skills.sources` の `anthropic = { ... };` ブロックの後に追記する。変更前:

```nix
      # External: Anthropic 公式スキル (anthropics/skills) — frontend-design のみ使用
      anthropic = {
        path = anthropic-skills;
        subdir = "skills";
        filter.maxDepth = 1;
      };
    };
```

変更後:

```nix
      # External: Anthropic 公式スキル (anthropics/skills) — frontend-design のみ使用
      anthropic = {
        path = anthropic-skills;
        subdir = "skills";
        filter.maxDepth = 1;
      };
      # External: herdr operate skill（HERDR_ENV=1 のときだけ herdr を CLI 操作）
      herdr = {
        path = herdr-skill;
        subdir = ".";
        filter.maxDepth = 1;
      };
    };
```

- [ ] **Step 3: skills.enable に herdr を追加**

`skills.enable` リストの末尾（`"frontend-design"` の後）に `"herdr"` を追加する。変更前:

```nix
    skills.enable = [
      "agents-sdk"
      "cloudflare"
      "cloudflare-email-service"
      "durable-objects"
      "sandbox-sdk"
      "web-perf"
      "workers-best-practices"
      "wrangler"
      "frontend-design"
    ];
```

変更後:

```nix
    skills.enable = [
      "agents-sdk"
      "cloudflare"
      "cloudflare-email-service"
      "durable-objects"
      "sandbox-sdk"
      "web-perf"
      "workers-best-practices"
      "wrangler"
      "frontend-design"
      "herdr"
    ];
```

- [ ] **Step 4: skill ソースの解決を評価**

Run: `nix eval .#homeConfigurations."mkiin@wsl".config.programs.agent-skills.sources.herdr.subdir`
Expected: `"."` が返る（sources に herdr が登録され eval が通る）。

- [ ] **Step 5: 生成物のパスを評価して SKILL.md が包まれたか確認**

Run: `ls "$(nix eval --raw .#homeConfigurations."mkiin@wsl".config.programs.agent-skills.sources.herdr.path)/herdr"`
Expected: `SKILL.md` が表示される（derivation がビルドされ `herdr/SKILL.md` が存在）。

- [ ] **Step 6: フォーマット確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なしで正常終了。

- [ ] **Step 7: コミット**

```bash
git add home-manager/ai/agent-skills/default.nix
git commit -m "feat(ai): herdr operate skillをagent-skillsに追加"
```

---

### Task 4: 日本語チュートリアルマニュアル

**Files:**

- Create: `home-manager/cli/herdr/MANUAL.md`

**Interfaces:**

- Consumes: Task 2 の config（vim chord 早見表の値と一致させる）。
- Produces: `home-manager/cli/herdr/MANUAL.md`（読み物。ビルドには影響しない）。

- [ ] **Step 1: マニュアルを作成**

`home-manager/cli/herdr/MANUAL.md` を新規作成する。内容は次のとおり（早見表は Task 2 の config と一致させる）。

````markdown
# herdr チュートリアルマニュアル

herdr は tmux を AI コーディングエージェント向けに作り直したターミナルマルチプレクサです。ワークスペース / タブ / ペインを持ち、各ペインは実ターミナルとして動きます。サイドバーが各エージェントの状態を 🔴 blocked / 🟡 working / 🔵 done / 🟢 idle で集約表示し、detach してもエージェントは生き続けます。

この dotfiles では Nix で導入済みです。`herdr` はそのまま PATH にあります。

## 1. 起動と最初の一歩

```bash
herdr
```

バックグラウンドサーバーを起動（または再接続）してワークスペースを開きます。開いたペインでエージェントを起動します。

```bash
claude
```

サイドバーにそのエージェントの状態が出ます。マウス操作にも対応していて、ペイン・タブ・分割境界はクリックとドラッグで操作できます。

## 2. プレフィックスの考え方

herdr はプレフィックス方式です。まず `ctrl+b` を押して離し、続けてアクションキーを押します。例えば `ctrl+b` → `c` で新しいタブ。全バインドは `ctrl+b` → `?` で一覧表示できます。

この設定では、プレフィックスに加えて `ctrl+alt` の直接 chord を併設しています（プレフィックス不要）。シェルやエディタと衝突しにくい組み合わせです。

## 3. vim chord 早見表（この設定）

| 操作                      | プレフィックス             | 直接 chord                  |
| ------------------------- | -------------------------- | --------------------------- |
| ペイン移動（左/下/上/右） | `ctrl+b` → `h`/`j`/`k`/`l` | `ctrl+alt+h`/`j`/`k`/`l`    |
| 新しいタブ                | `ctrl+b` → `c`             | `ctrl+alt+c`                |
| 前/次のタブ               | `ctrl+b` → `p`/`n`         | `ctrl+alt+[` / `ctrl+alt+]` |
| 縦分割                    | `ctrl+b` → `v`             | `ctrl+alt+d`                |
| 横分割                    | `ctrl+b` → `-`             | `ctrl+alt+shift+d`          |
| ズーム                    | `ctrl+b` → `z`             | `ctrl+alt+z`                |

navigate モード（ワークスペース/ペインをキーボードで辿るモード）では素の `h`/`j`/`k`/`l` で移動します。

## 4. まず覚える5つ

| やりたいこと                   | キー                            |
| ------------------------------ | ------------------------------- |
| 新しいタブ                     | `ctrl+b` → `c`                  |
| 分割（縦/横）                  | `ctrl+b` → `v` / `ctrl+b` → `-` |
| ペイン間移動                   | `ctrl+alt+h/j/k/l`              |
| ワークスペース選択             | `ctrl+b` → `w`                  |
| detach（全部動かしたまま離脱） | `ctrl+b` → `q`                  |

detach 後は `herdr` をもう一度実行すれば再接続できます。エージェントは生きたままです。

## 5. コピーモード（vim 操作）

`ctrl+b` → `[` でコピーモードに入ります。`h/j/k/l` で移動、`w`/`b`/`e` で単語移動、`{`/`}` で段落移動、`ctrl+b`/`ctrl+f` でページ移動。`v` または Space で選択開始、`y` または Enter でコピー、`q` または Esc でコピーせず退出します。マウスのドラッグ選択でもコピーできます。

## 6. worktree とワークスペース

Git ワークスペースの行から `New worktree` で worktree チェックアウトを作れます。作成した worktree は元のワークスペースの下にグループ化された別ワークスペースとして開き、独自のタブ・ペインを持てます。チェックアウト先の削除は `Delete worktree checkout...` から明示的に行います（ブランチは消えません）。

worktree の作成先ディレクトリは config の `[worktrees] directory`（既定 `~/.herdr/worktrees`）で決まります。

## 7. エージェント連携（skill）

この dotfiles では herdr の operate skill を claude / codex に配布済みです。herdr 管理ペイン内（環境変数 `HERDR_ENV=1`）でエージェントを動かすと、エージェント自身が `herdr` CLI 経由でワークスペース作成・ペイン分割・他ペインの出力読み取り・状態変化待ちなどを行えます。`HERDR_ENV=1` が無い場合、skill は「herdr 内で動いていない」と判断して何もしません。

## 8. detach / reattach とトラブル時

- detach: `ctrl+b` → `q`。再接続は `herdr`。
- 設定を編集したら反映: `herdr server reload-config`（多くの UI 設定はペイン再起動なしで反映。起動時のみ有効な設定は再起動が必要）。
- リモート: `herdr --remote <host>` でローカル端末をリモートサーバーのクライアントにできます（画像貼り付けが維持される）。
- 既定設定の全出力: `herdr --default-config`。

## この設定をいじるには

キーバインドやテーマは `home-manager/cli/herdr/default.nix` の `settings` を編集し、`nix run .#build` で検証してから `nix run .#switch`（WSL は `nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl`）で反映します。config.toml は生成物なので直接編集しません。
````

- [ ] **Step 2: マニュアルの早見表が config と一致するか確認**

Run: `grep -E "ctrl\+alt\+(h|j|k|l|c|z|d)" home-manager/cli/herdr/MANUAL.md`
Expected: `ctrl+alt+h/j/k/l`・`ctrl+alt+c`・`ctrl+alt+z`・`ctrl+alt+d` を含む行が表示され、Task 2 の config の値と食い違わないこと。

- [ ] **Step 3: コミット**

```bash
git add home-manager/cli/herdr/MANUAL.md
git commit -m "docs(cli): herdrの日本語チュートリアルマニュアルを追加"
```

---

### Task 5: 統合ビルド検証

**Files:**

- なし（検証のみ）

**Interfaces:**

- Consumes: Task 1〜4 の全変更。

- [ ] **Step 1: フォーマット最終確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なしで正常終了。

- [ ] **Step 2: nixos 構成をフルビルド**

Run: `nix run .#build`
Expected: `Build successful!` が表示される。ここで herdr パッケージ本体（Rust + zig ビルド）も実際にビルドされるため時間がかかることがある。ビルドが通れば home 側の herdr パッケージ・config・skill 配線がすべて整合している。

- [ ] **Step 3: 反映（ユーザー判断）**

NixOS 実機に反映する場合:

```bash
nix run .#switch
```

WSL に反映する場合:

```bash
nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl
```

反映後 `herdr` を起動し、`ctrl+b` → `?` でキーバインド一覧に vim chord が反映されているか、`ctrl+alt+h/j/k/l` でペイン移動できるかを確認する。

- [ ] **Step 4: 反映確認をコミット（変更があれば）**

このタスクは検証のみでコード変更は無い。`git status` がクリーンであることを確認する。

Run: `git status --short`
Expected: 出力なし（全変更は Task 1〜4 でコミット済み）。

---

## Self-Review

- **Spec coverage:**
  - 「Nix 管理」→ Task 1（input + package）。
  - 「skill 配布」→ Task 3。
  - 「vim キーバインド」→ Task 2。
  - 「日本語マニュアル」→ Task 4。
  - 「検証と反映」→ Task 5。全 spec セクションにタスクが対応。
- **Placeholder scan:** TBD / TODO / 「適宜」等なし。全ステップに実コード・実コマンド・期待出力を記載。
- **Type consistency:** `inputs.herdr.packages.${pkgs.system}.default`（Task 1）、`inputs.herdr`（Task 3 の derivation ソース）、`herdr-skill`（Task 3 内で定義・参照）、`sources.herdr`（Task 3・検証コマンド）で名称一貫。config の chord 値（Task 2）とマニュアル早見表（Task 4）を一致させる検証あり。
