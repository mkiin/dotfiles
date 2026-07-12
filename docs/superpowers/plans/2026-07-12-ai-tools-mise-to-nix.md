# AI ツール（claude-code / codex / serena）mise → Nix 移管 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** claude-code / codex を `numtide/llm-agents.nix` overlay で、serena を `natsukium/mcp-servers-nix` の home-manager モジュールで宣言的に管理し、mise から AI ツール 3 件を剥がす。

**Architecture:** flake input に `llm-agents.nix` を追加し `lib/default.nix` の `defaultOverlays` に overlay を挿す。既存の `programs.claude-code` / `programs.codex`（現状 `package = null`）の `package` を overlay 由来の `pkgs.claude-code` / `pkgs.codex` に差し替える。serena は既存未使用 input `mcp-servers-nix` の HM モジュールを `home-manager/default.nix` で import し、新規 `home-manager/ai/serena/default.nix` で宣言、両クライアントに `enableMcpIntegration` で配線する。最後に `mise/config.toml` から 3 行削除。

**Tech Stack:** Nix flakes, home-manager, NixOS, treefmt (deadnix/nixfmt)

## Global Constraints

- パッケージ本体は集約 `packages.nix`（`cli`/`desktop`/`nixos/core`）で宣言。機能ディレクトリの `default.nix` は設定専用。ただし `programs.<foo>.package = ...;` は「設定機構」であり直書き禁止の対象外（本計画はこれに依拠）。
- `home.packages` / `environment.systemPackages` へのパッケージ直書き禁止。
- `../../../` のような親ディレクトリ遡り相対パス参照を新規に書かない（`hosts/` の imports 組み立ては既存パターンにつき対象外）。
- コメントは「なぜ」を 1〜2 行のみ。逐条コメント禁止。
- `nix run .#build` と `nix run .#fmt -- --fail-on-change` を最終的に両方通す。
- 1 機能 = 1 ディレクトリ = 1 `default.nix`。

## 裏取り済みの確定値（`nix eval` / 一次情報で確認済み）

- llm-agents.nix overlay 名: `default`（隔離 nixpkgs）/ `shared-nixpkgs`（共有）→ **`shared-nixpkgs` を使用**。
- パッケージ attribute: `shared-nixpkgs` overlay は top-level ではなく **`pkgs.llm-agents` 名前空間**に提供する。参照は **`pkgs.llm-agents.claude-code`**（実体 `claude-code-2.1.207`）/ **`pkgs.llm-agents.codex`**（実体 `codex-0.144.1`）。top-level `pkgs.claude-code` は nixpkgs の古い版を掴むため使わない。
- numtide cache: substituter `https://cache.numtide.com` / 公開鍵 `niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=`。
- mcp-servers-nix HM モジュール: import 名 `inputs.mcp-servers-nix.homeManagerModules.default`。サーバ宣言 `mcp-servers.programs.<name>`。中央レジストリ有効化 `programs.mcp.enable = true;`。クライアント配線 `programs.<client>.enableMcpIntegration = true;`。
- 現状 `home-manager/default.nix` は `inputs.agent-skills.homeManagerModules.default` を import 済み（同じ場所に mcp-servers-nix を追加する）。
- AI スタック（`home-manager/ai`）は nixos・wsl 両ホストへ共有適用される。

---

### Task 1: claude-code / codex を llm-agents.nix overlay に切替

**Files:**

- Modify: `flake.nix`（inputs へ `llm-agents` 追加、`nixConfig` の substituter/key 追加）
- Modify: `lib/default.nix:12-28`（`defaultOverlays` に overlay 追加）
- Modify: `home-manager/ai/claude-code/default.nix`（module 引数に `pkgs`、`package = null;` → `package = pkgs.llm-agents.claude-code;`）
- Modify: `home-manager/ai/codex/default.nix`（`package = null;` → `package = pkgs.llm-agents.codex;`。`pkgs` は既存引数に無いので追加）

**Interfaces:**

- Produces: overlay 経由で `pkgs.llm-agents.claude-code` / `pkgs.llm-agents.codex` が全 `pkgs` に露出。Task 2 の serena 配線とは独立。

