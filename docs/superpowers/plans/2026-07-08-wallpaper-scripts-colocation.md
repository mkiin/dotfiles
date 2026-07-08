# hyprlock 関連ファイルのコロケーション整理 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** lock 専用スクリプト 4 本を `hyprland/scripts/lock/` に区画整理し、matugen 側の迷子テンプレートを hyprlock 機能側へ引っ越し、壁紙変更手順をコメントで明文化する。

**Architecture:** `~/.config/hypr/scripts` はディレクトリごと lnk 済みのため、サブディレクトリ `lock/` の新設は Nix 変更なしでライブ反映される。`hyprlock.conf` の cmd パスだけ `scripts/lock/` へ更新する。テンプレートは生成物・消費者と同じ `hyprland/` 直下に置き、`gen-lock-colors.sh` の参照パスを更新する。

**Tech Stack:** git mv / bash / hyprlock v0.9.5 / NixOS home-manager（`lnk`）。

**Spec:** `docs/superpowers/specs/2026-07-08-wallpaper-scripts-colocation-design.md`

## Global Constraints

- `images/`・`hyprland/default.nix`・`matugen/default.nix`・regreet・root `scripts/` は**変更しない**。
- switch 系スクリプトは**作らない**（quickshell UI 設計時に保留）。
- 検証は `nix run .#build` と `nix run .#fmt -- --fail-on-change` を必ず通す。
- `lock-preview.sh` の実行は数秒間実際に画面をロックする（自動解除）。
- 移動は `git mv` で行い、履歴の追跡性を保つ。

---

## Task 1: `hyprland/scripts/lock/` への区画整理

**Files:**

- Move: `home-manager/desktop/hyprland/scripts/{lock-clock,gen-lock-colors,gen-lock-scrim,lock-preview}.sh` → `home-manager/desktop/hyprland/scripts/lock/`
- Modify: `home-manager/desktop/hyprland/hyprlock.conf`（cmd パス 2 箇所）

**Interfaces:**

- Produces: ランタイムパス `~/.config/hypr/scripts/lock/lock-clock.sh`（hyprlock.conf が参照）。リポジトリパス `home-manager/desktop/hyprland/scripts/lock/{gen-lock-colors,gen-lock-scrim,lock-preview}.sh`（人間が実行）。

- [ ] **Step 1: サブディレクトリを作って 4 本を git mv**

```bash
cd home-manager/desktop/hyprland/scripts
mkdir lock
git mv lock-clock.sh gen-lock-colors.sh gen-lock-scrim.sh lock-preview.sh lock/
cd -
```

- [ ] **Step 2: hyprlock.conf の cmd パスを更新**

`home-manager/desktop/hyprland/hyprlock.conf` の 2 箇所を置換する。

変更前（time / date の 2 行）:

```ini
    text = cmd[update:10000] ~/.config/hypr/scripts/lock-clock.sh time "$lock_hour" "$lock_colon" "$lock_minute" "$lock_ampm"
    text = cmd[update:10000] ~/.config/hypr/scripts/lock-clock.sh date "$lock_month" "$lock_day" "$lock_weekday"
```

変更後:

```ini
    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh time "$lock_hour" "$lock_colon" "$lock_minute" "$lock_ampm"
    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh date "$lock_month" "$lock_day" "$lock_weekday"
```

- [ ] **Step 3: lnk 経由で新パスが解決できることを確認**

Run: `readlink -f ~/.config/hypr/scripts/lock/lock-clock.sh`
Expected: `.../dotfiles/home-manager/desktop/hyprland/scripts/lock/lock-clock.sh`

Run: `grep -c 'scripts/lock/lock-clock.sh' home-manager/desktop/hyprland/hyprlock.conf`
Expected: `2`

- [ ] **Step 4: ロック画面の動作確認（数秒画面がロックされる）**

Run: `./home-manager/desktop/hyprland/scripts/lock/lock-preview.sh /tmp/colocation-check.png "3480,0 1000x500"`
撮影画像に時計・日付が描画されていること（= 新パスの lock-clock.sh が呼べている）。`$lock_hour` の生表示や空ラベルが出ていたらパス解決失敗。

- [ ] **Step 5: コミット**

```bash
git add -A home-manager/desktop/hyprland/scripts home-manager/desktop/hyprland/hyprlock.conf
git commit -m "refactor(hyprlock): lock 専用スクリプトを scripts/lock/ に区画整理"
```

---

## Task 2: 迷子テンプレートの引っ越しとワークフロー明文化

**Files:**

- Move: `home-manager/desktop/matugen/templates/lock-colors.conf` → `home-manager/desktop/hyprland/lock-colors.template.conf`
- Modify: `home-manager/desktop/hyprland/scripts/lock/gen-lock-colors.sh`（`TEMPLATE` パスとヘッダコメント）

