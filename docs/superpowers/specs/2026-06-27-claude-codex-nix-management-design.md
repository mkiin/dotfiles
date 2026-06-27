# Claude Code / Codex の設定と skills を Nix で管理する設計

## 目的

Claude Code と Codex の設定ファイルと skills を、home-manager の宣言的管理下に置く。

現状、これらは手動でインストールおよび配置されている。

`~/.claude/settings.json` と `~/.codex/config.toml` は手で編集された実ファイルであり、skills は `~/.claude/skills` と `~/.codex/skills` に手動配置されたディレクトリである。

これらを Nix のソースに移し、`switch` で再現できる状態にする。

ただしバイナリ自体は対象外とする。

`claude` と `codex` は mise で導入済みであり、本設計はその運用を変えない。

## スコープ

管理対象は次の四つの設定と skills である。

- **Claude settings.json**：permissions、enabledPlugins、effortLevel などの動作設定
- **Claude CLAUDE.md**：グローバル指示書
- **Codex config.toml**：グローバル設定とプロジェクト信頼設定
- **Codex AGENTS.md**：グローバル指示書
- **skills**：`agents/skills/` 配下のローカル skill 群を Claude と Codex の両方へ配布

バイナリ（`claude` / `codex` の実行ファイル）は mise 管理のままとし、Nix では導入しない。

## 方式の選択

設定の生成には home-manager 本体の native モジュール（`programs.claude-code` と `programs.codex`）を使う。

両モジュールは `settings`、`context`、`package` などの typed options を備えており、`settings.json` や `config.toml` を自前で組み立てる必要がない。

これはプロジェクトの方針（typed options を優先し、raw file への降格は最後の手段とする）に合致する。

skills の配布には外部 flake の agent-skills-nix（`programs.agent-skills`）を使う。

native モジュールにも `skills` オプションはあるが、agent-skills-nix を採用する理由は、単一のソースから複数のエージェント（Claude、Codex、将来は他のツール）へ統一的に配布でき、外部 skill の取り込みやコマンドの store パス書き換え（transform）といった拡張余地を残せる点にある。

### native モジュールの確認済みの挙動

設計の前提として、home-manager の `programs.claude-code` と `programs.codex` の実装を確認した。

- `package` は両モジュールとも `nullable = true` であり、`package = null` でバイナリの導入を skip できる。`home.packages` への追加は `package != null` のときに限られる。
- `settings` は `home.file` の symlink として配置される。生成物は Nix store 上にあり read-only である。
- `context` は path 指定で symlink として配置される。Claude は `~/.claude/CLAUDE.md`、Codex は `~/.codex/AGENTS.md` に書かれる。
- `programs.claude-code` には `mcpServers`、`lspServers`、`plugins` を使うと `package != null` を要求する assertion がある。

最後の点が enabledPlugins の扱いを決める。

プラグインの有効化フラグを `plugins` オプションで宣言すると package が必須になり、mise 版との併存が崩れる。

これを避けるため、enabledPlugins は `plugins` オプションではなく `settings` 属性に直接書く。

`settings` は任意の JSON 属性を受け取るため、`settings.enabledPlugins` として書けば assertion に触れず `package = null` を維持できる。

### 受け入れたトレードオフ

native の `settings` は read-only の symlink であり、`/plugin` などによるランタイムの書き込みはできない。

enabledPlugins や effortLevel を Nix で宣言し、UI から変更しない運用とする。

これは設定のソースを Nix 側に一本化する方針と一致する。

## ディレクトリ構成

dotfiles 内に skills と指示書のソースを置く。

```
agents/
├── skills/            # 既存。ローカル skill 群（cm, write-sentence, cloudflare 系 など）
├── claude/CLAUDE.md   # 新規。現 ~/.claude/CLAUDE.md の内容を移植
└── codex/AGENTS.md    # 新規。Codex グローバル指示書
```

`settings.json` と `config.toml` には専用のソースファイルを作らない。

これらは native モジュールの `settings` 属性として Nix モジュール内に定義する。

## モジュール構成

既存の慣習（`nix/modules/home/programs/<tool>.nix` に1ツール1モジュール）に合わせ、三つのモジュールに分ける。

### nix/modules/home/programs/claude-code.nix（新規）

```nix
{ ... }:
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

    context = ../../../agents/claude/CLAUDE.md;
  };
}
```

`skills` は指定しない。

