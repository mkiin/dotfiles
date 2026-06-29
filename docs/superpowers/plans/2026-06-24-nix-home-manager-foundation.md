# Nix Home Manager Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** CachyOS と WSL2 で、Nix と Home Manager により共通の開発環境を再現できる基盤を作る。

**Architecture:** standalone Home Manager の `.#cachyos` と `.#wsl` を `flake.nix` から公開する。共通モジュールは Nix package と設定配置を担当し、環境モジュールは環境変数だけを追加する。既存のアプリ設定はトップレベルへ移し、Home Manager が配布する。

**Tech Stack:** Nix flakes、Home Manager、Nixpkgs、mise、Lazy.nvim、agent-skills-nix。

## Global Constraints

- ユーザー名は `mkiin`、Linux home は `/home/mkiin`。
- Home Manager の出力名は `cachyos` と `wsl`。
- Nix が zsh、Git、Neovim、WezTerm、共通 CLI、mise 本体を所有する。
- mise は言語ランタイム、uv、Supabase、Codex、Claude Code、Serena、rtk を所有する。
- Nixvim と chezmoi は導入しない。
- CopyQ と SwayNC は移行せず削除する。
- `awww`、`matugen`、`wallust` は Nix package とする。
- ghq と bootstrap の完全な仕様はこの計画の対象外とする。

---

## File Structure

- Create: `flake.nix`、`flake.lock`
- Create: `nix/home.nix`
- Create: `nix/home/common.nix`、`nix/home/wsl.nix`、`nix/home/cachyos.nix`
- Create: `nix/home/zsh.nix`、`nix/home/git.nix`、`nix/home/mise.nix`、`nix/home/neovim.nix`、`nix/home/wezterm.nix`
- Create: `nix/home/agent-skills.nix`、`nix/home/codex.nix`、`nix/home/claude.nix`
- Create: `zsh/zshrc`、`zsh/zshenv`、`git/config`、`mise/config.toml`
- Create: `nvim/`、`wezterm/`
- Create: `agents/skills/README.md`
- Modify: `home/dot_zshrc.tmpl`、`home/dot_zshenv`、`home/dot_gitconfig`、`home/dot_config/mise/config.toml`、`home/dot_config/nvim/`、`home/dot_config/wezterm/wezterm.lua`
- Delete: chezmoi-managed paths only after their replacements are active.

### Task 1: Create the standalone Home Manager flake

**Files:**

- Create: `flake.nix`
- Create: `nix/home.nix`
- Create: `nix/home/common.nix`
- Create: `nix/home/wsl.nix`
- Create: `nix/home/cachyos.nix`

- [ ] **Step 1: Generate the standalone Home Manager scaffold**

Run from the repository root: `nix run home-manager/master -- init .`

Expected: `flake.nix` and `home.nix` are generated in the repository root without activating a Home Manager generation.

- [ ] **Step 2: Move the generated module and add the evaluation check**

Run: `mkdir -p nix/home && git mv home.nix nix/home.nix`

Add a `checks.x86_64-linux.flake-evaluation` derivation to `flake.nix` that evaluates both Home Manager outputs.

- [ ] **Step 3: Run the check before adding environment modules**

Run: `nix flake check`

Expected: FAIL because `nix/home/common.nix`, `nix/home/cachyos.nix`, and `nix/home/wsl.nix` do not exist.

- [ ] **Step 4: Implement the flake and modules**

Keep the generated `inputs.nixpkgs` and `inputs.home-manager` relation, with Home Manager following Nixpkgs.

Define `homeConfigurations.cachyos` and `homeConfigurations.wsl` with `home.username = "mkiin"`, `home.homeDirectory = "/home/mkiin"`, and modules `[ ./nix/home.nix ./nix/home/cachyos.nix ]` or `[ ./nix/home.nix ./nix/home/wsl.nix ]`.

Set `home.stateVersion = "25.11"` and `programs.home-manager.enable = true` in `nix/home.nix`.

Make `nix/home.nix` import `./home/common.nix`.

- [ ] **Step 5: Verify both outputs**

Run: `nix flake check && nix run nixpkgs#home-manager -- build --flake .#cachyos && nix run nixpkgs#home-manager -- build --flake .#wsl`

Expected: all commands exit 0.

- [ ] **Step 6: Commit**

