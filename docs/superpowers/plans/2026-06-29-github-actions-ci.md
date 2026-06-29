# GitHub Actions CI / 自動更新 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ryoppippi の GitHub Actions 構成を mkiin の dotfiles に移植し、CI（並列ビルド・lint・差分）と flake 自動更新（並列 PR + auto-merge）、Dependabot による Actions pin 更新を導入する。

**Architecture:** `.github/actions/` に composite action（Nix セットアップ・bot トークン・input 探索・input 更新）を置き、`.github/workflows/` の各 workflow から呼ぶ。CI はビルドを matrix で並列化し、自動更新は `discover → matrix → 並列 update` の三段で input ごとに独立 PR を作って auto-merge する。

**Tech Stack:** GitHub Actions (composite actions, reusable steps), Nix flakes, `nixbuild/nix-quick-install-action`, `nix-community/cache-nix-action`, `dorny/paths-filter`, `natsukium/nix-diff-action`, `actions/create-github-app-token`, Dependabot, treefmt (`nix run .#fmt`)。

## Global Constraints

- 対象 system は **x86_64-linux のみ**。arm / darwin ジョブは作らない。
- 全ジョブの `runs-on` は **`ubuntu-latest`**。
- third-party action は **commit SHA で pin**し、`# vX` コメントを付ける。本プランで使う pin（ryoppippi と同一の既知良好版）:
  - `actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7`
  - `dorny/paths-filter@fbd0ab8f3e69293af611ebaee6363fc25e6d187d # v4.0.1`
  - `nixbuild/nix-quick-install-action@9f63be77f412a248c9d9a65a4c82cf066cdf8f0c # v35`
  - `nix-community/cache-nix-action@7df957e333c1e5da7721f60227dbba6d06080569 # v7.0.2`
  - `natsukium/nix-diff-action@4091452e4c7b3c7ea4ecbaec84be7f0066d810d7 # main`
  - `actions/create-github-app-token@bcd2ba49218906704ab6c1aa796996da409d3eb1 # v3.2.0`
- ビルドターゲットの属性パス（検証済み）:
  - nixos: `.#nixosConfigurations.nixos.config.system.build.toplevel`
  - wsl-home: `.#homeConfigurations."mkiin@wsl".activationPackage`
- `homeConfigurations."mkiin@wsl"` は属性名に `@` を含むため、shell に渡す際は**シングルクォートで囲い、内側の二重引用符を保持**する（例: `nix build '.#homeConfigurations."mkiin@wsl".activationPackage'`）。
- flake 更新 bot の Secrets 名: `NIX_UPDATER_APP_ID` / `NIX_UPDATER_APP_PRIVATE_KEY`。
- ryoppippi 版にある `llm-agents` / `nix-bun` 専用のパッケージ版数差分ロジックは**移植しない**（mkiin に該当 input なし）。
- 検証ツール: workflow は `nix run nixpkgs#actionlint -- <file>`、composite action / dependabot.yml は `nix run nixpkgs#yq-go -- '.' <file> > /dev/null`。

---

## File Structure

作成するファイル:

- `.github/actions/setup-nix/action.yaml` — Nix インストール + store キャッシュ（composite）
- `.github/actions/setup-git-bot/action.yml` — GitHub App トークン発行 + git identity（composite）
- `.github/actions/discover-flake-inputs/action.yaml` — inputs を matrix JSON 化（composite）
- `.github/actions/update-flake-input/action.yaml` — 1 input 更新 + PR + auto-merge（composite）
- `.github/workflows/lint.yaml` — flake check + fmt
- `.github/workflows/nix-build.yaml` — 2 構成を matrix 並列ビルド
- `.github/workflows/nix-diff.yaml` — PR 差分コメント
- `.github/workflows/update-flake.yaml` — 日次・並列 flake 更新
- `.github/workflows/auto-rebase.yaml` — マージ後の残り PR を自動 rebase
- `.github/dependabot.yml` — Actions pin の週次更新
- `.github/workflows/dependabot-automerge.yaml` — Dependabot PR の auto-merge
- `docs/github-actions-setup.md` — 手動設定手順（GitHub App / branch protection）

タスク順は依存順（composite を先、それを使う workflow を後）。

---

### Task 1: setup-nix composite action

**Files:**

- Create: `.github/actions/setup-nix/action.yaml`

**Interfaces:**

- Consumes: なし。
- Produces: ローカル action `./.github/actions/setup-nix`（入力なし）。以降の全 workflow が `uses: ./.github/actions/setup-nix` で利用し、`nix` コマンドが使える状態と store キャッシュを提供する。

- [ ] **Step 1: action ファイルを作成する**

`.github/actions/setup-nix/action.yaml`:

```yaml
name: "Setup Nix"
description: "Install Nix with binary cache configured"
runs:
  using: "composite"
  steps:
    - name: Install Nix
      uses: nixbuild/nix-quick-install-action@9f63be77f412a248c9d9a65a4c82cf066cdf8f0c # v35
      with:
        nix_conf: |
          accept-flake-config = true

    - name: Cache Nix store
      uses: nix-community/cache-nix-action@7df957e333c1e5da7721f60227dbba6d06080569 # v7.0.2
      with:
        primary-key: nix-${{ runner.os }}-${{ runner.arch }}-${{ hashFiles('flake.lock') }}
        restore-prefixes-first-match: nix-${{ runner.os }}-${{ runner.arch }}-
```

