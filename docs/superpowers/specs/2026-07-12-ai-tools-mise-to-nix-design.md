# AI ツール（claude-code / codex / serena）を mise → Nix 管理へ移管

作成日: 2026-07-12

## 背景と目的

現在、AI 系 CLI/MCP は mise で管理している。

- `home-manager/cli/mise/config.toml`
  - `claude-code = "latest"`
  - `"pipx:serena-agent" = "latest"`
  - `"aqua:openai/codex" = "latest"`

一方 `programs.claude-code` / `programs.codex` は既に home-manager モジュールで
設定管理されており、`package = null;`（本体は mise 供給、nix は設定のみ）という
中途半端な二重管理になっている。serena は nix 側に設定が一切なく mise の pipx 依存。

これらを Nix（flake）へ寄せ、宣言的・再現可能な単一管理にする。mise は言語
ランタイム管理としては存続させる。

## 調査で確定した事実

- **供給源**: `numtide/llm-agents.nix` が `claude-code` と `codex` を**単一 input**で
  overlay 提供。日次自動更新、`cache.numtide.com` バイナリキャッシュあり。
- **serena**: `natsukium/mcp-servers-nix`（既に flake input 済み・未使用）が serena を
  **第一級サポート**（`mcp-servers.programs.serena`）。home-manager モジュール
  `homeManagerModules.default` を持ち、`programs.claude-code` / `programs.codex` へ
  `enableMcpIntegration = true;` で MCP 設定を自動配線できる。serena 本体パッケージは
  mcp-servers-nix の derivation に内包（nixpkgs には serena パッケージ無し）。
- **unfree**: claude は unfree だが `lib/default.nix` の `mkPkgs` で
  `config.allowUnfree = true;` が全体適用済みのため追加対応不要。

## トレードオフ（承知の上で採用）

- claude-code が「起動ごとに最新」→ **日次更新（llm-agents CI）＋ `flake.lock` 追従**に
  変わる。反映は `git pull && nix run .#switch`。緊急時は `nix run .#update` で
  特定 input を強制更新できる。
- nixpkgs 直（数パッチ〜2マイナー遅れ）や claude-code 専用 flake（毎時）ではなく、
  「claude-code と codex を1 input で日次」を選択。input 増を最小化しつつ十分に新鮮。

## 設計

### 1. パッケージ供給を llm-agents.nix overlay に一本化

- **`flake.nix` inputs 追加**
  - `llm-agents.url = "github:numtide/llm-agents.nix";`
  - `llm-agents.inputs.nixpkgs.follows = "nixpkgs";`
- **`flake.nix` nixConfig**: `extra-substituters` に `https://cache.numtide.com`、
  `extra-trusted-public-keys` に numtide の公開鍵を追加（ソースビルド回避）。
  ※ 鍵の正確値は実装時に一次情報で裏取りする（暫定:
  `niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=`）。
- **`lib/default.nix` の `defaultOverlays`** に
  `inputs.llm-agents.overlays.shared-nixpkgs` を追加（ピン留め nixpkgs を共有し
  二重 eval を避ける。overlay 名は実装時に確認）。
- **`home-manager/ai/claude-code/default.nix`**: `package = null;` →
  `package = pkgs.claude-code;`（`pkgs` を module 引数に追加）。
- **`home-manager/ai/codex/default.nix`**: `package = null;` →
  `package = pkgs.codex;`（同上）。

### 2. serena を mcp-servers-nix の home-manager モジュールで宣言

- **`homeManagerModules.default` を home-manager に import**（配線経路は実装時に確定。
  `home-manager/ai/serena/default.nix` から import するか、host のモジュール組み立て側で
  import するかは既存パターンに合わせる）。
- **新規 `home-manager/ai/serena/default.nix`**（1 機能 = 1 ディレクトリ）
  - `mcp-servers.programs.serena.enable = true;`
  - `programs.mcp.enable = true;`
  - serena 本体は mcp-servers-nix 内包のため `home.packages` 直書きにならず、集約
    `packages.nix` も不要。
- **`home-manager/ai/claude-code/default.nix` と `home-manager/ai/codex/default.nix`** に
  `enableMcpIntegration = true;` を追加 → 両クライアントの MCP 設定へ serena を配線。
- **`home-manager/ai/default.nix`** の `imports` に `./serena` を追加。

### 3. mise から AI ツールを剥がす

- **`home-manager/cli/mise/config.toml`** から次の 3 行を削除:
  - `claude-code = "latest"`
  - `"pipx:serena-agent" = "latest"`
  - `"aqua:openai/codex" = "latest"`
- `[settings]` と言語ランタイム群（go/bun/rust/uv/deno/node/supabase）は存続。

## 規約整合の確認

- `programs.*.package =` は CLAUDE.md が明示する「設定機構」であり、パッケージ直書き
  禁止に**非該当**。バージョン供給源の単一管理は `defaultOverlays`（`lib/default.nix`）に
  集約されるため、機能ディレクトリは設定に徹する原則を保つ。
- serena 本体は mcp-servers-nix derivation 内包 → 集約 `packages.nix` ルール**非抵触**。
- `../..` 遡り相対参照なし・1 機能 1 ディレクトリを維持。

## 検証（実装フェーズで実施）

- `nix eval` で llm-agents.nix の実 attribute 名（`claude-code` / `codex`）、
  `overlays.shared-nixpkgs` の存在、numtide 公開鍵を裏取り。
- `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。
- `nix run .#switch` 後、`claude --version` / `codex --version` が nix store 由来を指すこと、
  claude-code / codex 双方で serena が MCP として認識されることを確認。

## 想定リスク

- llm-agents.nix の attribute 名や overlay 名が想定と違う場合 → 実装時の `nix eval` で
  即判明。ズレたら overlay 配線を修正。
- `enableMcpIntegration` が既存 `programs.claude-code.settings`（read-only symlink 制約で
  effort をここに書いている等）と競合しないか要確認。競合時は mcp 設定の出力先を分離。
- numtide cache が引けない場合はソースビルドにフォールバック（claude-code/codex は
  prebuilt バイナリ主体のためビルドコストは限定的）。
