# GitHub Actions 構成メモ

この dotfiles の CI（`.github/workflows` と `.github/actions`）と、依存更新を担う Renovate の全体像・ハマりどころをまとめたメモ。
将来の自分が忘れたとき用。

## 全体像

大きく 2 系統。

- **CI 系（検証）**: push / PR のたびに Nix のビルド・lint・差分表示を行う（`.github/workflows`）
- **依存更新**: Renovate (Mend hosted) が `flake.lock` と GitHub Actions を更新する PR を作り、CI 緑で auto-merge する

以前は自前 GitHub App bot（`update-flake` / `auto-rebase` / dependabot）で更新していたが、Renovate に一本化した。
旧構成は input ごとに PR を量産し、auto-rebase の force-push で同じ `nixos` ビルド（約 28 分）が何度も cancelled になっていた。
`lockFileMaintenance` で 1 本 PR にまとめる方式へ移行してこの無駄を消した、という経緯がある。

## Workflow 一覧とトリガー

| Workflow                      | ファイル                         | トリガー                             | 役割                                                                      |
| ----------------------------- | -------------------------------- | ------------------------------------ | ------------------------------------------------------------------------- |
| CI: Lint                      | `workflows/lint.yaml`            | `push` / `pull_request`              | `nix flake check` + フォーマット確認                                      |
| CI: Nix build                 | `workflows/nix-build.yaml`       | `push`(main) / `pull_request` / 手動 | nixos と home-manager(wsl) をビルド                                       |
| CI: Nix diff                  | `workflows/nix-diff.yaml`        | `pull_request`(Nix 関連 paths)       | derivation 差分を PR にコメント                                           |
| Cache: Warm                   | `workflows/cache-warm.yaml`      | 毎日 03:00 UTC / 手動                | Renovate の翌朝の更新を先取りビルドして cachix を温める（非ブロッキング） |
| Dependencies: Update dwproton | `workflows/update-dwproton.yaml` | 毎日 02:30 UTC / 手動                | dwproton の version と Nix hash を更新する PR を作成                      |

## Composite Action（再利用部品）

| Action              | 役割                                                             | 使う側                      |
| ------------------- | ---------------------------------------------------------------- | --------------------------- |
| `actions/setup-nix` | Nix インストール + バイナリキャッシュ（flake.lock ハッシュキー） | lint / nix-build / nix-diff |

## Renovate（依存更新）

設定はリポジトリ直下の `renovate.json`。
Mend hosted の Renovate App がリポジトリを定期巡回して動く（自前サーバー・token・実行 workflow は不要）。

- **nix manager + `lockFileMaintenance`**: `flake.lock` の全 input を 1 本の PR にまとめて更新（日次 schedule）。input 単位の分割はしない。
- **github-actions manager**: `.github/workflows/*.yaml` と `.github/actions/*/action.yaml` の外部 `uses:` を追従更新（旧 dependabot の役割）。
- **automerge**: `flake.lock` は `lockFileMaintenance.automerge`、actions は `packageRules` で有効化。GitHub の auto-merge（`platformAutomerge`）を使い、ブランチ保護の必須チェックが緑になったらマージされる。
- **release-age は無し**: 旧構成の「3 日寝かせる」ゲートは `lockFileMaintenance` に効かないため廃止。CI ビルド緑を唯一のゲートにした。

## 実行フロー（ツリー）

### Renovate（Mend hosted が定期実行）

```
renovate.json
├─ nix (lockFileMaintenance)  → flake.lock を 1 本 PR で更新
└─ github-actions             → uses: のバージョン更新 PR
     └─ どちらも CI（lint / nix-build / nix-diff）で検証 → 緑なら auto-merge
```

dwproton は `fetchurl` の version と hash を同時に変える必要があるため、専用 workflow が更新する。
`scripts/update-dwproton.sh` が GitHub mirror の最新リリースを取得し、配布アーカイブを `nix store prefetch-file` して両方を更新する。
workflow 内の外部 Actions はバージョンタグで指定し、通常どおり Renovate の github-actions manager が更新する。

### pull_request / push トリガー（CI）

```
pull_request
├─ lint.yaml       : setup-nix → nix flake check → nix run .#fmt --fail-on-change
├─ nix-build.yaml  : job changes(paths-filter) → job build [matrix: nixos / wsl-home]
└─ nix-diff.yaml   : nix-diff-action で nixos の derivation 差分を PR コメント

push(main)      → nix-build.yaml
push(全ブランチ) → lint.yaml
```

## ⚠️ ハマりどころ / 前提条件（重要）

### 1. auto-merge にはブランチ保護の必須チェックが全部緑になる必要がある

`main` のブランチ保護で必須ステータスチェックに **`lint` / `build (wsl-home)` / `build (nixos)`** が設定されている（`strict: true`）。
Renovate の PR も、これらが緑にならない限り auto-merge は完了しない。
（repo 設定 `allow_auto_merge: true` は有効済み、required review は 0）

