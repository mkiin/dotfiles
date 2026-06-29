# GitHub Actions CI / 自動更新 設計

## 背景と目的

mkiin の dotfiles リポジトリには現在 `.github/` が存在せず、CI も自動更新も無い。
`ghq/github.com/ryoppippi/dotfiles` の GitHub Actions 構成を参考に、以下を導入する。

- **CI**: PR / push で flake の健全性とビルドを保証する。
- **並列化**: 構成ビルドと flake input 更新を matrix で並列実行する。
- **自動マージ**: flake input 更新 PR と Actions pin 更新 PR を、CI 通過後に自動マージ
  する（手動マージの手間をなくす）。

参考実装は ryoppippi の構成。ただし mkiin の環境（x86_64-linux のみ・2 構成・neovim
は lnk 管理で nix 外・node/overlays なし）に合わせて取捨選択・簡略化する。

## 現状

- `flake.nix` は標準 flake（flake-parts 未使用）。出力は以下。
  - `nixosConfigurations.nixos`（x86_64-linux）
  - `homeConfigurations."mkiin@wsl"`（x86_64-linux）
  - `formatter.x86_64-linux` / `packages.x86_64-linux.fmt`（treefmt ラッパー、導入済み）
- flake inputs は 19 個（nixpkgs, nixpkgs-stable, home-manager, nixos-hardware,
  hyprland, zen-browser, firefox-addons, treefmt-nix, git-hooks, nix-index-database,
  agenix, disko, mcp-servers-nix, xremap, agent-skills, superpowers-skill,
  cloudflare-skills, anthropic-skills）。
- `.github/` ディレクトリは存在しない。

## 方針の決定事項

- **導入範囲**: CI（ビルド並列 / lint・fmt / nix-diff）＋ Bot（flake 自動更新・並列 PR）
  ＋ auto-rebase ＋ Dependabot（Actions pin 更新）。
- **Bot 認証**: GitHub App。各 PR で CI が発火し auto-merge が機能する。
- **更新頻度**: 単一・日次。frequent/stable 分離や reusable workflow 分離はしない。
- **Actions pin 更新**: Renovate ではなく Dependabot（純正・App 不要）を採用。flake は
  Dependabot 管轄外（自作 workflow が担当）。
- **簡略化**: ryoppippi の `update-flake-input` にある `llm-agents` / `nix-bun` 専用の
  パッケージ版数差分ロジックは削除し、rev 追跡のみとする。arm / darwin / neovim /
  node-packages / overlays は対象外。

## ファイル構成

```
.github/
├── dependabot.yml                         # Dependabot: github-actions ecosystem
├── actions/
│   ├── setup-nix/action.yaml              # Nix インストール + バイナリキャッシュ
│   ├── setup-git-bot/action.yml           # GitHub App トークン発行 + git identity
│   ├── discover-flake-inputs/action.yaml  # inputs 列挙 → matrix JSON 生成
│   └── update-flake-input/action.yaml     # 1 input 更新 + PR 作成 + auto-merge 有効化
└── workflows/
    ├── nix-build.yaml                      # CI: 2 構成を並列ビルド（matrix）
    ├── lint.yaml                           # CI: flake check + fmt --fail-on-change
    ├── nix-diff.yaml                       # CI: PR に差分コメント
    ├── update-flake.yaml                   # Bot: 日次・discover→matrix 並列更新
    ├── auto-rebase.yaml                    # Bot: マージ後に残り PR を自動 rebase
    └── dependabot-automerge.yaml           # Dependabot PR の auto-merge 有効化
```

## コンポーネント設計

### 1. `actions/setup-nix`（composite）

全 CI / Bot が共有する Nix セットアップ。

- `nixbuild/nix-quick-install-action` で Nix をインストール（`nix_conf` に
  `accept-flake-config = true`）。
- `nix-community/cache-nix-action` で Nix store をキャッシュ。
  - `primary-key: nix-${runner.os}-${runner.arch}-${hashFiles('flake.lock')}`
  - `restore-prefixes-first-match: nix-${runner.os}-${runner.arch}-`

**何をするか**: Nix を入れ、`flake.lock` ハッシュ単位で store をキャッシュする。
**依存**: なし。**利用側**: 全 workflow。

### 2. `workflows/nix-build.yaml`（CI: 並列ビルド）

