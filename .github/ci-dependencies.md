# GitHub Actions 構成メモ

この dotfiles の CI / 自動化（`.github/workflows` と `.github/actions`）の全体像・依存関係・ハマりどころをまとめたメモ。
将来の自分が忘れたとき用。

## 全体像

大きく 2 系統。

- **CI 系（検証）**: push / PR のたびに Nix のビルド・lint・差分表示を行う
- **Bot 系（自動更新）**: cron で flake input を毎日更新し、PR を自動生成 → 自動マージする

構成要素は **6 つの workflow**、**4 つの composite action**、**1 つの dependabot 設定**。

中心にいるのは GitHub App bot（secrets `NIX_UPDATER_APP_ID` / `NIX_UPDATER_APP_PRIVATE_KEY`）。
PR 作成・auto-merge・rebase を回す主体。`GITHUB_TOKEN` ではなく App token を使う理由は、
bot の push で他の workflow（CI）を再発火させるため、と auto-rebase の `committer.name == 'GitHub'` 判定を成立させるため。

## Workflow 一覧とトリガー

| Workflow                   | ファイル                              | トリガー                             | 役割                                                 |
| -------------------------- | ------------------------------------- | ------------------------------------ | ---------------------------------------------------- |
| Bot: Update flake inputs   | `workflows/update-flake.yaml`         | `schedule` 毎日 06:00 UTC / 手動     | flake input を更新し PR 自動生成・auto-merge         |
| Bot: Auto-rebase PRs       | `workflows/auto-rebase.yaml`          | `push`(main) / 手動                  | 開いている `update-flake-*` PR を main に追従 rebase |
| Bot: Dependabot auto-merge | `workflows/dependabot-automerge.yaml` | `pull_request`                       | dependabot の PR を auto-merge                       |
| CI: Lint                   | `workflows/lint.yaml`                 | `push` / `pull_request`              | `nix flake check` + フォーマット確認                 |
| CI: Nix build              | `workflows/nix-build.yaml`            | `push`(main) / `pull_request` / 手動 | nixos と home-manager(wsl) をビルド                  |
| CI: Nix diff               | `workflows/nix-diff.yaml`             | `pull_request`(Nix 関連 paths)       | derivation 差分を PR にコメント                      |

## Composite Action（再利用部品）

| Action                          | 役割                                                             | 使う側                                     |
| ------------------------------- | ---------------------------------------------------------------- | ------------------------------------------ |
| `actions/setup-nix`             | Nix インストール + バイナリキャッシュ（flake.lock ハッシュキー） | lint / nix-build / nix-diff / update-flake |
| `actions/setup-git-bot`         | GitHub App token 発行 + bot の git identity 設定                 | update-flake / auto-rebase                 |
| `actions/discover-flake-inputs` | `nix flake metadata` から更新対象を走査しマトリクス生成          | update-flake（discover ジョブ）            |
| `actions/update-flake-input`    | 1 input の更新 + release-age チェック + PR 作成 + auto-merge     | update-flake（update ジョブ）              |

## 実行フロー（ツリー）

### cron トリガー（毎日 06:00 UTC）

```
schedule: "0 6 * * *"  →  update-flake.yaml
│
├─ job: discover
│   ├─ setup-nix
│   └─ discover-flake-inputs   ── nix flake metadata で input 一覧 → matrix(JSON), has-updates
│
├─ job: update   [needs: discover, if has-updates == 'true']
│   strategy.matrix = discover の出力（input ごとに並列・fail-fast 無効）
│   ├─ setup-git-bot           ── App token と git identity を用意
│   ├─ checkout(bot token)
│   ├─ setup-nix
│   └─ update-flake-input
│       ├─ step update : skip-delay=false なら GitHub API で「N 日以上前のコミット」に更新
│       │                （minimum-release-age チェック。新しすぎる release は revert）
│       └─ step create-pr [if updated]
│           ├─ branch: update-flake-<input> を force push
│           ├─ gh pr create / edit
│           └─ gh pr merge --auto --squash（auto-merge 有効化）
│
└─ job: summary  [needs: discover+update, if always() && has-updates]
    └─ STEP_SUMMARY に成否を出力
```

### push(main) トリガー

```
push(main)  →  auto-rebase.yaml   concurrency: auto-rebase（直列化）
│   if: 手動 OR head_commit.committer.name == 'GitHub'（= squash-merge 起因のみ）
└─ job: rebase-prs
    ├─ setup-git-bot
    ├─ checkout(fetch-depth: 0)
    └─ 開いている update-flake-* PR を main に追従 rebase → force push

push(main)  →  nix-build.yaml（後述）
push(全ブランチ) → lint.yaml
```

### pull_request トリガー