- [ ] **Step 2: YAML が妥当か確認する**

Run: `nix run nixpkgs#yq-go -- '.' .github/actions/setup-nix/action.yaml > /dev/null && echo OK`
Expected: `OK`（パースエラーなし）

- [ ] **Step 3: コミット**

```bash
git add .github/actions/setup-nix/action.yaml
git commit -m "ci: add setup-nix composite action"
```

---

### Task 2: lint workflow

**Files:**

- Create: `.github/workflows/lint.yaml`

**Interfaces:**

- Consumes: `./.github/actions/setup-nix`（Task 1）、flake 出力 `packages.x86_64-linux.fmt`（既存）。
- Produces: `lint` ジョブ（branch protection の必須チェック候補）。

- [ ] **Step 1: workflow を作成する**

`.github/workflows/lint.yaml`:

```yaml
name: "CI: Lint"

on:
  push:
  pull_request:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - name: Checkout repository
        uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7

      - uses: ./.github/actions/setup-nix

      - name: Check flake
        run: nix flake check --show-trace

      - name: Check formatting
        run: nix run .#fmt -- --fail-on-change
```

- [ ] **Step 2: actionlint で検証する**

Run: `nix run nixpkgs#actionlint -- .github/workflows/lint.yaml`
Expected: 出力なし・終了コード 0（エラーなし。ローカル action 参照 `setup-nix` が解決できること）

- [ ] **Step 3: コミット**

```bash
git add .github/workflows/lint.yaml
git commit -m "ci: add lint workflow (flake check + fmt)"
```

---

### Task 3: nix-build workflow（並列ビルド）

**Files:**

- Create: `.github/workflows/nix-build.yaml`

**Interfaces:**

- Consumes: `./.github/actions/setup-nix`（Task 1）、`dorny/paths-filter`、ビルド属性 2 種。
- Produces: `changes` ジョブ（出力 `nix`）と `build` ジョブ（matrix: `nixos` / `wsl-home`）。`build (nixos)` / `build (wsl-home)` が branch protection の必須チェック候補。

- [ ] **Step 1: workflow を作成する**

`.github/workflows/nix-build.yaml`:

```yaml
name: "CI: Nix build"

on:
  push:
    branches:
      - main
  pull_request:
  workflow_dispatch:

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  changes:
    runs-on: ubuntu-latest
    outputs:
      nix: ${{ steps.filter.outputs.nix }}
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7
      - uses: dorny/paths-filter@fbd0ab8f3e69293af611ebaee6363fc25e6d187d # v4.0.1
        id: filter
        with:
          filters: |
            nix:
              - 'flake.nix'
              - 'flake.lock'
              - 'hosts/**'
              - 'lib/**'
              - 'nixos/**'
              - 'home-manager/**'
              - 'packages/**'
              - '.github/workflows/nix-build.yaml'
              - '.github/actions/setup-nix/**'

  build:
    needs: changes
    runs-on: ubuntu-latest
    timeout-minutes: 30
    strategy:
      fail-fast: false
      matrix:
        include:
          - name: nixos
            attr: ".#nixosConfigurations.nixos.config.system.build.toplevel"
          - name: wsl-home
            attr: '.#homeConfigurations."mkiin@wsl".activationPackage'
    steps:
      - name: Skip if no Nix changes
        if: needs.changes.outputs.nix != 'true' && github.event_name != 'workflow_dispatch'
        run: echo "No Nix-related changes detected, skipping build"

      - name: Checkout repository
        if: needs.changes.outputs.nix == 'true' || github.event_name == 'workflow_dispatch'
        uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7

      - name: Setup Nix
        if: needs.changes.outputs.nix == 'true' || github.event_name == 'workflow_dispatch'
        uses: ./.github/actions/setup-nix

      - name: Build ${{ matrix.name }} configuration
        if: needs.changes.outputs.nix == 'true' || github.event_name == 'workflow_dispatch'
        run: |
          nix build '${{ matrix.attr }}' \
            --print-build-logs \
            --show-trace
```

- [ ] **Step 2: actionlint で検証する**

Run: `nix run nixpkgs#actionlint -- .github/workflows/nix-build.yaml`
Expected: 出力なし・終了コード 0

- [ ] **Step 3: matrix の属性パスが実際に評価できることを確認する**

Run:

```bash
nix eval --raw '.#nixosConfigurations.nixos.config.system.build.toplevel.drvPath' >/dev/null && \
nix eval --raw '.#homeConfigurations."mkiin@wsl".activationPackage.drvPath' >/dev/null && echo OK
```

Expected: `OK`（両属性が評価エラーなく解決する）

- [ ] **Step 4: コミット**

```bash
git add .github/workflows/nix-build.yaml
git commit -m "ci: add nix-build workflow with parallel matrix build"
```

---

### Task 4: nix-diff workflow

**Files:**

- Create: `.github/workflows/nix-diff.yaml`

**Interfaces:**

- Consumes: `./.github/actions/setup-nix`（Task 1）、`natsukium/nix-diff-action`。
- Produces: `nix-diff` ジョブ（PR にビルド差分をコメント）。

