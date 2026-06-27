# Claude Code / Codex の設定と skills を Nix で管理する実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code と Codex の設定（settings.json / CLAUDE.md / config.toml / AGENTS.md）と skills を home-manager で宣言的に管理する。バイナリは mise 管理のまま変えない。

**Architecture:** 設定は home-manager 本体の native モジュール（`programs.claude-code` / `programs.codex`）の typed options で生成する。`package = null` でバイナリ導入を skip し mise 版を維持する。skills は外部 flake agent-skills-nix（`programs.agent-skills`）で `agents/skills/` を Claude と Codex の両方へ link 配布する。ソース参照はモジュールから `inputs.self + "/agents/..."` で行う。

**Tech Stack:** Nix flakes, home-manager (standalone, `mkHome`), agent-skills-nix。

## Global Constraints

- 対象ホスト: `cachyos`（`x86_64-linux`）。switch コマンドは `home-manager switch --flake .#cachyos`。
- バイナリは mise 管理を維持する。両 native モジュールとも `package = null` を必須とする。
- enabledPlugins は `plugins` オプションではなく `settings.enabledPlugins` に直書きする（`plugins`/`mcpServers`/`lspServers` を使うと `package != null` を要求する assertion に触れるため）。
- flake は git tracked ファイルのみ評価する。新規ファイルは build / switch の前に必ず `git add` する。
- switch は既存の非管理ファイルがあると clobber エラーで停止する。Task 7 で退避してから switch する。
- ソース参照は `inputs.self + "/agents/..."`。`../` で遡る相対パスと `dotfilesDir`（flake 外絶対パス）は使わない。
- リポジトリルート: `/home/mkiin/dotfiles`。

---

### Task 1: skills と指示書のソースを整える

**Files:**
- Create: `agents/claude/CLAUDE.md`
- Create: `agents/codex/AGENTS.md`
- 既存: `agents/skills/`（変更なし。untracked なので add 対象）

**Interfaces:**
- Produces: `agents/claude/CLAUDE.md`（`claude-code.nix` の `context` が参照）、`agents/codex/AGENTS.md`（`codex.nix` の `context` が参照）、`agents/skills/`（`agent-skills.nix` の source が参照）。

- [ ] **Step 1: `agents/claude/CLAUDE.md` を作成**

現 `~/.claude/CLAUDE.md` の内容をそのまま移植する。

```markdown
# Claude Code Guidelines

## Clipboard

When you want the user to copy a command, text, or code snippet, pipe it to `gocopy` via Bash instead of just displaying it.

```bash
echo "something to copy" | gocopy
```
This places the content into the user's clipboard.

## Shell Tooling Rules

- Use `rg` (ripgrep) instead of `grep`. Never run `grep` or `grep -r`.
- Use `fd` instead of `find`. Never run `find` for file search.
- **By default, ignore `.gitignore`/`.ignore` rules so excluded files/dirs are not silently dropped.** Pass `--no-ignore --hidden` (rg) / `--no-ignore --hidden` (fd). Shorthand: `rg -uu` and `fd -HI`.
  - Only omit these flags when the user explicitly wants gitignore-aware results (e.g. "only tracked files").
- Examples:
  - Search file contents: `rg -uu "pattern" path/`
  - Find files by name: `fd -HI "pattern" path/`
  - Find files by extension: `fd -HI -e ts`
- If `rg` or `fd` is unavailable in the environment, stop and tell me before falling back.
```

- [ ] **Step 2: `agents/codex/AGENTS.md` を作成**

Claude と同等のツール規約を初期内容とする（実行後に調整可能）。

```markdown
# Codex Global Instructions

## Clipboard

When you want the user to copy a command, text, or code snippet, pipe it to `gocopy` instead of just displaying it.

```bash
echo "something to copy" | gocopy
```

## Shell Tooling Rules

- Use `rg` (ripgrep) instead of `grep`. Never run `grep` or `grep -r`.
- Use `fd` instead of `find`. Never run `find` for file search.
- By default, ignore `.gitignore`/`.ignore` rules: pass `--no-ignore --hidden` (`rg -uu` / `fd -HI`).
  - Only omit these flags when only tracked files are wanted.
- If `rg` or `fd` is unavailable, stop and tell the user before falling back.
```

