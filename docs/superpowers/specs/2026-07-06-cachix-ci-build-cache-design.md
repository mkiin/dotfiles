# Cachix による CI ビルドキャッシュ導入 設計

## 背景と問題

Renovate の `flake.lock` 更新 PR で `build (nixos)` が 30 分でタイムアウトして失敗し、auto-merge が止まる。
`build (wsl-home)` は 6 分で通る。

原因は当初 hyprland だと考えていたが、失敗ログの実測で否定された。
真因は、どのバイナリキャッシュにも存在しない独自ビルドの Rust パッケージ 2 つである。

- `herdr`（`github:ogulcancelik/herdr`。cli で使用）
- `anime-games-launcher`（`github:an-anime-team/anime-games-launcher`。nixos の games で使用）

これらは `inputs.nixpkgs.follows = "nixpkgs"` で自分の nixpkgs に追従するため、lock が nixpkgs を更新するたびに派生ハッシュが変わり、必ずソースから再ビルドされる。
`build (wsl-home)` が通るのは、WSL が `anime-games-launcher` を import しないからである。

## 実測データ

nixos 閉包 2177 path のキャッシュ被覆状況を narinfo プローブで実測した。

| 出所                | path 数                      |
| ------------------- | ---------------------------- |
| cache.nixos.org     | 1809                         |
| hyprland.cachix.org | 39                           |
| ezkea.cachix.org    | 13（honkers-railway を含む） |
| どこにも無い        | 316                          |

「どこにも無い 316」の大半は NixOS がその場で生成する設定 glue（`system-path`、`udev-rules`、`*.service` など）でビルドコストはほぼゼロである。
CI ログと突き合わせると、毎回ソースビルドされる重いものは `herdr` と `anime-games-launcher` の 2 つに確定する。
`honkers-railway` は follows があっても `ezkea.cachix.org` に hit しており、対策は不要である。

1 回のビルドで実際に push される量（cache.nixos.org に無い path のみ）も実測した。

| パッケージ           | 閉包全体 | push 対象     |
| -------------------- | -------- | ------------- |
| herdr                | 63 MB    | 17.3 MB       |
| anime-games-launcher | 1027 MB  | 24.7 MB       |
| 合計                 |          | 約 42 MB / 回 |

anime-games-launcher の閉包は 1 GB あるが、その 297 個の依存は cache.nixos.org に在るため push されない。
倉庫に入るのは各パッケージの本体だけで、1 回あたり約 42 MB に収まる。

## ゴール

2 つを別のレバーで解く。

1. Renovate PR の初回 CI ビルドを打ち切られず完走させ、auto-merge を通す。
2. ローカルの `git pull && nix run .#switch` と CI 再実行で、`herdr` と `anime-games-launcher` を再ビルドせず substitute する。

Cachix は「一度 push した成果物を substitute する」仕組みのため、ゴール 1（初回ビルドを速くする）は解けない。
ゴール 1 は timeout 緩和で解き、ゴール 2 を Cachix で解く、という分担にする。

## 用語

- **キャッシュ**：Cachix サービス上に作る、ビルド済みパッケージの倉庫。`https://<name>.cachix.org` の住所を持つ。
- **他人のキャッシュ**：`hyprland.cachix.org`、`ezkea.cachix.org`。読むだけ。書き込み権限は無い。
- **自分のキャッシュ**：今回新しく作る、書き込み可能なキャッシュ。CI がビルド結果を push し、CI とローカルが substitute する。

## 設計

作業場所は 3 つに分かれる。

### 1. Cachix 側（一度だけ）

- OSS 5GB 無料枠でキャッシュを 1 つ作る。名前は `mkiin-dotfiles`（変更可）。
- 書き込み用の auth token を発行する。
- garbage collection を設定する。条件は「一定期間ダウンロードされていない成果物を削除」。
  これにより、新しい 42 MB が入るたびに使われなくなった古い成果物が消え、容量は 5GB の手前で頭打ちになる。