`allow_auto_merge` と branch protection は **public リポジトリだから Free で使える**。
private + Free では両方使えないため、public を維持している。
private に戻したくなったら、`renovate.json` の `platformAutomerge` を `false` にして Renovate 自身にマージさせる方式へ切り替える（GitHub の auto-merge に依存しなくなるが、CI 緑の「強制」は失われ Renovate のチェック待ちが実質ゲートになる）。

### 2. Renovate の nix manager は flake.nix の nixpkgs 参照文字列を要求する

`lockFileMaintenance` が `flake.lock` を refresh するには、`flake.nix` に `github:nixos/nixpkgs/...` 形式の文字列が含まれている必要がある。
現状は `nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"` があるので満たしている。
この行を消す・書き換えると Renovate が flake.lock の更新をやめるので注意。

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

### 4. 独自ビルドの Rust パッケージは自前 Cachix でカバー（`herdr` / `anime-games-launcher`）

`herdr` と `anime-games-launcher` は公開キャッシュに存在せず、`inputs.nixpkgs.follows = "nixpkgs"` で
nixpkgs に追従するため、lock が nixpkgs を更新するたびに派生ハッシュが変わり必ずソース再ビルドになる。
これが Renovate の lock 更新 PR で `build (nixos)` を 30 分タイムアウトさせていた真因（hyprland ではない）。

→ public キャッシュ `mkiin-dotfiles.cachix.org` を作成し、`nix-build.yaml` の build ジョブに
`cachix/cachix-action`（`name: mkiin-dotfiles` + `CACHIX_AUTH_TOKEN`）を追加。post-build-hook で
ソースビルドされた成果物だけが push されるため、`cache.nixos.org` から来る依存は push されない
（1 回約 42 MB、5GB 枠に十分収まる）。`flake.nix` の `nixConfig` にも substituter + 公開鍵を追加済みで、
ローカルの `nix run .#switch` も同キャッシュから substitute する。将来 `herdr` 以外の独自ビルドが増えても
パッケージ個別設定なしで自動的にカバーされる。設計は
`docs/superpowers/specs/2026-07-06-cachix-ci-build-cache-design.md`。

なお Cachix は「push 済みの成果物を substitute する」仕組みのため、Renovate PR の初回ビルドは依然
ソースビルドになる。ここは `timeout-minutes: 120`（public ランナーは無料無制限）で完走させる分担。

その他のキャッシュ事情:

- `honkers-railway`（aagl 経由）は follows があっても `ezkea.cachix.org` に hit するため対策不要。
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
（Renovate の 1 本 PR 化で、旧構成のような auto-rebase 連鎖による大量 cancelled は起きなくなった。）

### 6. GitHub Actions の料金

public リポジトリ + 標準ランナー（`ubuntu-latest`）なので Actions は無料・無制限。
larger runner を使うか private 化しない限り課金されない（private + Free は月 2000 分の無料枠）。
build(nixos) が 28 分かかっても、public 標準ランナーである限り分課金は発生しない。

### 7. cache-warm.yaml: 初回コールドビルドを PR の必須チェックから逃がす

`build (nixos)` / `build (wsl-home)` は必須チェックである以上 `timeout-minutes` に上限がある。
llm-agents.nix の更新で `codex`（Rust 製、multi-crate workspace）のようなビルドの重いパッケージが
巻き込まれてキャッシュミスすると、120 分でも足りず cancelled になり得る（実例: 2026-07-24, PR #61,
rustc バージョン変更で codex 一式が未キャッシュになり 60 分タイムアウト）。cancelled は required
status check 上は非 green 扱いのため、Renovate の automerge が永久に成立しない。

→ `cache-warm.yaml` を新設。毎日 03:00 UTC（Renovate の `lockFileMaintenance` schedule `before 6am`
より前）に `nix flake update`（コミットしない、その場限り）で翌朝 Renovate が作るのと同じ更新を
先取りし、`timeout-minutes: 180` の非ブロッキングジョブ（`continue-on-error: true`、必須チェックには
未登録）でビルドして `mkiin-dotfiles.cachix.org` に温めておく。これにより実際の Renovate PR が来た
時点では既にキャッシュがヒットし、必須チェック側は短時間で完走する想定。

ビルドは matrix（別ランナー）ではなく単一ランナー上で
[2026-06-25 に GA した parallel steps](https://github.blog/changelog/2026-06-25-actions-steps-can-now-be-run-in-parallel/)
（`parallel:` ブロック）を使って nixos / wsl-home を並行実行している。両 configuration は
`home-manager/{cli,editor,ai}` の大半（codex や claude-code を含む）を共有しているため、matrix で
ランナーを分けると重い derivation を 2 回コールドビルドすることになる。同一 Nix store を共有する
単一ランナー上で並行ビルドすれば、共通の重い derivation は 1 回のビルドで両方に効く。