```sh
git add flake.nix flake.lock nix/home.nix nix/home/common.nix nix/home/wsl.nix nix/home/cachyos.nix
git commit -m "feat: add Home Manager flake foundation"
```

### Task 2: Move and manage shell, Git, and mise configuration

**Files:**

- Create: `zsh/zshrc`、`zsh/zshenv`、`git/config`、`mise/config.toml`
- Create: `nix/home/zsh.nix`、`nix/home/git.nix`、`nix/home/mise.nix`
- Modify: `nix/home/common.nix`
- Delete: `home/dot_zshrc.tmpl`、`home/dot_zshenv`、`home/dot_gitconfig`、`home/dot_config/mise/config.toml`

- [ ] **Step 1: Write the configuration-path evaluation check**

Add a `checks.x86_64-linux.common-config-paths` derivation that fails unless the CachyOS configuration exposes `.zshrc`, `.zshenv`, `.gitconfig`, and `mise/config.toml` in `home.file` or `xdg.configFile`.

- [ ] **Step 2: Run the check before creating modules**

Run: `nix flake check`

Expected: FAIL because the four managed paths are absent.

- [ ] **Step 3: Move configuration files and split mise ownership**

Use `git mv` to move the four existing files to their new top-level locations.

Remove common CLI entries and `chezmoi` from `mise/config.toml`.

Keep `go`、`bun`、`rust`、`deno`、`node`、`uv`、`supabase`、`claude-code`、`pipx:serena-agent`、`github:rtk-ai/rtk`、`aqua:codex`.

- [ ] **Step 4: Implement Home Manager modules**

`zsh.nix` adds `pkgs.zsh` and assigns the two zsh files to `.zshrc` and `.zshenv`.

`git.nix` adds `pkgs.git` and assigns `git/config` to `.gitconfig`.

`mise.nix` adds `pkgs.mise` and assigns `mise/config.toml` to `xdg.configFile."mise/config.toml"`.

`common.nix` imports all three modules and adds `ripgrep`、`fd`、`bat`、`eza`、`jq`、`fzf`、`zoxide`、`lazygit`、`lazydocker`、`gh`、`starship`、`sheldon`、`shellcheck`、`shfmt`、`delta`、`mo` to `home.packages`.

- [ ] **Step 5: Verify configuration ownership**

Run: `nix flake check && nix run nixpkgs#home-manager -- build --flake .#cachyos`

Expected: exit 0 and the generated home-files tree contains the four configuration paths.

- [ ] **Step 6: Commit**

```sh
git add -A nix/home zsh git mise home
git commit -m "feat: manage shell Git and mise with Home Manager"
```

### Task 3: Preserve Lazy.nvim and deploy terminal configuration

**Files:**

- Create: `nix/home/neovim.nix`、`nix/home/wezterm.nix`
- Create: `nvim/`、`wezterm/`
- Modify: `nix/home/common.nix`
- Delete: `home/dot_config/nvim/`、`home/dot_config/wezterm/wezterm.lua`

- [ ] **Step 1: Write the package and path evaluation check**

Extend `common-config-paths` so it fails unless `neovim` and `wezterm` are in the common package list and the generated configuration contains `nvim/` and `wezterm/wezterm.lua`.

- [ ] **Step 2: Run the check before migration**

Run: `nix flake check`

Expected: FAIL because the Neovim and WezTerm modules are absent.

- [ ] **Step 3: Move existing settings without changing their format**

Use `git mv home/dot_config/nvim nvim`.

Use `git mv home/dot_config/wezterm wezterm`.

Keep `lazy-lock.json` and all Lua files intact.

- [ ] **Step 4: Implement the two modules**

`neovim.nix` installs `pkgs.neovim` and recursively assigns `nvim/` to `xdg.configFile."nvim"`.

`wezterm.nix` installs `pkgs.wezterm` and assigns `wezterm/wezterm.lua` to `xdg.configFile."wezterm/wezterm.lua"`.

Import both modules from `common.nix`.

- [ ] **Step 5: Verify config generation and editor startup**

Run: `nix flake check && nix run nixpkgs#home-manager -- build --flake .#wsl`

Expected: exit 0.

After the first switch, run: `nvim --headless '+quit'`.

Expected: exit 0.

- [ ] **Step 6: Commit**

```sh
git add -A nix/home nvim wezterm home
git commit -m "feat: manage Neovim and WezTerm with Home Manager"
```

