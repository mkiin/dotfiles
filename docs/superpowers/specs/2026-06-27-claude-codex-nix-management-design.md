# Claude Code / Codex の設定と skills を Nix で管理する設計

## 目的

Claude Code と Codex の設定と skills を、home-manager の宣言的管理下に置く。

設定の本丸を dotfiles リポジトリに置き、`switch` で再現できる状態にする。

バイナリは対象外とする。

`claude` と `codex` は mise で導入済みであり、本設計はその運用を変えない。

## スコープ

管理対象は次のとおりである。

- **Claude の設定**：`settings.json`、`CLAUDE.md`、`commands/`、`agents/`、`rules/`
- **Codex の設定**：`config.toml`、`AGENTS.md`
- **skills**：`agents/skills/` 配下のローカル skill 群を Claude と Codex の両方へ配布

バイナリ（`claude` / `codex` の実行ファイル）は mise 管理のままとし、Nix では導入しない。

`output-styles/` は対象外とする。

home-manager の native モジュールにディレクトリごと指定する口が無く、現状中身も無いためである。

中身ができたときに `outputStyles` で個別に足す。

## 方式の選択

設定の生成には home-manager 本体の native モジュール（`programs.claude-code` / `programs.codex`）を使う。

両モジュールは `settings`、`context`、`commandsDir` などの型つきの設定項目を備えており、`settings.json` や `config.toml` を自前で組み立てる必要がない。

`package = null` でバイナリの導入をやめられるため、mise 版をそのまま使える。

### native を採る理由

以前は native の窮屈さとして二点を挙げていた。

ひとつは plugin の宣言が「バイナリの導入」を要求する制約である。

これは `enabledPlugins` を消す方針にしたため、そもそも発生しない。

もうひとつは `settings.json` が書き換え不可の配置になる点である。

設定をランタイムで書き換えなければ実害がない。

`enabledPlugins` を消すと、ランタイムで `settings.json` が書き換わる主な原因（プラグインの切り替え）も無くなる。

よって native の制約は今回の方針では問題にならない。

自前でファイルを生成して置く方式よりも、型つきの設定項目で素直に書ける native を採る。

### 配置はソース経由になる

native は設定の中身を Nix の保管領域に取り込み、そこから配置する。

そのため `CLAUDE.md` や `commands/` を編集しても、その場では反映されず、`switch` で反映される。

これは「ソースを編集して switch する」という本リポジトリの方針と一致する。

ソースの指定は `inputs.self`（flake のルート、git 管理下）を基点にする。

保管領域への取り込みが要るため、ランタイムの symlink 用である `dotfilesDir`（flake 外の絶対パス）は使わない。

### skills は agent-skills-nix を維持

skills の配布には外部 flake の agent-skills-nix（`programs.agent-skills`）を使う。

単一のソースから Claude と Codex の両方へ配布でき、将来の外部 skill 取り込みの余地を残せる。

native にも skills の項目はあるが、両ツールへ一括配布できる agent-skills-nix を使い、native 側では skills を指定しない。

## ソースディレクトリ構成

設定の本丸を dotfiles リポジトリ内に置く。

```
dotfiles/
├── claude/
│   ├── CLAUDE.md          # 現 ~/.claude/CLAUDE.md を移植
│   ├── commands/.gitkeep  # 枠のみ（現状は空）
│   ├── agents/.gitkeep
│   └── rules/.gitkeep
├── codex/
│   └── AGENTS.md          # Codex グローバル指示書
└── agents/
    └── skills/            # 既存。agent-skills-nix の local source
```

`commands/`、`agents/`、`rules/` は現状中身がない。

`.gitkeep` で枠だけ作り、ディレクトリごと繋ぐ。

将来これらに実体を足すと、`switch` で反映される。

`settings.json` と `config.toml` には平文のソースファイルを置かない。

これらは Nix モジュール内に設定値として定義する。

## デプロイ先

Claude の設定ディレクトリは現状の `~/.claude` を維持する。

native の `configDir` は既定で `~/.claude` を指すため、指定は不要である。

`CLAUDE_CONFIG_DIR` も設定しない。

現状この変数は未設定であり、`~/.claude` に credentials、history、projects、sessions などが既にある。

`~/.config/claude` へ移すとこれらの移行が要り、リスクに見合わない。

Codex も同様に現状の `~/.codex` を使う。

## モジュール構成

既存の慣習（`nix/modules/home/programs/<tool>.nix`）に合わせ、三つのモジュールに分ける。

### nix/modules/home/programs/claude-code.nix（新規）