- [ ] **Step 1: flake input を追加**

`flake.nix` の `inputs = { ... }` 内、既存 `mcp-servers-nix` の近くに追記:

```nix
    llm-agents.url = "github:numtide/llm-agents.nix";
    llm-agents.inputs.nixpkgs.follows = "nixpkgs";
```

- [ ] **Step 2: numtide バイナリキャッシュを nixConfig に追加**

`flake.nix` 先頭の `nixConfig` ブロックの各リストへ追記（hyprland 等の既存要素は残す）:

```nix
  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org"
      "https://ezkea.cachix.org"
      "https://mkiin-dotfiles.cachix.org"
      "https://cache.numtide.com"
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "ezkea.cachix.org-1:/Hcp/kUFmp+2FLdzXlmDF9SHFsMzQoPZWH8fXOTdVBM="
      "mkiin-dotfiles.cachix.org-1:LJ6X3uYDglOyphSEDcaz/wrwGDmetitbmrUDkwvUzjM="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
```

- [ ] **Step 3: overlay を defaultOverlays に追加**

`lib/default.nix` の `defaultOverlays` リスト（現状 cantarell-fonts のピン 1 要素）に追記。理由コメントを 1 行付ける:

```nix
  defaultOverlays = [
    # claude-code / codex を numtide/llm-agents.nix（日次更新・prebuilt）から供給する。
    inputs.llm-agents.overlays.shared-nixpkgs

    # unstable の cantarell-fonts 0.311 は上流で otfautohint がビルド失敗し、かつ
    # バイナリキャッシュにも無い（steam-run の FHS 環境が間接的に引き込む）。
    # キャッシュ済みで動作する stable 版 (0.303.1) にピン留めして switch ブロックを回避する。
    # 上流修正/キャッシュ復旧後に削除してよい。
    (_final: prev: {
      inherit
        (
          (import inputs.nixpkgs-stable {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          })
        )
        cantarell-fonts
        ;
    })
  ];
```

- [ ] **Step 4: claude-code の package を差し替え**

`home-manager/ai/claude-code/default.nix` の関数引数に `pkgs` を追加し、`package` を差し替える:

```nix
{ inputs, config, pkgs, ... }:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;
```

（`settings` 以下は変更しない。）

- [ ] **Step 5: codex の package を差し替え**

`home-manager/ai/codex/default.nix` の関数引数に `pkgs` を追加し、`package` を差し替える:

```nix
{
  inputs,
  lib,
  pkgs,
  homeDirectory,
  username,
  ...
}:
```

`programs.codex` 内:

```nix
    enable = true;
    package = pkgs.llm-agents.codex;
```

- [ ] **Step 6: lock 更新とビルド検証**

Run:

```bash
nix flake lock --update-input llm-agents
nix run .#build
```

Expected: エラーなくビルド完了。`claude-code` / `codex` が `cache.numtide.com` から取得されるログが出る（ソースビルドしない）。

- [ ] **Step 7: パッケージ解決を確認**

Run:

```bash
nix eval --raw .#nixosConfigurations.nixos.config.home-manager.users.mkiin.programs.claude-code.package.name
nix eval --raw .#nixosConfigurations.nixos.config.home-manager.users.mkiin.programs.codex.package.name
```

Expected: **llm-agents 由来の版**（`claude-code-2.1.207` 以上 / `codex-0.144.1` 以上）を出力すること。nixpkgs の古い版（`claude-code-2.1.204` / `codex-0.142.5`）が出たら overlay 参照ミス（top-level `pkgs.claude-code` を掴んでいる）。必ず `pkgs.llm-agents.claude-code` / `pkgs.llm-agents.codex` を参照する。

- [ ] **Step 8: フォーマット**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なし（deadnix 未使用束縛エラーが無い）。

- [ ] **Step 9: コミット**