### Task 4: Add shared AI configuration and agent skills

**Files:**

- Create: `nix/home/agent-skills.nix`、`nix/home/codex.nix`、`nix/home/claude.nix`
- Create: `agents/skills/README.md`
- Create: `codex/`、`claude/`
- Modify: `flake.nix`、`nix/home/common.nix`

- [ ] **Step 1: Write the agent skill target check**

Add a flake check that evaluates the agent-skills module and fails unless it targets both the Codex and Claude Code skill directories.

- [ ] **Step 2: Run the check before adding the input**

Run: `nix flake check`

Expected: FAIL because `agent-skills-nix` is not an input.

- [ ] **Step 3: Add the agent-skills input and module**

Add `github:Kyure-A/agent-skills-nix` as a flake input following `nixpkgs`.

Configure local source `agents/skills` and targets for Codex and Claude Code.

Leave credential files and authentication state unmanaged.

- [ ] **Step 4: Verify generated targets**

Run: `nix flake check && nix run nixpkgs#home-manager -- build --flake .#cachyos`

Expected: exit 0 and generated home-files include both skill target paths.

- [ ] **Step 5: Commit**

```sh
git add flake.nix flake.lock nix/home agents codex claude
git commit -m "feat: manage shared AI configuration and skills"
```

### Task 5: Add CachyOS user-space package module and remove obsolete applications

**Files:**

- Modify: `nix/home/cachyos.nix`
- Delete: `home/dot_config/swaync/`、`home/dot_config/systemd/user/symlink_swaync.service`
- Modify: `packages/pacman.txt`

- [ ] **Step 1: Write the CachyOS package evaluation check**

Add a flake check that fails unless `awww`、`matugen`、`wallust` occur in `homeConfigurations.cachyos.config.home.packages`.

- [ ] **Step 2: Run the check before adding packages**

Run: `nix flake check`

Expected: FAIL because the three packages are absent.

- [ ] **Step 3: Implement the CachyOS module**

Add `awww`、`matugen`、`wallust` to `home.packages` in `nix/home/cachyos.nix`.

Delete SwayNC configuration and its user service.

Remove `copyq` and `swaync` from `packages/pacman.txt`.

- [ ] **Step 4: Verify the package closure**

Run: `nix flake check && nix run nixpkgs#home-manager -- build --flake .#cachyos`

Expected: exit 0.

- [ ] **Step 5: Commit**

```sh
git add nix/home/cachyos.nix packages/pacman.txt
git rm -r home/dot_config/swaync home/dot_config/systemd/user/symlink_swaync.service
git commit -m "feat: manage CachyOS user packages with Nix"
```

### Task 6: Apply the initial configuration and validate ownership

**Files:**

- Modify: `SETUP.md`

- [ ] **Step 1: Document first-apply commands**

Write the initial command for each output.

```sh
nix run nixpkgs#home-manager -- switch --flake .#cachyos -b hm-pre-migration
nix run nixpkgs#home-manager -- switch --flake .#wsl -b hm-pre-migration
```

- [ ] **Step 2: Apply CachyOS configuration**

Run: `nix run nixpkgs#home-manager -- switch --flake .#cachyos -b hm-pre-migration`

Expected: exit 0 and any conflicting files end in `.hm-pre-migration`.

- [ ] **Step 3: Verify executables and settings**

Run: `command -v zsh git nvim wezterm mise awww matugen wallust`

Expected: each Nix-owned executable resolves under `/nix/store/` or `~/.nix-profile/`.

Run: `mise install && mise doctor && nvim --headless '+quit'`.

Expected: all commands exit 0.

- [ ] **Step 4: Preserve the remaining chezmoi source until desktop migration**

Do not remove `home/`, `.chezmoiroot`, package snapshots, hooks, or the legacy bootstrap script in this plan.

They contain CachyOS desktop settings whose migration is deferred.

- [ ] **Step 5: Commit**

```sh
git add SETUP.md
git commit -m "docs: document Home Manager foundation"
```

## Deferred Follow-up Plan

Create a separate plan after investigating ghq and the complete CachyOS and WSL bootstrap inventory.

It must cover clone placement, system-wide shell registration, native package installation, SDDM, desktop portals, drivers, daemons, Windows-side WezTerm, and the remaining CachyOS desktop configuration.