- トリガー: `push: { branches: [main] }` / `pull_request` / `workflow_dispatch`。
- `concurrency: { group: ${github.workflow}-${github.ref}, cancel-in-progress: true }`。
- `changes` ジョブ: `dorny/paths-filter` で Nix 関連変更を検出し `nix` 出力を返す。
  - フィルタ対象: `flake.nix`, `flake.lock`, `hosts/**`, `lib/**`, `nixos/**`,
    `home-manager/**`, `packages/**`, `.github/workflows/nix-build.yaml`,
    `.github/actions/setup-nix/**`。
- `build` ジョブ: `needs: changes`、`strategy.matrix` で 2 構成を並列ビルド。
  各ステップは `needs.changes.outputs.nix == 'true' || github.event_name == 'workflow_dispatch'`
  のときのみ実行（それ以外はスキップメッセージ）。
  - matrix.include:
    - `{ name: nixos, attr: '.#nixosConfigurations.nixos.config.system.build.toplevel' }`
    - `{ name: wsl-home, attr: '.#homeConfigurations."mkiin@wsl".activationPackage' }`
  - ビルドコマンド: `nix build '${{ matrix.attr }}' --print-build-logs --show-trace`
    （`@` を含むためシングルクォートで囲う）。
  - `timeout-minutes: 30`。

**並列化のポイント**: nixos と wsl-home が独立ジョブとして同時に走る。

### 3. `workflows/lint.yaml`（CI: lint / fmt）

- トリガー: `push` / `pull_request`。`concurrency` で古い実行をキャンセル。
- `setup-nix` 後:
  - `nix flake check --show-trace`
  - `nix run .#fmt -- --fail-on-change`（treefmt で未整形があれば失敗）

### 4. `workflows/nix-diff.yaml`（CI: 差分コメント）

- トリガー: `pull_request`（paths: `flake.lock`, `flake.nix`, `hosts/**`, `lib/**`,
  `nixos/**`, `home-manager/**`, `packages/**`）。
- `permissions: { contents: read, pull-requests: write }`。
- `actions/checkout`（`fetch-depth: 0`）→ `setup-nix` → `natsukium/nix-diff-action`。
  - `skip-no-change: true`
  - attributes:
    - `home-manager (wsl)`: `homeConfigurations."mkiin@wsl".activationPackage`
    - `nixos`: `nixosConfigurations.nixos.config.system.build.toplevel`

### 5. `actions/setup-git-bot`（composite）

- `actions/create-github-app-token` で App トークンを発行（`app-id` / `private-key`
  を入力に取る）。
- `git config user.name "${APP_SLUG}[bot]"` / `user.email` を bot identity に設定。
- 出力 `token` を後続ステップ / checkout に渡す。

### 6. `actions/discover-flake-inputs`（composite）

- `nix flake metadata --json --no-write-lock-file` で直接 inputs を列挙。
- 各 input の `name` / `current_version`(rev 先頭 8 文字) / `owner` / `repo` / `ref`
  を集め、`{ "include": [...] }` 形式の matrix JSON を `matrix` 出力に、更新候補有無を
  `has-updates` 出力に書く。
- `exclude-inputs` で除外可能（既定は空 = 全 input）。
- ryoppippi 版から `skip-delay-inputs` の分岐は残すが、mkiin では未使用（既定空）。

### 7. `actions/update-flake-input`（composite、簡略版）

1 input を更新し、変化があれば PR を作成して auto-merge を有効化する。

- `minimum-release-age-days`（既定 3）: GitHub API で「N 日以上前のコミット」を
  ターゲット rev として取得し `nix flake update <input> --override-input ...` で更新。
  取得失敗時は `nix flake update <input>`（最新）にフォールバックし、`lastModified` で
  リリース齢を検証して新しすぎる場合は更新を取り消す。
- ダウングレード検出（ターゲット rev が現在より古ければスキップ）。
- 変化が無ければ `updated=false` で終了。
- 変化があれば:
  - `update-flake-<input>` ブランチに commit（`chore(nix): update flake input <input> to <rev>`）。
  - `git push --force` し、既存 PR があれば `gh pr edit`、無ければ `gh pr create`
    （`--base main`、ラベル `dependencies,automated`）。
  - `auto-merge: true`（既定）なら `gh pr merge <n> --auto --squash`。
- **削除する点**: ryoppippi 版の `llm-agents` / `nix-bun` 専用パッケージ版数取得・
  差分テーブル生成は mkiin に該当 input が無いため全削除。PR 本文は rev 差分のみ。

### 8. `workflows/update-flake.yaml`（Bot: 並列更新）

- トリガー: `schedule: { cron: '0 6 * * *' }`（日次 06:00 UTC）+ `workflow_dispatch`
  （任意で `inputs` / `minimum-release-age-days` / `skip-delay` を指定可能）。