- [ ] **Step 3: 新規ファイルを git に追加**

Run: `cd /home/mkiin/dotfiles && git add agents/`
Expected: エラーなし。

- [ ] **Step 4: 配置を確認**

Run: `fd -HI . agents/claude agents/codex -t f`
Expected: `agents/claude/CLAUDE.md` と `agents/codex/AGENTS.md` が表示される。

- [ ] **Step 5: コミット**

```bash
git add agents/
git commit -m "feat: add claude/codex global instructions and track skills sources"
```

---

### Task 2: flake.nix に agent-skills-nix input を追加

**Files:**
- Modify: `flake.nix:4-10`（`inputs` ブロック）

**Interfaces:**
- Produces: `inputs.agent-skills`（`default.nix` が `inputs.agent-skills.homeManagerModules.default` を import する）。

- [ ] **Step 1: `inputs` に agent-skills を追加**

`flake.nix` の `inputs` ブロックを次のようにする。

```nix
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-skills = {
      url = "github:Kyure-A/agent-skills-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
```

- [ ] **Step 2: lock を更新**

Run: `cd /home/mkiin/dotfiles && nix flake lock`
Expected: `flake.lock` に `agent-skills` ノードが追加される。エラーなし。

- [ ] **Step 3: lock に input が入ったか確認**

Run: `rg -n "agent-skills" flake.lock`
Expected: `agent-skills` を含む行が表示される。

- [ ] **Step 4: コミット**

```bash
git add flake.nix flake.lock
git commit -m "feat: add agent-skills-nix flake input"
```

---

### Task 3: agent-skills.nix を確定版に修正

**Files:**
- Modify: `nix/modules/home/agent-skills.nix`（書きかけを上書き）

**Interfaces:**
- Consumes: `inputs.self`（flake root）、`programs.agent-skills`（agent-skills-nix の home-manager モジュール、Task 6 で import）。
- Produces: `~/.claude/skills/*` と `~/.codex/skills/*` への link 配置（switch 時）。

- [ ] **Step 1: ファイルを次の内容で上書き**

```nix
{ inputs, ... }:
{
  programs.agent-skills = {
    enable = true;

    sources.local = {
      path = inputs.self + "/agents/skills";
      subdir = ".";
      filter.maxDepth = 1;
    };

    skills.enableAll = [ "local" ];

    targets.claude = { enable = true; structure = "link"; };
    targets.codex  = { enable = true; structure = "link"; };
  };
}
```

- [ ] **Step 2: git に追加**

Run: `cd /home/mkiin/dotfiles && git add nix/modules/home/agent-skills.nix`
Expected: エラーなし。

- [ ] **Step 3: コミット**

```bash
git add nix/modules/home/agent-skills.nix
git commit -m "feat: configure agent-skills for claude and codex targets"
```

注: このモジュールは Task 6 で import するまで評価されない。ここでは構文のみ確定する。

---

### Task 4: claude-code.nix を作成

**Files:**
- Create: `nix/modules/home/programs/claude-code.nix`

**Interfaces:**
- Consumes: `inputs.self`、home-manager native `programs.claude-code`。
- Produces: `~/.claude/settings.json`（symlink）、`~/.claude/CLAUDE.md`（symlink）。

- [ ] **Step 1: ファイルを作成**

現 `~/.claude/settings.json` を再現する。enabledPlugins は `settings` 直書き。