### 2. GitHub 側（一度だけ）

- 発行した auth token を、リポジトリの Secret `CACHIX_AUTH_TOKEN` に登録する。

### 3. リポジトリのファイル

**`flake.nix` の `nixConfig`（substituter 追加）**

hyprland/ezkea と同じ形で、自分のキャッシュを substituter と公開鍵のペアで追加する。
これで CI とローカルの両方が同じキャッシュを読む。

```nix
nixConfig = {
  extra-substituters = [
    "https://hyprland.cachix.org"
    "https://ezkea.cachix.org"
    "https://mkiin-dotfiles.cachix.org"
  ];
  extra-trusted-public-keys = [
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    "ezkea.cachix.org-1:/Hcp/kUFmp+2FLdzXlmDF9SHFsMzQoPZWH8fXOTdVBM="
    "mkiin-dotfiles.cachix.org-1:<公開鍵>"
  ];
};
```

公開鍵はキャッシュ作成時に Cachix が発行する値を入れる。

**`.github/workflows/nix-build.yaml`（push と timeout）**

`build` ジョブに `cachix/cachix-action` を追加し、ビルドされた path を自動で push する。
`cachix-action` は post-build-hook を設定するため、ソースビルドされた path だけが push され、cache.nixos.org から substitute された path は push されない。
将来 `herdr`/`anime-games-launcher` 以外の独自ビルドが増えても、パッケージ個別の設定なしで自動的にカバーされる。

```yaml
- name: Setup Cachix
  if: needs.changes.outputs.nix == 'true' || github.event_name == 'workflow_dispatch'
  uses: cachix/cachix-action@<pinned>
  with:
    name: mkiin-dotfiles
    authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}
```

同ジョブの `timeout-minutes` を 30 から 60 に変える。
public リポジトリ + 標準ランナーのため、60 分に伸ばしても課金は発生しない。
実際に 60 分近くかかるのは各 lock 更新の初回だけで、以降は自分のキャッシュに hit して短くなる。

## データフロー

1. Renovate が `flake.lock` を更新した PR を作る。
2. CI の `build (nixos)` が走る。`herdr` と `anime-games-launcher` の新ハッシュは自分のキャッシュにまだ無いため、初回はソースビルドする（timeout 60 分で完走）。
3. `cachix-action` の post-build-hook が、ビルドした 2 つの成果物（約 42 MB）を自分のキャッシュに push する。
4. CI が緑になり auto-merge される。
5. ローカルで `git pull && nix run .#switch` すると、`flake.nix` の substituter 経由で自分のキャッシュから 2 つの成果物を substitute する（再ビルドしない）。

## スコープ外

- レバー 1（`follows` を外して upstream の公開キャッシュに hit させる）は採らない。
  `herdr` には公開キャッシュが存在せず、`anime-games-launcher` も an-anime-team の公開キャッシュの有無が未確認のため、どのみち自分のキャッシュが要る。
  自分のキャッシュに 2 つとも入れる方が素直である。
- nightly 事前ウォーム（初回 CI も速くする）は採らない。
  public ランナーのビルドは無料のため、初回が遅いこと自体はコストにならず、労力に見合わない。

## 検証

- `narinfo` の 200 確認で、自分のキャッシュに `herdr`/`anime-games-launcher` が push されたことを確かめる（hyprland キャッシュで実施済みの手順と同じ）。
- Renovate PR、または `workflow_dispatch` で `build (nixos)` が 60 分以内に緑になることを確認する。
- ローカルで `flake.lock` 更新後に `nix run .#switch` し、2 つのパッケージがビルドされず substitute されることを確認する。

## ドキュメント更新

`.github/ci-dependencies.md` の §4（キャッシュ）と、`todo.md` の「Cachix による CI ビルドキャッシュの導入」を、本設計の実装後に完了として更新する。