```
pull_request
├─ lint.yaml       : setup-nix → nix flake check → nix run .#fmt --fail-on-change
├─ nix-build.yaml  : job changes(paths-filter) → job build [matrix: nixos / wsl-home]
├─ nix-diff.yaml   : nix-diff-action で nixos と home-manager(wsl) の差分を PR コメント
└─ dependabot-automerge.yaml : if actor==dependabot[bot] → gh pr merge --auto --squash
```

### dependabot（週次）

```
dependabot.yml → github-actions を weekly チェック → PR 作成（labels: dependencies, github-actions）
    └─ dependabot-automerge.yaml が拾って auto-merge
```

## 全体の循環（依存の肝）

```
[cron 06:00]
  └→ update-flake が input ごとに PR を量産
       └→ auto-merge で 1 件ずつ main に squash-merge
            └→ push(main) が auto-rebase を起動
                 └→ 残りの update-flake-* PR を main に rebase
                      └→ それらも CI を再実行 → auto-merge → また push(main) …（PR が尽きるまで循環）
```

`main` のブランチ保護で `strict: true`（main 追従必須）が付いているため、PR が順にマージされると
残りが out-of-date になる。それを追従させるのが auto-rebase の役割。

## ⚠️ ハマりどころ / 前提条件（重要）

### 1. PR 作成にはラベルが実在している必要がある

`update-flake-input/action.yaml` は PR 作成時に `--label dependencies --label automated` を付ける。
**存在しないラベルを指定すると `gh pr create` は PR を作らずに exit 1 する。**
（branch の push は成功するので「ブランチはあるが PR が無い」状態になる）

→ リポジトリに `dependencies` と `automated` ラベルが存在していること。
dependabot.yml も `dependencies` ラベルを前提にしている。

```sh
gh label create dependencies --color 0366d6 --description "Dependency updates" --force
gh label create automated    --color ededed --description "Automated PR" --force
```

### 2. auto-merge にはブランチ保護の必須チェックが全部緑になる必要がある

`main` のブランチ保護で必須ステータスチェックに **`lint` / `build (wsl-home)` / `build (nixos)`** が設定されている。
PR が作られても、これらが緑にならない限り auto-merge は完了しない。
（repo 設定 `allow_auto_merge: true` は有効済み、required review は 0）

### 3. hyprland はキャッシュ必須（さもないと build(nixos) が 30 分でタイムアウト）

nixos / home-manager の設定は hyprland を `inputs.hyprland.packages.<system>.hyprland`
（= hyprland 独自の nixpkgs でビルド）から入れている。
このビルドは **`cache.nixos.org` に存在しない**ため、対策が無いと CI は毎回ソースから
hyprland 一式（aquamarine, hyprwire, hyprtoolkit, portal …）をビルドし、
`timeout-minutes: 30` を超えて失敗する。

→ `flake.nix` の `nixConfig` で **hyprland 公式 Cachix** を substituter に追加してある。
`setup-nix` が `accept-flake-config = true` を設定済みなので CI でも有効。

```nix
nixConfig = {
  extra-substituters     = [ "https://hyprland.cachix.org" ];
  extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
};
```

検証方法（hit すれば 200 が返る）:

```sh
hrev=$(nix flake metadata --json | jq -r '.locks.nodes.hyprland.locked.rev')
out=$(nix eval --raw --accept-flake-config "github:hyprwm/Hyprland/$hrev#packages.x86_64-linux.hyprland.outPath")
hash=$(basename "$out" | cut -d- -f1)
curl -s -o /dev/null -w "%{http_code}\n" "https://hyprland.cachix.org/${hash}.narinfo"   # 200 を期待
```

`extra-substituters`（取得元 URL）と `extra-trusted-public-keys`（署名検証用の公開鍵）は必ずペア。
鍵を登録しないと署名検証に失敗してキャッシュが無視され、結局ソースビルドになる。

### 4. 他にキャッシュが要るパッケージは現状なし

- `zen-browser` は両キャッシュとも未ヒットだが、ソースビルドではなくビルド済みバイナリの展開だけなので
  数秒で終わり対策不要（公開 cachix も無い）。
- `cantarell-fonts` は unstable 版がビルド失敗 & 未キャッシュのため、`lib/default.nix` の overlay で
  stable 版にピン留めして回避済み（キャッシュ追加の代わりの別解）。
- その他の入力（agenix / disko / xremap / mcp-servers-nix / nix-index-database 等）は
  `inputs.nixpkgs.follows = "nixpkgs"` で nixpkgs に追従するため `cache.nixos.org` でカバーされる。

将来 hyprland 以外で「独自 nixpkgs を持つ重い flake 入力」を足したら、同じ手順
（`extra-substituters` + `extra-trusted-public-keys` のペア追加 → narinfo 200 を確認）で対応する。

### 5. concurrency による cancelled は正常動作

`nix-build.yaml` / `lint.yaml` は `concurrency.cancel-in-progress: true` のため、
同じ ref に連続 push すると古い実行が cancelled になる。これは設計通りで故障ではない。