```nix
{ inputs, ... }:
{
  programs.claude-code = {
    enable = true;
    package = null;

    settings = {
      permissions = {
        deny = [
          "Bash(grep:*)"
          "Bash(find:*)"
          "Bash(/usr/bin/grep*)"
          "Bash(/bin/grep*)"
          "Bash(/usr/bin/find*)"
          "Bash(/bin/find*)"
        ];
        defaultMode = "auto";
      };
      enabledPlugins = {
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
        "lua-lsp@claude-plugins-official" = true;
      };
      effortLevel = "high";
      awaySummaryEnabled = false;
      skipDangerousModePermissionPrompt = true;
      skipWorkflowUsageWarning = true;
      skipAutoPermissionPrompt = true;
    };

    context = inputs.self + "/agents/claude/CLAUDE.md";
  };
}
```

- [ ] **Step 2: git に追加**

Run: `cd /home/mkiin/dotfiles && git add nix/modules/home/programs/claude-code.nix`
Expected: エラーなし。

- [ ] **Step 3: コミット**

```bash
git add nix/modules/home/programs/claude-code.nix
git commit -m "feat: manage claude-code settings and memory via native module"
```

注: Task 6 で import するまで評価されない。

---

### Task 5: codex.nix を作成

**Files:**
- Create: `nix/modules/home/programs/codex.nix`

**Interfaces:**
- Consumes: `inputs.self`、home-manager native `programs.codex`。
- Produces: `~/.codex/config.toml`（symlink）、`~/.codex/AGENTS.md`（symlink）。

- [ ] **Step 1: ファイルを作成**

```nix
{ inputs, ... }:
{
  programs.codex = {
    enable = true;
    package = null;

    settings = {
      projects."/home/mkiin/dotfiles".trust_level = "trusted";
    };

    context = inputs.self + "/agents/codex/AGENTS.md";
  };
}
```

- [ ] **Step 2: git に追加**

Run: `cd /home/mkiin/dotfiles && git add nix/modules/home/programs/codex.nix`
Expected: エラーなし。

- [ ] **Step 3: コミット**

```bash
git add nix/modules/home/programs/codex.nix
git commit -m "feat: manage codex config and context via native module"
```

注: Task 6 で import するまで評価されない。

---

### Task 6: default.nix で全モジュールを import しビルド検証

**Files:**
- Modify: `nix/modules/home/default.nix`

**Interfaces:**
- Consumes: `inputs.agent-skills`、`./agent-skills.nix`、`./programs/claude-code.nix`、`./programs/codex.nix`。
- Produces: 評価可能な home 設定（activationPackage がビルドできる状態）。

- [ ] **Step 1: default.nix を更新**

シグネチャを `{ inputs, ... }:` にし、imports へ4エントリを追加する。

```nix
{ inputs, ... }:

{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./agent-skills.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    ./packages.nix
    ./programs/zsh.nix
    ./programs/git.nix
    ./programs/mise.nix
    ./programs/lazygit.nix
    ./programs/starship.nix
    ./programs/sheldon.nix
    ./programs/neovim.nix
    ./programs/yazi.nix
    ./programs/goclipboard.nix
    ./programs/python.nix
  ];

  programs.home-manager.enable = true;

  news.display = "silent";
}
```

- [ ] **Step 2: 新規/変更ファイルを git に追加**

flake は git tree を見るため、評価前に add する。

Run: `cd /home/mkiin/dotfiles && git add -A`
Expected: エラーなし。

- [ ] **Step 3: activationPackage をビルド（switch せず評価検証）**

Run: `nix build --no-link .#homeConfigurations.cachyos.activationPackage 2>&1 | tail -30`
Expected: エラーなしで完了（出力なしまたは store path）。eval エラーや assertion 失敗が出たら、該当モジュールを修正して再実行する。

- [ ] **Step 4: コミット**

```bash
git add -A
git commit -m "feat: wire claude-code, codex, and agent-skills modules into home"
```

---

### Task 7: 既存ファイルを退避し switch して配置を確認

**Files:**
- 変更なし（実環境への適用と検証のみ）。

**Interfaces:**
- Consumes: Task 6 でビルド可能になった home 設定。

- [ ] **Step 1: 退避先を作成**

