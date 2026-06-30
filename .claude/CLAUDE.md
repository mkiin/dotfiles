# プロジェクトメモ（mkiin/dotfiles）

NixOS & home-manager の個人 dotfiles。

## 構成

- `nixosConfigurations.nixos` … 実機 NixOS（host: `nixos` / user: `mkiin`）
- `homeConfigurations."mkiin@wsl"` … WSL 上の home-manager

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

## 運用モデル: A（Bot主導 / pull運用）

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
