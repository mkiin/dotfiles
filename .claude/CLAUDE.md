# プロジェクトメモ（mkiin/dotfiles）

NixOS & home-manager の個人 dotfiles。

## 構成

- `nixosConfigurations.nixos` … 実機 NixOS（host: `nixos` / user: `mkiin`）
- `homeConfigurations."mkiin@wsl"` … WSL 上の home-manager

## ディレクトリ構成と分離ルール

レイヤーで最上位を分ける:

- `nixos/` … システム(NixOS module)。`core/`(boot/nix/users/locale/… 基盤) + `hardware/` + `desktop/`
- `home-manager/` … ユーザー。`cli/` + `editor/` + `ai/` + `desktop/`
- `hosts/` … ホスト単位のエントリ。imports 組み立て・`hardware-configuration.nix`・`home-manager.users` 配線・`stateVersion` のみ。実体設定は書かない
- `lib/` … flake ヘルパー(`makeNixosConfig` 等)と `treefmt/`
- `packages/` `scripts/` `hooks/` `images/` … 補助

守るルール:

1. **1 機能 = 1 ディレクトリ = 1 `default.nix`**。関連する設定ファイル(lua/conf/テンプレート)は同じディレクトリに同居(コロケーション)。ゲーム等の並列物は `desktop/games/<name>/` のように 1 つ下の階層で分ける。
2. **各階層の `default.nix` は `imports` 集約役**。ロジックは書かない。機能を足したら親の `default.nix` の imports に 1 行足すだけ。
3. **`packages.nix`** … 独立ディレクトリを作るほどでない、依存の薄いパッケージ束の置き場(`home-manager/{cli,desktop}/packages.nix`, `nixos/core/packages`)。
4. **system か user か**を先に決める。全体に効くもの(steam/ランチャー/フォント)は `nixos/`、ユーザー設定は `home-manager/`。本体=system・設定=user に割るものもある(例: vesktop)。
5. **ホスト差分は `hosts/` で吸収**。WSL は desktop を import しない等。共通は `nixos/`・`home-manager/` 側へ。

## コーディング規約

- **コメントをだらだら書くな**。何をしているかはコードで分かる。コメントは「なぜそうしたか(非自明な理由・ハマりどころ・外部制約)」だけを 1〜2 行で。
- `enable = true; # 有効化` のような逐条コメントや、設定項目を日本語で言い換えるだけのコメントは禁止。冗長なら消す。
- Nix の未使用 let 束縛は treefmt の deadnix が検出する。`nix run .#fmt -- --fail-on-change` を build と併せて必ず通す。

## ローカル用カスタムコマンド（flake apps）

リポジトリ直下で実行する。

| コマンド           | 内容                                                                             |
| ------------------ | -------------------------------------------------------------------------------- |
| `nix run .#update` | `nix flake update`（※ flake更新は基本 Bot 任せ。これは緊急/特定input強制更新用） |
| `nix run .#build`  | nixos 構成をビルドだけする（反映しない）。`nom` でログ整形                       |
| `nix run .#switch` | `sudo nixos-rebuild switch --flake .#nixos` で反映する                           |
| `nix run .#fmt`    | treefmt で整形（`--fail-on-change` で確認も可）                                  |

定義は `flake.nix` の `apps.${system}`。`build` / `switch` は実機 NixOS（`.#nixos`）向け。
WSL を反映するときは `nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl`。

## 運用モデル: Bot主導 / pull運用

flake の更新は **cron Bot に任せる**。Bot が main の `flake.lock` を更新し
（release-age 3日 + CIビルド緑のみマージ）、検証済みの lock だけが main に入る。

- **flake 更新**: 自分で `nix flake update` しない。Bot 任せ。`nix run .#update` は緊急時/特定input強制更新のみ。
- **ローカル反映**: `git pull && nix run .#switch` だけ。pull する lock は CI 検証済み。
- **設定変更（waybar 等）**: ローカルで `nix run .#build` で通してから push する。
  main 直 push は毎回 CI がフルビルドして遅いため、ローカル検証を先に。
- CI は後追いの保険。`concurrency: cancel-in-progress` で連続 push の古い実行は自動キャンセルされる。

## CI / 自動化

`.github/` の workflow・action の依存関係・ハマりどころは **`.github/ci-dependencies.md`** に詳細を記載。
要点だけ:

- flake input は cron（毎日 06:00 UTC）で自動更新 → PR 自動生成 → auto-merge。Bot は GitHub App。
- PR 作成には `dependencies` / `automated` ラベルが**実在**している必要がある（無いと `gh pr create` が exit 1）。
- auto-merge にはブランチ保護の必須チェック `lint` / `build (wsl-home)` / `build (nixos)` が全部緑である必要がある。
- hyprland は `cache.nixos.org` に無いため、`flake.nix` の `nixConfig` で `hyprland.cachix.org` を substituter に追加してある。外すと CI がソースビルドで 30 分タイムアウトする。