- `discover` ジョブ: `setup-nix` → `discover-flake-inputs` → `matrix` / `has-updates` 出力。
- `update` ジョブ: `needs: discover`、`if: needs.discover.outputs.has-updates == 'true'`、
  `strategy: { fail-fast: false, matrix: ${{ fromJson(needs.discover.outputs.matrix) }} }`。
  - `permissions: { contents: write, pull-requests: write }`。
  - checkout（local actions 用）→ `setup-git-bot` → bot token で再 checkout →
    `setup-nix` → `update-flake-input`（matrix の各 input を渡す）。
- `summary` ジョブ: `needs: [discover, update]`, `if: always() && has-updates`。
  `GITHUB_STEP_SUMMARY` に設定と結果（成功 / 一部失敗）を出力。

**並列化のポイント**: input ごとに `update` ジョブが並列で立ち、各々が独立 PR を作る。

### 9. `workflows/auto-rebase.yaml`（Bot: 自動 rebase）

- トリガー: `push: { branches: [main] }` + `workflow_dispatch`。
- `concurrency: { group: auto-rebase, cancel-in-progress: false }`。
- `if`: `workflow_dispatch` または「head_commit の committer が bot（マージコミット）」。
- `setup-git-bot` で bot token を得て `fetch-depth: 0` で checkout。
- `gh pr list` で `update-flake-` 始まりの開き PR を列挙し、`origin/main` より遅れて
  いるものを `git rebase origin/main` → `git push --force`。コンフリクト時は
  `git rebase --abort` でスキップ。

**役割**: ある PR がマージされて他 PR の `flake.lock` が衝突した際に自動追従させ、
auto-merge の連鎖を止めない。

### 10. `.github/dependabot.yml` + `workflows/dependabot-automerge.yaml`

- `dependabot.yml`: `version: 2`、`updates` に 1 件。
  - `package-ecosystem: "github-actions"`、`directory: "/"`、`schedule: { interval: "weekly" }`、
    `labels: ["dependencies", "github-actions"]`。
- `dependabot-automerge.yaml`: `pull_request` トリガー、`if: github.actor == 'dependabot[bot]'`。
  - `permissions: { contents: write, pull-requests: write }`。
  - `gh pr merge --auto --squash "$PR_URL"`（CI 通過後に自動マージ）。
  - token は `GITHUB_TOKEN` でよい（Dependabot PR は CI が走るため auto-merge が成立）。

## 動作フロー

**CI（PR 時）**: lint（flake check + fmt）、nix-build（2 構成並列、Nix 変更時のみ）、
nix-diff（差分コメント）が走る。

**flake 自動更新（日次）**: discover が inputs を matrix 化 → input ごとに並列ジョブが
更新を試行し、変化があれば PR を作成して auto-merge 有効化 → CI 通過後に自動マージ →
push をトリガーに auto-rebase が残り PR を追従。

**Actions pin 更新（週次）**: Dependabot が `.github` 内の Actions pin 更新 PR を作成 →
dependabot-automerge が auto-merge を有効化 → CI 通過後に自動マージ。

## 導入後に必要な手動設定（コード化不可の外部設定）

1. **GitHub App 作成**: flake 更新 bot 用。権限 `contents:write` / `pull-requests:write`。
   対象リポジトリに install し、`NIX_UPDATER_APP_ID`（App ID）と
   `NIX_UPDATER_APP_PRIVATE_KEY`（秘密鍵）をリポジトリ Secrets に登録する。
2. **branch protection（main）**: 必須ステータスチェックに `lint` と
   `build (nixos)` / `build (wsl-home)` を指定。「Require branches to be up to date
   before merging」を ON。
3. **Allow auto-merge**: リポジトリ設定で auto-merge を有効化する。
4. Dependabot は install 不要（GitHub 純正）。

## 想定される影響と留意点

- auto-merge は branch protection の必須チェックが設定されて初めて機能する（上記手動
  設定が前提）。
- `homeConfigurations."mkiin@wsl"` は属性名に `@` を含むため、`nix build` / nix-diff の
  attribute 指定でクォートに注意する。
- 初回 CI はキャッシュが無いためビルドに時間がかかる（以降は cache-nix-action で短縮）。
- flake 更新 PR は input 数だけ並列で立つため、初回は PR 数が多くなりうる。
  `minimum-release-age-days: 3` で新しすぎる更新は抑制される。
- nixos 構成は x86_64-linux のため Linux runner 上でビルド / diff 可能。

```

```
