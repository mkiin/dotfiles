# NixOS Steam 宣言的追加 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** NVIDIA GPU デスクトップ（`hosts/nixos`）で Steam を `programs.steam.enable` により宣言的に有効化する。

**Architecture:** 既存の機能別ディレクトリモジュールパターン（例: `nixos/desktop/vesktop`）に従い、`nixos/desktop/steam/default.nix` を新規作成し、`nixos/desktop/default.nix` の `imports` に追加する。`environment.systemPackages` への単純追加ではなく NixOS の `programs.steam` モジュールを使う（FHS ランタイムと 32bit グラフィックスライブラリ連携を自動構成するため）。

**Tech Stack:** Nix flakes, NixOS modules

## Global Constraints

- 対象 flake attribute: `nixosConfigurations.nixos`
- ビルド検証コマンド: `nixos-rebuild build --flake .#nixos`（再起動不要、評価＋ビルドのみ）
- `nixpkgs.config.allowUnfree = true` は `lib/default.nix` で設定済み（変更不要）
- `hardware.graphics.enable` / `hardware.graphics.enable32Bit = true` は `nixos/hardware/default.nix` で設定済み（変更不要）
- 既存モジュールの記法に合わせる: 引数は `{ ... }:`、属性は 2 スペースインデント
- スコープ外（追加しない）: gamescope, gamemode, Proton-GE, ファイアウォール開放

---

### Task 1: Steam モジュールの作成と有効化

**Files:**

- Create: `nixos/desktop/steam/default.nix`
- Modify: `nixos/desktop/default.nix`（`imports` リストに `./steam` を追加）

**Interfaces:**

- Consumes: なし（`programs.steam` は NixOS 標準モジュール）
- Produces: `nixos/desktop/default.nix` が `./steam` を import し、`programs.steam.enable = true` がシステム構成に反映される

- [ ] **Step 1: 検証 — 変更前にベースラインのビルドが通ることを確認**

Run: `nixos-rebuild build --flake .#nixos`
Expected: ビルド成功（既存構成が正常であることのベースライン確認）

- [ ] **Step 2: Steam モジュールファイルを作成**

Create `nixos/desktop/steam/default.nix`:

```nix
{ ... }:
{
  programs.steam.enable = true;
}
```

- [ ] **Step 3: desktop の imports に steam を追加**

Modify `nixos/desktop/default.nix` の `imports` リストに `./steam` を追加する。変更後の内容:

```nix
{ ... }:
{
  imports = [
    ./hyprland
    ./display-manager
    ./fcitx5
    ./sound
    ./polkit
    ./vesktop
    ./steam
  ];
}
```

- [ ] **Step 4: 検証 — Steam を含めた構成のビルドが通ることを確認**

Run: `nixos-rebuild build --flake .#nixos`
Expected: ビルド成功（`programs.steam` モジュールが評価され、Steam パッケージと FHS ランタイムが構成に含まれる）

- [ ] **Step 5: 検証 — Steam パッケージが構成に含まれることを確認**

Run: `nix eval .#nixosConfigurations.nixos.config.programs.steam.enable`
Expected: `true`
（注: `--raw` は文字列専用のため bool 値ではエラーになる。`--raw` なしで評価する）

- [ ] **Step 6: Commit**

```bash
git add nixos/desktop/steam/default.nix nixos/desktop/default.nix
git commit -m "feat(steam): NixOSにSteamを宣言的に追加"
```

---

## 適用（手動・任意）

ビルド検証が通った後、実際にシステムへ反映するには以下を実行する（このプランのタスク完了条件ではない）:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

反映後、アプリケーションメニューまたは `steam` コマンドから起動できることを確認する。

## Self-Review

- **Spec coverage:** 設計の新規ファイル（Task 1 Step 2）、imports 変更（Step 3）、前提充足の確認（Global Constraints）、検証（Step 4-5）をすべてカバー。スコープ外項目も Global Constraints に明記。
- **Placeholder scan:** プレースホルダなし。全ステップに実コード・実コマンド・期待出力を記載。
- **Type consistency:** モジュール名 `./steam`、属性 `programs.steam.enable` は全ステップで一貫。