Run: `mkdir -p ~/agent-migration-backup-2026-06-27`
Expected: エラーなし。

- [ ] **Step 2: Claude の手動ファイルを退避**

Run:
```bash
mv ~/.claude/settings.json ~/agent-migration-backup-2026-06-27/ 2>/dev/null
mv ~/.claude/CLAUDE.md ~/agent-migration-backup-2026-06-27/ 2>/dev/null
mv ~/.claude/skills ~/agent-migration-backup-2026-06-27/claude-skills 2>/dev/null
true
```
Expected: エラーなし（既に無いものは無視）。

- [ ] **Step 3: Codex の手動ファイルを退避**

`config.toml` を退避し、skills の同名衝突分（`superpowers`, `write-sentence`）を退避する。`.system` は agent-skills が触らないため残す。

Run:
```bash
mv ~/.codex/config.toml ~/agent-migration-backup-2026-06-27/codex-config.toml 2>/dev/null
mv ~/.codex/skills/superpowers ~/agent-migration-backup-2026-06-27/codex-superpowers 2>/dev/null
mv ~/.codex/skills/write-sentence ~/agent-migration-backup-2026-06-27/codex-write-sentence 2>/dev/null
true
```
Expected: エラーなし。

- [ ] **Step 4: switch を適用**

Run: `cd /home/mkiin/dotfiles && home-manager switch --flake .#cachyos 2>&1 | tail -30`
Expected: `Activating ...` を経て成功。clobber エラーが出たら、該当ファイルを Step 2/3 と同様に退避して再実行する。

- [ ] **Step 5: Claude の配置を確認**

Run:
```bash
echo "--- settings.json ---"; cat ~/.claude/settings.json
echo "--- CLAUDE.md link ---"; readlink ~/.claude/CLAUDE.md
echo "--- skills ---"; ls -l ~/.claude/skills | head; readlink ~/.claude/skills/cm
```
Expected: settings.json が permissions.deny / enabledPlugins / effortLevel を含む JSON。CLAUDE.md と skills/cm が `/nix/store/...` への symlink。

- [ ] **Step 6: Codex の配置を確認**

Run:
```bash
echo "--- config.toml ---"; cat ~/.codex/config.toml
echo "--- AGENTS.md link ---"; readlink ~/.codex/AGENTS.md
echo "--- skills ---"; ls -l ~/.codex/skills
```
Expected: config.toml に `[projects."/home/mkiin/dotfiles"] trust_level = "trusted"`。AGENTS.md が symlink。skills に local skill が link 配置され、`.system` が残っている。

- [ ] **Step 7: バイナリが mise 版のままか確認**

Run: `which claude codex`
Expected: 両方 `~/.local/share/mise/installs/...` を指す（nix store ではない）。

- [ ] **Step 8: 退避物を照合し、不要なら処分（任意）**

Run: `diff <(cat ~/agent-migration-backup-2026-06-27/settings.json) <(cat ~/.claude/settings.json)`
Expected: 差分なし（内容が一致）。一致を確認したら退避ディレクトリは保持または削除を判断する。

---

## Self-Review

**Spec coverage（design doc の各項目）:**
- Claude settings.json → Task 4
- Claude CLAUDE.md → Task 1 + Task 4（context）
- Codex config.toml → Task 5
- Codex AGENTS.md → Task 1 + Task 5（context）
- skills を Claude/Codex 両方へ → Task 3
- flake input 追加 → Task 2
- default.nix 配線 → Task 6
- 移行（退避）→ Task 7
- 検証 → Task 6（build）+ Task 7（配置確認）
- バイナリ mise 維持（package=null）→ Task 4/5 + Task 7 Step 7

**Placeholder scan:** TODO / TBD / 「適切に処理」等なし。各 .nix と .md の全文を記載済み。

**Type consistency:** `inputs.self + "/agents/..."` は全モジュールで統一。`package = null` は Task 4/5 で一致。target 名 `claude`/`codex` は agent-skills-nix のデフォルトパス名と一致。
