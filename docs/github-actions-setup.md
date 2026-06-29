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