```bash
git add flake.nix flake.lock lib/default.nix home-manager/ai/claude-code/default.nix home-manager/ai/codex/default.nix
git commit -m "feat(ai): claude-code/codex を llm-agents.nix overlay で管理

package=null(mise供給) から llm-agents.nix の pkgs.claude-code/pkgs.codex に
切替。numtide cache を substituter へ追加してソースビルドを回避。"
```

---

### Task 2: serena を mcp-servers-nix で宣言し両クライアントへ配線

**Files:**

- Modify: `home-manager/default.nix`（`imports` に `inputs.mcp-servers-nix.homeManagerModules.default` 追加）
- Create: `home-manager/ai/serena/default.nix`
- Modify: `home-manager/ai/default.nix`（`imports` に `./serena` 追加）
- Modify: `home-manager/ai/claude-code/default.nix`（`enableMcpIntegration = true;` 追加）
- Modify: `home-manager/ai/codex/default.nix`（`enableMcpIntegration = true;` 追加）

**Interfaces:**

- Consumes: Task 1 で有効化された `programs.claude-code` / `programs.codex` の module（`enableMcpIntegration` オプションは mcp-servers-nix の HM モジュールがこれらへ注入する）。
- Produces: `mcp-servers.programs.serena` により serena が中央レジストリに登録され、両クライアントの MCP 設定へ出力される。

- [ ] **Step 1: mcp-servers-nix の HM モジュールを import**