```nix
{ inputs, ... }:
{
  programs.claude-code = {
    enable = true;
    package = null;

    settings = {
      env = {
        ENABLE_BACKGROUND_TASKS = "1";
        FORCE_AUTO_BACKGROUND_TASKS = "1";
        DISABLE_MICROCOMPACT = "1";
        DISABLE_INTERLEAVED_THINKING = "1";
        DISABLE_ERROR_REPORTING = "1";
        CLAUDE_CODE_NO_FLICKER = "1";
      };
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
      includeCoAuthoredBy = false;
      alwaysThinkingEnabled = true;
      autoMemoryEnabled = false;
      useAutoModeDuringPlan = true;
      effortLevel = "high";
      awaySummaryEnabled = false;
      skipAutoPermissionPrompt = true;
      skipDangerousModePermissionPrompt = true;
      skipWorkflowUsageWarning = true;
    };

    context = inputs.self + "/claude/CLAUDE.md";
    commandsDir = inputs.self + "/claude/commands";
    agentsDir = inputs.self + "/claude/agents";
    rulesDir = inputs.self + "/claude/rules";
  };
}
```

`enabledPlugins` は settings に入れない。

`hooks` も今回は入れない。

後から `settings.hooks` を足すだけで追加できる。

`$schema` は native モジュールが自動で付けるため、書かない。

`env` 群と `includeCoAuthoredBy` 以降の便利設定は ryoppippi から取り込んだ候補である。

どれを残すかは確定前に確認する。

### nix/modules/home/programs/codex.nix（新規）

```nix
{ inputs, ... }:
{
  programs.codex = {
    enable = true;
    package = null;

    settings = {
      projects."/home/mkiin/dotfiles".trust_level = "trusted";
    };

    context = inputs.self + "/codex/AGENTS.md";
  };
}
```

native の `programs.codex` は `settings` を `~/.codex/config.toml` に、`context` を `~/.codex/AGENTS.md` に配置する。

現状の `config.toml` にある `tui.model_availability_nux` は TUI のローカル状態であり、Nix では持たない。

`projects."/home/mkiin/dotfiles".trust_level` は保持する。

### nix/modules/home/agent-skills.nix（書きかけを修正）

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

`structure = "link"` は各 skill を個別の symlink で配置する。

配置先の非管理ファイルを一括削除しないため、Codex 側の `.system` などを残せる。

`filter.maxDepth = 1` は直下の skill ディレクトリだけを拾い、`references/` 内を skill として誤認しないために置く。

## flake 統合

### flake.nix

inputs に agent-skills-nix を1つ追加する。

```nix
agent-skills = {
  url = "github:Kyure-A/agent-skills-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

native モジュールは home-manager 本体に含まれるため、追加で要る input は agent-skills-nix だけである。

### nix/modules/home/default.nix

シグネチャを `{ inputs, ... }:` に変え、imports へ追加する。

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

`inputs` は `mkHome` の `extraSpecialArgs` から渡るため、`mkHome` には手を入れない。

## 移行手順

home-manager は配置先に管理外の実ファイルがあると止まる。

`switch` の前に、現在の手動ファイルを退避する。

- `~/.claude/settings.json`：内容は `claude-code.nix` の settings へ移植済み。退避する。
- `~/.claude/CLAUDE.md`：内容は `claude/CLAUDE.md` へ移植済み。退避する。
- `~/.claude/skills/`：実ディレクトリ群。agent-skills-nix の配置と衝突するため退避する。
- `~/.codex/config.toml`：内容は `codex.nix` の settings へ移植済み。退避する。
- `~/.codex/skills/`：`.system` は別名のため残るが、`superpowers` や `write-sentence` は同名で衝突しうる。衝突分を退避する。

`commands/`、`agents/`、`rules/` は現状 `~/.claude` に存在しないため、退避は不要である。

退避は削除ではなくバックアップとし、移行後に照合してから処分する。

## 検証

成功条件は次のとおりである。

- `nix build --no-link .#homeConfigurations.cachyos.activationPackage` がエラーなく完了する。
- `home-manager switch --flake .#cachyos` が成功する。
- `~/.claude/settings.json` が定義どおりの内容を持ち、`enabledPlugins` を含まない。
- `~/.claude/CLAUDE.md`、`commands`、`agents`、`rules` がソースから配置される。
- `~/.claude/skills/cm` などが skill ごとの symlink として存在する。
- `~/.codex/config.toml` が `trust_level = "trusted"` を持ち、`~/.codex/AGENTS.md` が配置される。
- `claude` と `codex` の実行ファイルが従来どおり mise 版を指す。

## 決定事項

### enabledPlugins は完全に消す

現 `settings.json` の `enabledPlugins` にある `rust-analyzer-lsp`、`superpowers`、`lua-lsp` の3つをすべて消す。

これらのプラグインは無効になる。

`superpowers` の無効化により、brainstorming や writing-plans などの skill は次回以降使えなくなる。

この影響を承知のうえで消す。

### settings の便利設定はすべて取り込む

`env` 群（`DISABLE_INTERLEAVED_THINKING` など）と `includeCoAuthoredBy` 以降の設定を、design doc に書いたとおりすべて取り込む。

`statusLine`（ccusage 連携）は ryoppippi 固有のパスに依存するため取り込まない。

## やらないこと

- バイナリの Nix 管理。
- MCP サーバーの Nix 管理。
- output-styles の管理（中身ができたときに `outputStyles` で足す）。
- Codex の TUI ローカル状態の Nix 管理。