- [ ] **Step 1: workflow を作成する**

`.github/workflows/nix-diff.yaml`:

```yaml
name: "CI: Nix diff"

on:
  pull_request:
    paths:
      - "flake.lock"
      - "flake.nix"
      - "hosts/**"
      - "lib/**"
      - "nixos/**"
      - "home-manager/**"
      - "packages/**"

permissions:
  contents: read
  pull-requests: write

jobs:
  nix-diff:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7
        with:
          fetch-depth: 0

      - name: Setup Nix
        uses: ./.github/actions/setup-nix

      - name: Run nix-diff
        uses: natsukium/nix-diff-action@4091452e4c7b3c7ea4ecbaec84be7f0066d810d7 # main
        with:
          skip-no-change: true
          attributes: |
            - displayName: home-manager (wsl)
              attribute: homeConfigurations."mkiin@wsl".activationPackage
            - displayName: nixos
              attribute: nixosConfigurations.nixos.config.system.build.toplevel
```

- [ ] **Step 2: actionlint で検証する**

Run: `nix run nixpkgs#actionlint -- .github/workflows/nix-diff.yaml`
Expected: 出力なし・終了コード 0

- [ ] **Step 3: コミット**

```bash
git add .github/workflows/nix-diff.yaml
git commit -m "ci: add nix-diff workflow for PR diff comments"
```

---

### Task 5: setup-git-bot composite action

**Files:**

- Create: `.github/actions/setup-git-bot/action.yml`

**Interfaces:**

- Consumes: `actions/create-github-app-token`、Secrets `app-id` / `private-key`。
- Produces: ローカル action `./.github/actions/setup-git-bot`。入力 `app-id`, `private-key`。出力 `token`（GitHub App トークン）。git の `user.name` / `user.email` を bot identity に設定する。

- [ ] **Step 1: action ファイルを作成する**

`.github/actions/setup-git-bot/action.yml`:

```yaml
name: "Setup Git Bot"
description: "Configure git with bot identity for automated commits"

inputs:
  app-id:
    description: "GitHub App ID"
    required: true
  private-key:
    description: "GitHub App private key"
    required: true

outputs:
  token:
    description: "GitHub App token for subsequent steps"
    value: ${{ steps.app-token.outputs.token }}

runs:
  using: "composite"
  steps:
    - name: Generate GitHub App Token
      id: app-token
      uses: actions/create-github-app-token@bcd2ba49218906704ab6c1aa796996da409d3eb1 # v3.2.0
      with:
        app-id: ${{ inputs.app-id }}
        private-key: ${{ inputs.private-key }}

    - name: Configure git bot identity
      shell: bash
      env:
        GH_TOKEN: ${{ steps.app-token.outputs.token }}
        APP_SLUG: ${{ steps.app-token.outputs.app-slug }}
      run: |
        bot_id=$(gh api "users/${APP_SLUG}[bot]" --jq '.id')
        git config user.name "${APP_SLUG}[bot]"
        git config user.email "${bot_id}+${APP_SLUG}[bot]@users.noreply.github.com"
```

- [ ] **Step 2: YAML が妥当か確認する**

Run: `nix run nixpkgs#yq-go -- '.' .github/actions/setup-git-bot/action.yml > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: コミット**

```bash
git add .github/actions/setup-git-bot/action.yml
git commit -m "ci: add setup-git-bot composite action"
```

---

### Task 6: discover-flake-inputs composite action

**Files:**

- Create: `.github/actions/discover-flake-inputs/action.yaml`

**Interfaces:**

- Consumes: `nix flake metadata`、`jq`（runner 標準搭載）。
- Produces: ローカル action `./.github/actions/discover-flake-inputs`。入力 `inputs`, `exclude-inputs`, `skip-delay-inputs`。出力 `matrix`（`{"include":[{name,current_version,skip_delay,owner,repo,ref},...]}` 形式の JSON）、`has-updates`（`true`/`false`）。

- [ ] **Step 1: action ファイルを作成する**

`.github/actions/discover-flake-inputs/action.yaml`:

```yaml
name: "Discover Flake Inputs"
description: "Discover Nix flake inputs and create a matrix for parallel updates"

inputs:
  inputs:
    description: "Space-separated list of specific inputs to update (empty for all)"
    required: false
    default: ""
  exclude-inputs:
    description: "Space-separated list of inputs to exclude from discovery"
    required: false
    default: ""
  skip-delay-inputs:
    description: "Space-separated list of inputs that should skip the release age check"
    required: false
    default: ""

outputs:
  matrix:
    description: "JSON matrix for GitHub Actions strategy"
    value: ${{ steps.discover.outputs.matrix }}
  has-updates:
    description: "Whether there are inputs to update"
    value: ${{ steps.discover.outputs.has-updates }}