`home-manager/default.nix` の `imports` に 1 行追加（既存の agent-skills と並置）:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    inputs.mcp-servers-nix.homeManagerModules.default
    ./cli
    ./editor
    ./ai
  ];

  news.display = "silent";
}
```

- [ ] **Step 2: serena モジュールを新規作成**

Create `home-manager/ai/serena/default.nix`:

```nix
{ ... }:
{
  # serena 本体は mcp-servers-nix の derivation に内包（PATH には載せない）。
  # context は claude-code/codex 両対応の汎用のまま既定に任せる。
  programs.mcp.enable = true;
  mcp-servers.programs.serena.enable = true;
}
```

- [ ] **Step 3: ai の集約 imports に serena を追加**

`home-manager/ai/default.nix`:

```nix
{ ... }:
{
  imports = [
    ./agent-skills
    ./claude-code
    ./codex
    ./serena
  ];
}
```

- [ ] **Step 4: claude-code に MCP 統合を有効化**

`home-manager/ai/claude-code/default.nix` の `programs.claude-code` 冒頭に追加:

```nix
  programs.claude-code = {
    enable = true;
    package = pkgs.llm-agents.claude-code;
    enableMcpIntegration = true;
```

- [ ] **Step 5: codex に MCP 統合を有効化**

`home-manager/ai/codex/default.nix` の `programs.codex` 冒頭に追加:

```nix
  programs.codex = {
    enable = true;
    package = pkgs.llm-agents.codex;
    enableMcpIntegration = true;
```

- [ ] **Step 6: ビルド検証**

Run: `nix run .#build`
Expected: エラーなく完了。既存 `programs.claude-code.settings`（effort 等）と競合しない。

- [ ] **Step 7: 生成 MCP 設定に serena が入るか確認**

Run:

```bash
nix eval --json .#nixosConfigurations.nixos.config.home-manager.users.mkiin.programs.claude-code.mcpServers 2>/dev/null \
  || echo "属性パスが異なる場合は build 済み home 世代の生成ファイルを確認する"
```

Expected: `serena` を含む JSON。属性パスがモジュール実装で異なる場合は、`nix run .#build` 後に生成される claude-code / codex の MCP 設定ファイル（`.mcp.json` / `.mcp.toml` 相当）を store 経由で確認する。最終確認は Task 4 後の switch で `claude mcp list` に serena が出ることをもって行う。

- [ ] **Step 8: フォーマット**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なし。

- [ ] **Step 9: コミット**

```bash
git add home-manager/default.nix home-manager/ai/default.nix home-manager/ai/serena/default.nix home-manager/ai/claude-code/default.nix home-manager/ai/codex/default.nix
git commit -m "feat(ai): serena を mcp-servers-nix で宣言し claude-code/codex へ配線

mcp-servers-nix の HM モジュールを import し serena を中央レジストリに登録。
両クライアントに enableMcpIntegration を付けて MCP 設定へ自動出力する。"
```

---

### Task 3: mise から AI ツール 3 件を剥がす

**Files:**

- Modify: `home-manager/cli/mise/config.toml`

**Interfaces:**

- Consumes: Task 1・Task 2 で claude-code / codex / serena が Nix 管理へ移行済みであること。

- [ ] **Step 1: mise の AI エントリを削除**

`home-manager/cli/mise/config.toml` の `[tools]` から次の 3 行を削除する（言語ランタイム群と `[settings]` は残す）:

```
claude-code = "latest"
"pipx:serena-agent" = "latest"
"aqua:openai/codex" = "latest"
```

削除後の `# --- AI ---` コメントは配下エントリが無くなるため一緒に削除する。

- [ ] **Step 2: ビルド検証**

Run: `nix run .#build`
Expected: エラーなく完了。

- [ ] **Step 3: フォーマット**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 変更なし。

- [ ] **Step 4: コミット**

```bash
git add home-manager/cli/mise/config.toml
git commit -m "chore(mise): AI ツール(claude-code/codex/serena)を mise から除去

Nix(llm-agents.nix / mcp-servers-nix)へ移行済みのため mise 管理を撤去。
言語ランタイム管理としての mise は存続。"
```

---

### Task 4: 実機反映と動作確認

**Files:** なし（反映と手動検証のみ）

- [ ] **Step 1: switch で反映**

Run: `nix run .#switch`
Expected: 反映成功。（WSL を使う場合は別途 `nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl`。）

- [ ] **Step 2: バイナリが nix store 由来か確認**

Run:

```bash
command -v claude
command -v codex
claude --version
codex --version
```

Expected: パスが `/nix/store/...` または home-manager の profile 配下を指す。mise shim (`~/.local/share/mise/...`) を指さない。

- [ ] **Step 3: serena が両クライアントで MCP 認識されるか確認**

Run:

```bash
claude mcp list
```

Expected: `serena` が一覧に出る。codex 側は生成された MCP 設定（`.mcp.toml` / `mcp_servers`）に serena が含まれることを確認。

- [ ] **Step 4: mise から消えたか確認**

Run: `mise ls`
Expected: `claude-code` / `serena-agent` / `codex` が一覧に無い。言語ランタイム（node/go/rust 等）は残る。

---

## Self-Review（記入済み）

**Spec coverage:**

- 設計 §1（llm-agents overlay 一本化）→ Task 1 で input・cache・overlay・両 package 差し替えを網羅。
- 設計 §2（serena を mcp-servers-nix HM モジュール）→ Task 2 で import・serena モジュール・両クライアント配線を網羅。
- 設計 §3（mise から剥がす）→ Task 3。
- 設計「検証」節（nix eval 裏取り・build・fmt・switch 後確認）→ Task 1 Step6-8 / Task 4。
- unfree は `mkPkgs` の `allowUnfree = true` で既充足のため専用タスク不要（設計通り）。

**Placeholder scan:** コード変更ステップは全て具体コードを提示。Task 2 Step7 の属性パスは実装差異に備えたフォールバック手順を明記済み（曖昧な TODO ではなく代替検証を定義）。

**Type consistency:** overlay 名 `shared-nixpkgs`、package 名 `claude-code`/`codex`、オプション `enableMcpIntegration` / `programs.mcp.enable` / `mcp-servers.programs.serena` は全タスクで一貫（`nix eval`・一次情報で裏取り済み）。

## 想定リスク

- Task 2 Step7 の `mcpServers` 属性パスがモジュール実装と異なる可能性 → build は通るのでフォールバックの生成ファイル確認、最終は switch 後 `claude mcp list` で確定。
- `enableMcpIntegration` が既存 `programs.claude-code.settings`（read-only symlink 制約）と競合する場合 → MCP 出力先を分離するオプションを検討（発生時に対処）。
- numtide cache 未ヒット時 → prebuilt バイナリ主体のためソースビルドコストは限定的。