**Interfaces:**

- Consumes: Task 1 の移動後パス。
- Produces: `hyprland/lock-colors.template.conf`（gen-lock-colors.sh の入力）。

- [ ] **Step 1: git mv でテンプレートを移動**

```bash
git mv home-manager/desktop/matugen/templates/lock-colors.conf \
       home-manager/desktop/hyprland/lock-colors.template.conf
```

- [ ] **Step 2: テンプレートのヘッダコメントを更新**

`home-manager/desktop/hyprland/lock-colors.template.conf` の先頭 3 行コメントを以下へ置換:

```ini
# hyprlock 専用カラートークン（役割ベース）の matugen テンプレート。
# scripts/lock/gen-lock-colors.sh が images/lock/lock.jpg からこれを描画して
# 同ディレクトリの lock-colors.conf（hyprlock.conf が source する生成物）を上書きする。
```

- [ ] **Step 3: gen-lock-colors.sh のパスとヘッダを更新**

`home-manager/desktop/hyprland/scripts/lock/gen-lock-colors.sh` を修正する。

`TEMPLATE` 行の変更前:

```bash
TEMPLATE="$ROOT/home-manager/desktop/matugen/templates/lock-colors.conf"
```

変更後:

```bash
TEMPLATE="$ROOT/home-manager/desktop/hyprland/lock-colors.template.conf"
```

ヘッダコメント（先頭 6 行）を以下へ置換し、壁紙変更手順を明文化する:

```bash
#!/usr/bin/env bash
# lock.jpg から hyprlock 専用カラーパレット (lock-colors.conf) を再生成する。
# 【lock 壁紙の変更手順】
#   1. images/lock/lock.jpg を差し替える（参照名は lnk と hyprlock.conf で固定）
#   2. このスクリプトを実行して色トークンを再生成する
#   3. lock.jpg と lock-colors.conf をコミットする
# scrim (lock-scrim.png) は壁紙非依存なので再生成不要。反映は lnk のライブ反映のみで
# nixos-rebuild は不要。テンプレートは同階層の lock-colors.template.conf。
# 使い方: dotfiles リポジトリ内で実行する。
#   ./home-manager/desktop/hyprland/scripts/lock/gen-lock-colors.sh
```

（既存の `set -euo pipefail` 以降のロジックは変更しない。）

- [ ] **Step 4: 冪等再生成で検証**

Run: `./home-manager/desktop/hyprland/scripts/lock/gen-lock-colors.sh`
Expected: `generated: .../lock-colors.conf` と表示。

Run: `git diff --stat home-manager/desktop/hyprland/lock-colors.conf`
Expected: 出力なし（現行と同一 = 冪等）。差分が出たら matugen のバージョン差等を調査し、原因を確認してからコミット可否を判断する。

Run: `ls home-manager/desktop/matugen/templates/`
Expected: `lock-colors.conf` が無い（matugen ランタイム用のみ）。

- [ ] **Step 5: コミット**

```bash
git add -A home-manager/desktop/matugen/templates home-manager/desktop/hyprland
git commit -m "refactor(hyprlock): 色テンプレートを matugen から hyprlock 側へ移設し手順を明文化"
```

---

## Task 3: 統合検証

**Files:** （変更なし。検証のみ）

- [ ] **Step 1: Nix 評価と整形**

Run: `nix run .#build`
Expected: エラーなく完了（lnk パスがすべて解決）。

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで成功。差分が出たら `nix run .#fmt` で整形し、該当タスクのコミットへ amend せず追加コミットする。

- [ ] **Step 2: 旧パスの参照が残っていないことを確認**

Run: `grep -rn 'scripts/lock-clock.sh\|scripts/gen-lock-colors.sh\|scripts/gen-lock-scrim.sh\|scripts/lock-preview.sh\|matugen/templates/lock-colors' --include='*.nix' --include='*.conf' --include='*.sh' --include='*.toml' home-manager/ nixos/ flake.nix lib/`
Expected: 出力なし（docs/ 配下の過去ドキュメントは対象外 = 履歴として残す）。

---

## Self-Review

**Spec coverage:** 区画整理（設計1）→ Task 1 / テンプレート引っ越し（設計2）→ Task 2 / ワークフロー明文化（設計3）→ Task 2 Step 3 / switch 不作成（設計4）→ Global Constraints / 受け入れ基準 → Task 1 Step 3-4・Task 2 Step 4・Task 3。

**Placeholder scan:** 未確定値なし。

**Type consistency:** 新パス `scripts/lock/...` は Task 1（移動・conf 更新）と Task 2（gen 実行・コメント）で一致。テンプレート名 `lock-colors.template.conf` は Task 2 内で一貫。