runs:
  using: "composite"
  steps:
    - name: Discover flake inputs
      id: discover
      shell: bash
      env:
        INPUTS: ${{ inputs.inputs }}
        EXCLUDE_INPUTS: ${{ inputs.exclude-inputs }}
        SKIP_DELAY_INPUTS: ${{ inputs.skip-delay-inputs }}
      run: |
        set -euo pipefail

        IFS=' ' read -ra exclude_array <<< "${EXCLUDE_INPUTS:-}"
        IFS=' ' read -ra skip_delay_array <<< "${SKIP_DELAY_INPUTS:-}"

        should_exclude() {
          local input="$1"
          for e in "${exclude_array[@]}"; do
            [ "$input" = "$e" ] && return 0
          done
          return 1
        }

        should_skip_delay() {
          local input="$1"
          for s in "${skip_delay_array[@]}"; do
            [ "$input" = "$s" ] && return 0
          done
          return 1
        }

        declare -a matrix_items=()

        if [ ! -f "flake.lock" ]; then
          echo "No flake.lock found"
          echo 'matrix={"include":[]}' >> "$GITHUB_OUTPUT"
          echo "has-updates=false" >> "$GITHUB_OUTPUT"
          exit 0
        fi

        if ! metadata=$(nix flake metadata --json --no-write-lock-file 2>/dev/null); then
          echo "Failed to get flake metadata"
          exit 1
        fi

        if [ -n "$INPUTS" ]; then
          requested_inputs="$INPUTS"
        else
          requested_inputs=$(echo "$metadata" | jq -r '.locks.nodes.root.inputs | keys[]' | sort)
        fi

        for input in $requested_inputs; do
          if [ ${#exclude_array[@]} -gt 0 ] && should_exclude "$input"; then
            echo "  - $input (excluded)"
            continue
          fi

          if ! echo "$metadata" | jq -e ".locks.nodes.\"$input\"" >/dev/null 2>&1; then
            echo "Warning: Input $input not found, skipping"
            continue
          fi

          current_rev=$(echo "$metadata" | jq -r ".locks.nodes.\"$input\".locked.rev // \"unknown\"" | head -c 8)
          owner=$(echo "$metadata" | jq -r ".locks.nodes.\"$input\".original.owner // \"unknown\"")
          repo=$(echo "$metadata" | jq -r ".locks.nodes.\"$input\".original.repo // \"unknown\"")
          ref=$(echo "$metadata" | jq -r ".locks.nodes.\"$input\".original.ref // \"\"")

          if should_skip_delay "$input"; then
            skip_delay="true"
          else
            skip_delay="false"
          fi

          matrix_items+=("{\"name\":\"$input\",\"current_version\":\"$current_rev\",\"skip_delay\":$skip_delay,\"owner\":\"$owner\",\"repo\":\"$repo\",\"ref\":\"$ref\"}")
          echo "  - $input ($current_rev) [skip_delay=$skip_delay, ref=$ref]"
        done

        if [ ${#matrix_items[@]} -eq 0 ]; then
          matrix='{"include":[]}'
          has_updates="false"
          echo "No items to update"
        else
          matrix_json='{"include":['
          for i in "${!matrix_items[@]}"; do
            [ "$i" -gt 0 ] && matrix_json+=","
            matrix_json+="${matrix_items[$i]}"
          done
          matrix_json+="]}"
          matrix="$matrix_json"
          has_updates="true"
          echo "Found ${#matrix_items[@]} input(s) to check"
        fi

        echo "matrix=$matrix" >> "$GITHUB_OUTPUT"
        echo "has-updates=$has_updates" >> "$GITHUB_OUTPUT"
```

- [ ] **Step 2: YAML が妥当か確認する**

Run: `nix run nixpkgs#yq-go -- '.' .github/actions/discover-flake-inputs/action.yaml > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: 探索ロジックがローカルの flake で動くことを確認する**

Run:

```bash
nix flake metadata --json --no-write-lock-file | jq -r '.locks.nodes.root.inputs | keys[]' | sort | head
```

Expected: `agenix`, `agent-skills`, `anthropic-skills`, ... のように直接 inputs が列挙される（探索ロジックが参照する jq パスが有効であることの確認）

- [ ] **Step 4: コミット**

```bash
git add .github/actions/discover-flake-inputs/action.yaml
git commit -m "ci: add discover-flake-inputs composite action"
```

---

### Task 7: update-flake-input composite action（簡略版）

**Files:**

- Create: `.github/actions/update-flake-input/action.yaml`

**Interfaces:**

- Consumes: `nix flake update`、`gh`（runner 標準搭載）、`github-token`。
- Produces: ローカル action `./.github/actions/update-flake-input`。入力 `input-name`, `current-version`, `owner`, `repo`, `ref`, `skip-delay`, `minimum-release-age-days`, `auto-merge`, `pr-labels`, `github-token`。出力 `updated`, `new-version`, `pr-url`。1 input を更新し、変化があれば `update-flake-<input-name>` ブランチに PR を作成して auto-merge を有効化する。

- [ ] **Step 1: action ファイルを作成する**

`.github/actions/update-flake-input/action.yaml`:

```yaml
name: "Update Flake Input"
description: "Update a single Nix flake input with optional release age check and auto-merge"

inputs:
  input-name:
    description: "Name of the flake input to update"
    required: true
  current-version:
    description: "Current version/revision of the input"
    required: true
  owner:
    description: "GitHub owner of the input repository"
    required: false
    default: ""
  repo:
    description: "GitHub repository name of the input"
    required: false
    default: ""
  ref:
    description: "Git ref (branch/tag) of the input"
    required: false
    default: ""
  skip-delay:
    description: "Skip the minimum release age check"
    required: false
    default: "false"
  minimum-release-age-days:
    description: "Minimum release age in days before updating"
    required: false
    default: "3"
  auto-merge:
    description: "Enable auto-merge for the PR"
    required: false
    default: "true"
  pr-labels:
    description: "Comma-separated labels to add to the PR"
    required: false
    default: "dependencies,automated"
  github-token:
    description: "GitHub token for creating PRs and enabling auto-merge"
    required: true

outputs:
  updated:
    description: "Whether the input was updated"
    value: ${{ steps.update.outputs.updated }}
  new-version:
    description: "New version/revision after update"
    value: ${{ steps.update.outputs.new_version }}
  pr-url:
    description: "URL of the created/updated PR"
    value: ${{ steps.create-pr.outputs.pr_url }}

runs:
  using: "composite"
  steps:
    - name: Update flake input
      id: update
      shell: bash
      env:
        INPUT_NAME: ${{ inputs.input-name }}
        INPUT_OWNER: ${{ inputs.owner }}
        INPUT_REPO: ${{ inputs.repo }}
        INPUT_REF: ${{ inputs.ref }}
        SKIP_DELAY: ${{ inputs.skip-delay }}
        MIN_AGE_DAYS: ${{ inputs.minimum-release-age-days }}
        GH_TOKEN: ${{ inputs.github-token }}
      run: |
        set -euo pipefail

        echo "=== Updating input: $INPUT_NAME ==="
        min_age_seconds=$((MIN_AGE_DAYS * 86400))

        current_metadata=$(nix flake metadata --json --no-write-lock-file 2>/dev/null)
        current_rev=$(echo "$current_metadata" | jq -r ".locks.nodes.\"$INPUT_NAME\".locked.rev // \"unknown\"")
        echo "Current revision: $current_rev"

        target_rev=""
        if [ "$SKIP_DELAY" = "false" ] && [ -n "$INPUT_OWNER" ] && [ -n "$INPUT_REPO" ] \
           && [ "$INPUT_OWNER" != "unknown" ] && [ "$INPUT_REPO" != "unknown" ]; then
          echo "Fetching commit from at least $MIN_AGE_DAYS days ago via GitHub API..."
          cutoff_date=$(date -u -d "$MIN_AGE_DAYS days ago" +%Y-%m-%dT%H:%M:%SZ)
          api_url="repos/${INPUT_OWNER}/${INPUT_REPO}/commits?until=${cutoff_date}&per_page=1"
          if [ -n "$INPUT_REF" ]; then
            api_url="${api_url}&sha=${INPUT_REF}"
          fi

          if commit_data=$(gh api "$api_url" --jq '.[0] | {sha: .sha, date: .commit.committer.date}' 2>/dev/null); then
            target_rev=$(echo "$commit_data" | jq -r '.sha // empty')
            commit_date=$(echo "$commit_data" | jq -r '.date // empty')
            if [ -n "$target_rev" ]; then
              echo "Found commit from $commit_date: ${target_rev:0:8}"
              if [ "${target_rev:0:40}" = "${current_rev:0:40}" ]; then
                echo "Target revision equals current. No update needed."
                echo "updated=false" >> "$GITHUB_OUTPUT"
                exit 0
              fi
            else
              echo "No commits older than $MIN_AGE_DAYS days. Skipping."
              echo "updated=false" >> "$GITHUB_OUTPUT"
              exit 0
            fi
          else
            echo "Warning: GitHub API fetch failed, falling back to standard update"
          fi
        fi

        if [ -n "$target_rev" ]; then
          echo "Updating to specific revision ${target_rev:0:8}"
          if ! nix flake update "$INPUT_NAME" --override-input "$INPUT_NAME" "github:${INPUT_OWNER}/${INPUT_REPO}/${target_rev}"; then
            echo "::error::Failed to update $INPUT_NAME to specific revision"
            exit 1
          fi
        else
          echo "Standard update (latest)"
          if ! nix flake update "$INPUT_NAME"; then
            echo "::error::Failed to update $INPUT_NAME"
            exit 1
          fi
        fi

        if git diff --quiet flake.lock; then
          echo "No changes detected for $INPUT_NAME"
          echo "updated=false" >> "$GITHUB_OUTPUT"
          exit 0
        fi

        new_metadata=$(nix flake metadata --json --no-write-lock-file 2>/dev/null)
        new_rev=$(echo "$new_metadata" | jq -r ".locks.nodes.\"$INPUT_NAME\".locked.rev // \"unknown\"")
        echo "New revision: $new_rev"

        if [ -z "$target_rev" ] && [ "$SKIP_DELAY" = "false" ]; then
          last_modified=$(echo "$new_metadata" | jq -r ".locks.nodes.\"$INPUT_NAME\".locked.lastModified // 0")
          if [ "$last_modified" != "0" ] && [ "$last_modified" != "null" ]; then
            current_time=$(date +%s)
            age_seconds=$((current_time - last_modified))
            echo "Release age: $((age_seconds / 86400)) days"
            if [ "$age_seconds" -lt "$min_age_seconds" ]; then
              echo "Release too new (< $MIN_AGE_DAYS days). Reverting."
              git checkout flake.lock
              echo "updated=false" >> "$GITHUB_OUTPUT"
              exit 0
            fi
          fi
        fi

        echo "Update successful!"
        echo "updated=true" >> "$GITHUB_OUTPUT"
        echo "new_version=${new_rev:0:8}" >> "$GITHUB_OUTPUT"

    - name: Create pull request
      id: create-pr
      if: steps.update.outputs.updated == 'true'
      shell: bash
      env:
        GH_TOKEN: ${{ inputs.github-token }}
        INPUT_NAME: ${{ inputs.input-name }}
        CURRENT_VERSION: ${{ inputs.current-version }}
        NEW_VERSION: ${{ steps.update.outputs.new_version }}
        SKIP_DELAY: ${{ inputs.skip-delay }}
        AUTO_MERGE: ${{ inputs.auto-merge }}
        PR_LABELS: ${{ inputs.pr-labels }}
        MIN_AGE_DAYS: ${{ inputs.minimum-release-age-days }}
      run: |
        set -euo pipefail

        branch="update-flake-${INPUT_NAME}"
        pr_title="chore(nix): update flake input ${INPUT_NAME} to ${NEW_VERSION}"

        if [ "$SKIP_DELAY" = "true" ]; then
          delay_note=":zap: This input skips the release age check."
        else
          delay_note=":hourglass: This update passed the ${MIN_AGE_DAYS}-day minimum release age check."
        fi

        pr_body="Automated update of flake input \`${INPUT_NAME}\`.

        ## Changes
        - **${INPUT_NAME}**: \`${CURRENT_VERSION}\` :arrow_right: \`${NEW_VERSION}\`

        ## Notes
        ${delay_note}

        ---
        This PR was automatically created by the flake update workflow."

        git add flake.lock
        git checkout -b "$branch"
        git commit -m "$pr_title"
        git push --force origin "$branch"

        pr_number=$(gh pr list --head "$branch" --json number --jq '.[0].number // empty')
        if [ -n "$pr_number" ]; then
          echo "Updating existing PR #$pr_number"
          gh pr edit "$pr_number" --title "$pr_title" --body "$pr_body"
        else
          echo "Creating new PR"
          label_args=""
          IFS=',' read -ra labels <<< "$PR_LABELS"
          for label in "${labels[@]}"; do
            label=$(echo "$label" | xargs)
            label_args="$label_args --label $label"
          done
          gh pr create --title "$pr_title" --body "$pr_body" --base main --head "$branch" $label_args
          pr_number=$(gh pr list --head "$branch" --json number --jq '.[0].number')
        fi

        if [ "$AUTO_MERGE" = "true" ] && [ -n "$pr_number" ]; then
          echo "Enabling auto-merge for PR #$pr_number"
          gh pr merge "$pr_number" --auto --squash || echo "Note: auto-merge may require branch protection rules"
        fi

        pr_url=$(gh pr view "$pr_number" --json url --jq '.url')
        echo "pr_url=$pr_url" >> "$GITHUB_OUTPUT"
```

- [ ] **Step 2: YAML が妥当か確認する**

Run: `nix run nixpkgs#yq-go -- '.' .github/actions/update-flake-input/action.yaml > /dev/null && echo OK`
Expected: `OK`

- [ ] **Step 3: コミット**

```bash
git add .github/actions/update-flake-input/action.yaml
git commit -m "ci: add update-flake-input composite action"
```

---

### Task 8: update-flake workflow（並列更新）

**Files:**

- Create: `.github/workflows/update-flake.yaml`

**Interfaces:**

- Consumes: `./.github/actions/setup-nix`（Task 1）、`./.github/actions/setup-git-bot`（Task 5）、`./.github/actions/discover-flake-inputs`（Task 6）、`./.github/actions/update-flake-input`（Task 7）、Secrets `NIX_UPDATER_APP_ID` / `NIX_UPDATER_APP_PRIVATE_KEY`。
- Produces: 日次 + 手動の自動更新 workflow。`discover` → matrix → `update`（input ごと並列）→ `summary`。

- [ ] **Step 1: workflow を作成する**

`.github/workflows/update-flake.yaml`:

```yaml
name: "Bot: Update flake inputs"

on:
  schedule:
    - cron: "0 6 * * *"
  workflow_dispatch:
    inputs:
      inputs:
        description: "Specific flake inputs to update (space-separated, empty for all)"
        required: false
        default: ""
      minimum-release-age-days:
        description: "Minimum release age in days before updating"
        required: false
        default: "3"
      skip-delay:
        description: "Skip the minimum release age check for all inputs"
        required: false
        type: boolean
        default: false

jobs:
  discover:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.discover.outputs.matrix }}
      has-updates: ${{ steps.discover.outputs.has-updates }}
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7

      - name: Setup Nix
        uses: ./.github/actions/setup-nix

      - name: Discover flake inputs
        id: discover
        uses: ./.github/actions/discover-flake-inputs
        with:
          inputs: ${{ github.event.inputs.inputs || '' }}

  update:
    needs: discover
    if: needs.discover.outputs.has-updates == 'true'
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix: ${{ fromJson(needs.discover.outputs.matrix) }}
    permissions:
      contents: write
      pull-requests: write
    steps:
      - name: Checkout repository (for local actions)
        uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7

      - name: Set up git bot identity
        id: bot
        uses: ./.github/actions/setup-git-bot
        with:
          app-id: ${{ secrets.NIX_UPDATER_APP_ID }}
          private-key: ${{ secrets.NIX_UPDATER_APP_PRIVATE_KEY }}

      - name: Checkout repository (with bot token)
        uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7
        with:
          token: ${{ steps.bot.outputs.token }}

      - name: Setup Nix
        uses: ./.github/actions/setup-nix

      - name: Update flake input
        uses: ./.github/actions/update-flake-input
        with:
          input-name: ${{ matrix.name }}
          current-version: ${{ matrix.current_version }}
          owner: ${{ matrix.owner }}
          repo: ${{ matrix.repo }}
          ref: ${{ matrix.ref }}
          skip-delay: ${{ github.event.inputs.skip-delay == 'true' && 'true' || matrix.skip_delay }}
          minimum-release-age-days: ${{ github.event.inputs.minimum-release-age-days || '3' }}
          auto-merge: "true"
          github-token: ${{ steps.bot.outputs.token }}

  summary:
    needs: [discover, update]
    runs-on: ubuntu-latest
    if: always() && needs.discover.outputs.has-updates == 'true'
    steps:
      - name: Generate summary
        env:
          UPDATE_RESULT: ${{ needs.update.result }}
        run: |
          echo "## Flake Update Summary" >> "$GITHUB_STEP_SUMMARY"
          echo "" >> "$GITHUB_STEP_SUMMARY"
          if [ "$UPDATE_RESULT" = "failure" ]; then
            echo ":warning: Some updates failed. Check individual job logs." >> "$GITHUB_STEP_SUMMARY"
          else
            echo ":white_check_mark: All update jobs completed." >> "$GITHUB_STEP_SUMMARY"
          fi
```

- [ ] **Step 2: actionlint で検証する**

Run: `nix run nixpkgs#actionlint -- .github/workflows/update-flake.yaml`
Expected: 出力なし・終了コード 0（4 つのローカル action 参照と入力が解決できること）

- [ ] **Step 3: コミット**

```bash
git add .github/workflows/update-flake.yaml
git commit -m "ci: add update-flake workflow with parallel matrix updates"
```

---

### Task 9: auto-rebase workflow

**Files:**

- Create: `.github/workflows/auto-rebase.yaml`

**Interfaces:**

- Consumes: `./.github/actions/setup-git-bot`（Task 5）、Secrets `NIX_UPDATER_APP_ID` / `NIX_UPDATER_APP_PRIVATE_KEY`、`gh`。
- Produces: main への push（マージ）時に `update-flake-*` ブランチの開き PR を `origin/main` に rebase する workflow。

- [ ] **Step 1: workflow を作成する**

`.github/workflows/auto-rebase.yaml`:

```yaml
name: "Bot: Auto-rebase PRs"

on:
  push:
    branches:
      - main
  workflow_dispatch:

concurrency:
  group: auto-rebase
  cancel-in-progress: false

jobs:
  rebase-prs:
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch' || github.event.head_commit.committer.name == 'GitHub'
    steps:
      - name: Checkout repository (for local actions)
        uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7

      - name: Set up git bot identity
        id: bot
        uses: ./.github/actions/setup-git-bot
        with:
          app-id: ${{ secrets.NIX_UPDATER_APP_ID }}
          private-key: ${{ secrets.NIX_UPDATER_APP_PRIVATE_KEY }}

      - name: Checkout repository (with bot token)
        uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7
        with:
          token: ${{ steps.bot.outputs.token }}
          fetch-depth: 0

      - name: Rebase open flake update PRs
        env:
          GH_TOKEN: ${{ steps.bot.outputs.token }}
        run: |
          set -euo pipefail

          prs=$(gh pr list --state open --json number,headRefName \
            --jq '.[] | select(.headRefName | startswith("update-flake-")) | "\(.number) \(.headRefName)"')

          if [ -z "$prs" ]; then
            echo "No open flake update PRs found"
            exit 0
          fi

          echo "$prs" | while read -r pr_number branch_name; do
            echo "=== PR #$pr_number ($branch_name) ==="
            git fetch origin "$branch_name"
            behind_count=$(git rev-list --count "origin/$branch_name..origin/main")
            if [ "$behind_count" -eq 0 ]; then
              echo "Up to date, skipping"
              continue
            fi
            echo "$behind_count commits behind, rebasing..."
            git checkout -B "$branch_name" "origin/$branch_name"
            if git rebase origin/main; then
              git push --force origin "$branch_name"
              echo "Rebased PR #$pr_number"
            else
              echo "Rebase failed for PR #$pr_number, aborting"
              git rebase --abort
            fi
            git checkout main
          done
```

- [ ] **Step 2: actionlint で検証する**

Run: `nix run nixpkgs#actionlint -- .github/workflows/auto-rebase.yaml`
Expected: 出力なし・終了コード 0

- [ ] **Step 3: コミット**

```bash
git add .github/workflows/auto-rebase.yaml
git commit -m "ci: add auto-rebase workflow for flake update PRs"
```

---

### Task 10: Dependabot + auto-merge

**Files:**

- Create: `.github/dependabot.yml`
- Create: `.github/workflows/dependabot-automerge.yaml`

**Interfaces:**

- Consumes: GitHub 純正 Dependabot、`gh`、`GITHUB_TOKEN`。
- Produces: Actions pin の週次更新 PR と、その自動マージ。

- [ ] **Step 1: dependabot.yml を作成する**

`.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    labels:
      - "dependencies"
      - "github-actions"
```

- [ ] **Step 2: auto-merge workflow を作成する**

`.github/workflows/dependabot-automerge.yaml`:

```yaml
name: "Bot: Dependabot auto-merge"

on:
  pull_request:

permissions:
  contents: write
  pull-requests: write

jobs:
  automerge:
    runs-on: ubuntu-latest
    if: github.actor == 'dependabot[bot]'
    steps:
      - name: Enable auto-merge
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PR_URL: ${{ github.event.pull_request.html_url }}
        run: gh pr merge --auto --squash "$PR_URL"
```

- [ ] **Step 3: YAML / actionlint で検証する**

Run:

```bash
nix run nixpkgs#yq-go -- '.' .github/dependabot.yml > /dev/null && \
nix run nixpkgs#actionlint -- .github/workflows/dependabot-automerge.yaml && echo OK
```

Expected: `OK`（dependabot.yml がパースでき、workflow に actionlint エラーがない）

- [ ] **Step 4: コミット**

```bash
git add .github/dependabot.yml .github/workflows/dependabot-automerge.yaml
git commit -m "ci: add dependabot config and auto-merge for actions pins"
```

---

### Task 11: 手動設定手順のドキュメント

**Files:**

- Create: `docs/github-actions-setup.md`

**Interfaces:**

- Consumes: なし。
- Produces: GitHub 上でしかできない設定（GitHub App / Secrets / branch protection / auto-merge 許可）の手順書。これが無いと auto-merge が機能しないため必須。

- [ ] **Step 1: ドキュメントを作成する**

`docs/github-actions-setup.md`:

```markdown
# GitHub Actions 導入後の手動設定

このリポジトリの CI / 自動更新を機能させるには、GitHub 上で以下を一度だけ設定する。

## 1. flake 更新 bot 用 GitHub App

1. GitHub の Settings → Developer settings → GitHub Apps → New GitHub App。
2. 権限（Repository permissions）:
   - Contents: Read and write
   - Pull requests: Read and write
3. App を作成し、このリポジトリに Install する。
4. App の **App ID** と **Private key**（生成してダウンロード）を控える。
5. リポジトリの Settings → Secrets and variables → Actions に登録:
   - `NIX_UPDATER_APP_ID` = App ID
   - `NIX_UPDATER_APP_PRIVATE_KEY` = Private key（PEM 全文）

## 2. auto-merge の有効化

リポジトリ Settings → General → Pull Requests →
**Allow auto-merge** をチェック。

## 3. branch protection（main）

Settings → Branches → Add branch protection rule（対象 `main`）:

- **Require status checks to pass before merging** を ON にし、以下を必須に指定:
  - `lint`
  - `build (nixos)`
  - `build (wsl-home)`
- **Require branches to be up to date before merging** を ON。

これで、flake 更新 PR と Dependabot PR は CI 通過後に自動マージされる。
複数 PR が衝突した場合は auto-rebase workflow が残り PR を main に追従させる。
```

- [ ] **Step 2: ドキュメントがレンダリングできることを確認する**

Run: `nix run nixpkgs#yq-go --version > /dev/null; test -f docs/github-actions-setup.md && echo OK`
Expected: `OK`（ファイルが存在する）

- [ ] **Step 3: コミット**

```bash
git add docs/github-actions-setup.md
git commit -m "docs: add GitHub Actions manual setup guide"
```

---

## Self-Review

**Spec coverage（spec の各節 → タスク対応）:**

- setup-nix → Task 1 ✓
- lint.yaml → Task 2 ✓
- nix-build.yaml（並列ビルド）→ Task 3 ✓
- nix-diff.yaml → Task 4 ✓
- setup-git-bot → Task 5 ✓
- discover-flake-inputs → Task 6 ✓
- update-flake-input（簡略版）→ Task 7 ✓
- update-flake.yaml（並列更新）→ Task 8 ✓
- auto-rebase.yaml → Task 9 ✓
- dependabot.yml + dependabot-automerge.yaml → Task 10 ✓
- 手動設定（GitHub App / branch protection / auto-merge）→ Task 11 ✓

**Placeholder scan:** 各タスクに実ファイル全文と実コマンド・期待出力を記載。TBD/TODO なし。

**Type consistency:**

- composite action の出力名（`matrix` / `has-updates` / `token` / `updated` / `new_version` / `pr_url`）と consumer 側の参照（`needs.discover.outputs.matrix` 等、`steps.bot.outputs.token` 等）が一致。
- branch protection の必須チェック名（`lint` / `build (nixos)` / `build (wsl-home)`）が、実ジョブ名（`lint` ジョブ、`build` ジョブの matrix `name`）と整合。
- Secrets 名（`NIX_UPDATER_APP_ID` / `NIX_UPDATER_APP_PRIVATE_KEY`）が Task 8 / 9 / 11 で一致。
- ビルド属性パスが Global Constraints・Task 3・Task 4・nix-diff の attribute で一致。

```

```