`~/.claude/skills` は agent-skills-nix が管理するため、native 側で skills を指定すると同じパスを二重に管理して衝突する。

### nix/modules/home/programs/codex.nix（新規）

```nix
{ ... }:
{
  programs.codex = {
    enable = true;
    package = null;

    settings = {
      projects."/home/mkiin/dotfiles".trust_level = "trusted";
    };

    context = ../../../agents/codex/AGENTS.md;
  };
}
```

現状の `config.toml` にある `tui.model_availability_nux` は TUI のローカル状態であり、Nix では持たない。

`projects."/home/mkiin/dotfiles".trust_level` は保持する。

`skills` は指定しない。

### nix/modules/home/agent-skills.nix（書きかけを修正）

```nix
{
  programs.agent-skills = {
    enable = true;

    sources.local = {
      path = ../../../agents/skills;
      subdir = ".";
      filter.maxDepth = 1;
    };

    skills.enableAll = [ "local" ];

    targets.claude = { enable = true; structure = "link"; };
    targets.codex  = { enable = true; structure = "link"; };
  };
}
```

書きかけにあった `dest` の明示は削除する。

agent-skills-nix は target ごとにデフォルトパス（Claude は `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills`、Codex は `${CODEX_HOME:-$HOME/.codex}/skills`）を内蔵しており、`enable = true` だけで現環境のパスに一致する。

`structure = "link"` は `home.file` の symlink で各 skill を個別に配置する。

`rsync --delete` を使う `copy-tree` や `symlink-tree` と異なり、配布先の非管理ファイルを一括削除しない。

`filter.maxDepth = 1` を明示する理由は、agent-skills-nix の discovery がデフォルトで無制限再帰になったためである。

`agents/skills/` の各 skill は1階層下にあり、その配下に `references/` を持つものもある。

`maxDepth = 1` で直下の skill ディレクトリだけを拾い、`references/` 内を誤って skill として解釈しない。

## flake 統合

### flake.nix

inputs に agent-skills-nix を1つ追加する。

```nix
agent-skills = {
  url = "github:Kyure-A/agent-skills-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### nix/modules/home/default.nix

現在のシグネチャは `{ ... }:` である。

agent-skills-nix の home-manager モジュールを取り込むため `{ inputs, ... }:` に変える。

`inputs` は `mkHome` の `extraSpecialArgs` から渡るため、追加の配線は要らない。

imports に四つのエントリを足す。

```nix
{ inputs, ... }:
{
  imports = [
    inputs.agent-skills.homeManagerModules.default
    ./agent-skills.nix
    ./programs/claude-code.nix
    ./programs/codex.nix
    # 既存のエントリは維持
  ];
}
```

native の `programs.claude-code` と `programs.codex` は home-manager 本体のモジュールであり、外部 flake を要しない。

input の追加が必要なのは agent-skills-nix だけである。

## 移行手順

home-manager は配置先に非管理の実ファイルがあると clobber エラーで停止する。

`switch` の前に、現在の手動ファイルを退避する必要がある。

- `~/.claude/settings.json`：内容は `claude-code.nix` の `settings` に移植済み。退避する。
- `~/.claude/CLAUDE.md`：内容は `agents/claude/CLAUDE.md` に移植済み。退避する。
- `~/.claude/skills/`：実ディレクトリ群。agent-skills-nix の link 配置と衝突するため退避する。
- `~/.codex/config.toml`：内容は `codex.nix` の `settings` に移植済み。退避する。
- `~/.codex/skills/`：`.system` は別名のため残るが、`superpowers` や `write-sentence` は同名衝突しうる。衝突分を退避する。

退避は削除ではなくバックアップとし、移行後に内容を照合してから処分する。

## 検証

成功条件は次のとおりである。

- `home-manager switch --flake .#cachyos` がエラーなく完了する。
- `~/.claude/settings.json` が現状と同一の JSON を持つ。
- `~/.claude/skills/cm` などが Nix store への symlink として存在する。
- `~/.codex/skills/` に skill が配置される。
- `~/.claude/CLAUDE.md` と `~/.codex/AGENTS.md` が symlink として配置される。
- `claude` と `codex` の実行ファイルが従来どおり mise 版を指す。

## やらないこと

- バイナリの Nix 管理（nix-claude-code や llm-agents.nix の導入）。
- MCP サーバーの Nix 管理。
- agents（subagent 定義）や commands、output-styles の Nix 管理。
- Codex の TUI ローカル状態の Nix 管理。
