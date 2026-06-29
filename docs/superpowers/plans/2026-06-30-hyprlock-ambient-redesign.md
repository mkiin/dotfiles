# hyprlock Ambient リファクタ Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** hyprlock ロック画面を Ambient（写真主役・極小 UI・非対称）方向にリファクタし、背景を専用固定画像（ぼかし無し）に、日付を英語表記に、色を固定画像由来の役割ベーストークンに、出現アニメーションを追加する。

**Architecture:** hyprlock の設定は `home-manager/desktop/hyprland/hyprlock.conf` を `lnk`（リポジトリ作業ツリーへのシンボリックリンク）で `~/.config/hypr/hyprlock.conf` に配置している。色は従来 matugen が現在の壁紙から `colors.conf` を生成していたが、これを廃し、固定背景画像から matugen で一度だけ生成した静的 `lock-colors.conf` をコミットして使う。`colors.conf` は hyprlock 専用と確認済みのため他機能に影響しない。

**Tech Stack:** Nix（home-manager / NixOS flake）、hyprlock v0.9.5、matugen、bash。

## Global Constraints

- `lnk` の挙動: 内容編集は即時反映。**新規 `lnk` エントリ追加・新規ファイル参照は git 追跡（`git add`）＋ `nixos-rebuild` が必要**（flake は git 追跡ファイルのみ参照）。
- 対象ホストは `nixos`（デスクトップ）。適用は `sudo nixos-rebuild switch --flake .#nixos`、評価チェックは `nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath`。
- 作業は git worktree 内で行う（実行時に `superpowers:using-git-worktrees` で作成済みのこと）。
- 日付は英語固定: `LC_ALL=C` を必ず付与。形式は `%B %-d, %Y`（例 `June 30, 2026`）。
- ロック画面で使う色トークンはすべて `$lock_*` 命名。hyprlock.conf で参照する `$lock_*` は必ず `lock-colors.conf` に定義が存在すること。
- matugen テンプレート構文は既存テンプレート（`{{colors.<name>.default.hex_stripped}}`）に合わせる。

## File Structure

- `home-manager/desktop/matugen/templates/lock-colors.conf` — 新規。固定画像から `$lock_*` トークンを生成する matugen テンプレート。
- `home-manager/desktop/hyprland/lock-colors.conf` — 新規。matugen 生成物（コミット対象）。画像未生成時のフォールバック既定値を初期コミット。
- `home-manager/desktop/hyprland/scripts/gen-lock-colors.sh` — 新規。`lock.png` から `lock-colors.conf` を再生成する手動スクリプト（`hypr/scripts` ディレクトリは一括 `lnk` 済みのため新規 lnk 不要）。
- `home-manager/desktop/hyprland/hyprlock.conf` — 改修。Ambient レイアウト・背景・日付・animations・`$lock_*` 参照・source 差し替え。
- `home-manager/desktop/hyprland/lock.png` — 新規（ユーザー配置の固定背景画像）。
- `home-manager/desktop/hyprland/default.nix` — 改修。`lock.png` / `lock-colors.conf` の lnk 追加。
- `home-manager/desktop/matugen/default.nix` — 改修。旧 hyprlock テンプレート lnk 削除。
- `home-manager/desktop/matugen/config.toml` — 改修。`[templates.hyprlock]` 削除。
- `home-manager/desktop/matugen/templates/hyprlock-colors.conf` — 削除。

---

## Task 1: lock カラートークン（テンプレート＋フォールバック既定値）

**Files:**

- Create: `home-manager/desktop/matugen/templates/lock-colors.conf`
- Create: `home-manager/desktop/hyprland/lock-colors.conf`

**Interfaces:**

- Produces: 役割ベーストークン群 `$lock_clock`, `$lock_date`, `$lock_shadow`, `$lock_input_outline`, `$lock_input_bg`, `$lock_input_text`, `$lock_hint`, `$lock_success`, `$lock_fail`（Task 3 の hyprlock.conf がこれらを参照）。

- [ ] **Step 1: matugen テンプレートを作成**

`home-manager/desktop/matugen/templates/lock-colors.conf`:

```ini
# hyprlock 専用カラートークン（役割ベース）。
# scripts/gen-lock-colors.sh が lock.png からこのテンプレートを描画して
# home-manager/desktop/hyprland/lock-colors.conf を生成する。
$lock_clock         = rgba({{colors.primary.default.hex_stripped}}f2)
$lock_date          = rgba({{colors.primary_fixed.default.hex_stripped}}e6)
$lock_shadow        = rgba(11111baa)
$lock_input_outline = rgba({{colors.primary_container.default.hex_stripped}}d9)
$lock_input_bg      = rgba({{colors.surface.default.hex_stripped}}bf)
$lock_input_text    = rgba({{colors.on_surface.default.hex_stripped}}ff)
$lock_hint          = rgba({{colors.on_surface.default.hex_stripped}}80)
$lock_success       = rgba(a6e3a1e6)
$lock_fail          = rgba(f38ba8e6)
```

- [ ] **Step 2: フォールバック既定値の lock-colors.conf を作成**

`home-manager/desktop/hyprland/lock-colors.conf`（画像未生成時でも hyprlock が source できるよう静的既定値で初期化）:

```ini
# ロック画面専用カラートークン（役割ベース）。
# 通常は scripts/gen-lock-colors.sh が lock.png から再生成する。
# 以下は画像未生成時のフォールバック既定値。
$lock_clock         = rgba(cdd6f4f2)
$lock_date          = rgba(bac2dee6)
$lock_shadow        = rgba(11111baa)
$lock_input_outline = rgba(89b4fad9)
$lock_input_bg      = rgba(1e1e2ebf)
$lock_input_text    = rgba(cdd6f4ff)
$lock_hint          = rgba(a6adc880)
$lock_success       = rgba(a6e3a1e6)
$lock_fail          = rgba(f38ba8e6)
```

- [ ] **Step 3: 全トークンが定義されているか検証**

Run:

```bash
for t in lock_clock lock_date lock_shadow lock_input_outline lock_input_bg lock_input_text lock_hint lock_success lock_fail; do
  grep -q "^\$$t " home-manager/desktop/hyprland/lock-colors.conf && echo "OK $t" || echo "MISSING $t"
done
```

Expected: 9 行すべて `OK`。

- [ ] **Step 4: コミット**

```bash
git add home-manager/desktop/matugen/templates/lock-colors.conf home-manager/desktop/hyprland/lock-colors.conf
git commit -m "feat(hyprlock): add role-based lock color tokens (template + fallback)"
```

---

## Task 2: パレット生成スクリプト

**Files:**

- Create: `home-manager/desktop/hyprland/scripts/gen-lock-colors.sh`

**Interfaces:**

- Consumes: Task 1 のテンプレート `matugen/templates/lock-colors.conf`、Task 4 で配置される `hyprland/lock.png`。
- Produces: `home-manager/desktop/hyprland/lock-colors.conf` を上書き生成するコマンド（Task 4 が実行）。

- [ ] **Step 1: スクリプトを作成**

`home-manager/desktop/hyprland/scripts/gen-lock-colors.sh`:

```bash
#!/usr/bin/env bash
# lock.png から hyprlock 専用カラーパレット (lock-colors.conf) を再生成する。
# Ambient ロック画面の固定背景画像に調和した色を matugen で生成し、
# リポジトリ内の生成物を上書きする。生成後は git diff を確認してコミットすること。
# 使い方: dotfiles リポジトリ内で実行する。
#   ./home-manager/desktop/hyprland/scripts/gen-lock-colors.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
IMG="$ROOT/home-manager/desktop/hyprland/lock.png"
TEMPLATE="$ROOT/home-manager/desktop/matugen/templates/lock-colors.conf"
OUT="$ROOT/home-manager/desktop/hyprland/lock-colors.conf"

if [[ ! -f "$IMG" ]]; then
  echo "error: lock image not found: $IMG" >&2
  echo "先に lock.png を配置してください。" >&2
  exit 1
fi

TMPCONF="$(mktemp --suffix=.toml)"
trap 'rm -f "$TMPCONF"' EXIT
cat >"$TMPCONF" <<EOF
[templates.lock]
input_path = "$TEMPLATE"
output_path = "$OUT"
EOF

matugen image "$IMG" --config "$TMPCONF" --mode dark --source-color-index 0
echo "generated: $OUT"
echo "git diff で確認してコミットしてください。"
```

- [ ] **Step 2: 実行権限を付与**

Run: `chmod +x home-manager/desktop/hyprland/scripts/gen-lock-colors.sh`

- [ ] **Step 3: 構文チェック**

Run: `bash -n home-manager/desktop/hyprland/scripts/gen-lock-colors.sh && echo SYNTAX_OK`
Expected: `SYNTAX_OK`

- [ ] **Step 4: 画像未配置時のエラーハンドリングを確認**

Run: `home-manager/desktop/hyprland/scripts/gen-lock-colors.sh; echo "exit=$?"`
Expected: `error: lock image not found:` を含むメッセージが stderr に出て `exit=1`（lock.png は Task 4 まで未配置のため）。

- [ ] **Step 5: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/gen-lock-colors.sh
git commit -m "feat(hyprlock): add gen-lock-colors.sh palette generator"
```

---

## Task 3: hyprlock.conf を Ambient レイアウトへ書き換え

**Files:**

- Modify: `home-manager/desktop/hyprland/hyprlock.conf`（全面書き換え）

**Interfaces:**

- Consumes: Task 1 の `$lock_*` トークン、`~/.config/hypr/lock.png`（Task 5 でリンク）、`~/.config/hypr/lock-colors.conf`（Task 5 でリンク）。

- [ ] **Step 1: hyprlock.conf を Ambient 構成で全面書き換え**

`home-manager/desktop/hyprland/hyprlock.conf` の内容を以下で置き換える:

```ini
source = ~/.config/hypr/lock-colors.conf

general {
    hide_cursor = false
    ignore_empty_input = true
}

animations {
    enabled = true
    bezier = lockEase, 0.25, 1, 0.5, 1
    animation = fadeIn, 1, 5, lockEase
    animation = fadeOut, 1, 4, lockEase
    animation = inputFieldDots, 1, 3, default
    animation = inputFieldColors, 1, 4, default
    animation = inputFieldFade, 1, 4, default
}

background {
    monitor =
    path = ~/.config/hypr/lock.png
    blur_passes = 0
    brightness = 0.8
    contrast = 1.0
}

# --- 左上クラスタ: 時刻・日付（写真上でも読めるよう text shadow） ---
label {
    monitor =
    text = cmd[update:60000] echo "$(date +"%H:%M")"
    color = $lock_clock
    font_size = 64
    font_family = JetBrainsMono Nerd Font ExtraBold
    position = 60, -60
    halign = left
    valign = top
    shadow_passes = 3
    shadow_size = 4
    shadow_color = $lock_shadow
    shadow_boost = 1.2
}

label {
    monitor =
    text = cmd[update:60000] echo "$(LC_ALL=C date +'%B %-d, %Y')"
    color = $lock_date
    font_size = 18
    font_family = JetBrainsMono Nerd Font Bold
    position = 62, -150
    halign = left
    valign = top
    shadow_passes = 3
    shadow_size = 3
    shadow_color = $lock_shadow
    shadow_boost = 1.2
}

# --- 中央〜やや下クラスタ: アバター・入力欄・ヒント ---
image {
    monitor =
    path = ~/.face.icon
    border_color = $lock_input_outline
    border_size = 2
    size = 80
    rounding = -1
    rotate = 0
    reload_time = -1
    position = 0, 60
    halign = center
    valign = center
}

input-field {
    monitor =
    size = 300, 56
    outline_thickness = 2
    dots_size = 0.25
    dots_spacing = 0.3
    dots_center = true
    dots_rounding = -1
    outer_color = $lock_input_outline
    inner_color = $lock_input_bg
    font_color = $lock_input_text
    fade_on_empty = true
    fade_timeout = 1000
    font_family = JetBrainsMono Nerd Font
    placeholder_text = <i>Enter password...</i>
    hide_input = false
    check_color = $lock_success
    fail_color = $lock_fail
    fail_text = <i>$FAIL <b>($ATTEMPTS)</b></i>
    rounding = -1
    position = 0, -40
    halign = center
    valign = center
}

label {
    monitor =
    text = Type to unlock
    color = $lock_hint
    font_size = 13
    font_family = JetBrainsMono Nerd Font
    position = 0, -110
    halign = center
    valign = center
}
```

- [ ] **Step 2: 旧トークンの残存が無いか確認**

Run: `grep -nE '\$(primary|tertiary|surface|on_surface|state_)' home-manager/desktop/hyprland/hyprlock.conf; echo "exit=$?"`
Expected: 一致なし（`exit=1`）。旧 `$primary_a95` 等が残っていないこと。

- [ ] **Step 3: 参照トークンがすべて定義済みか相互チェック**

Run:

```bash
for t in $(grep -oE '\$lock_[a-z_]+' home-manager/desktop/hyprland/hyprlock.conf | sort -u | sed 's/^\$//'); do
  grep -q "^\$$t " home-manager/desktop/hyprland/lock-colors.conf && echo "OK $t" || echo "MISSING $t"
done
```

Expected: すべて `OK`（`MISSING` が一つも無い）。

- [ ] **Step 4: 日付・背景・アニメの要点を確認**

Run: `grep -nE "LC_ALL=C|blur_passes = 0|brightness = 0.8|fadeIn|fade_on_empty = true" home-manager/desktop/hyprland/hyprlock.conf`
Expected: `LC_ALL=C`、`blur_passes = 0`、`brightness = 0.8`、`fadeIn`、`fade_on_empty = true` の各行が表示される。

- [ ] **Step 5: コミット**

```bash
git add home-manager/desktop/hyprland/hyprlock.conf
git commit -m "feat(hyprlock): Ambient layout, fixed bg, english date, animations"
```

---

## Task 4: 固定背景画像を配置しパレットを再生成

**Files:**

- Create: `home-manager/desktop/hyprland/lock.png`（ユーザー配置）
- Modify: `home-manager/desktop/hyprland/lock-colors.conf`（再生成で上書き）

**Interfaces:**

- Consumes: Task 2 の `gen-lock-colors.sh`、Task 1 のテンプレート。
- Produces: 固定画像由来の `lock-colors.conf`（Task 5 でリンクされ hyprlock が source）。

- [ ] **Step 1: ロック画面用の固定画像を配置**

ロック画面に使いたい画像を `home-manager/desktop/hyprland/lock.png` として配置する（PNG。横長・適度に暗め/低コントラストだと Ambient で映える）。例:

```bash
cp /path/to/your/wallpaper.png home-manager/desktop/hyprland/lock.png
```

> 注: この画像はユーザーが用意する。配置されるまで Task 5 の `nix eval` は失敗する（flake が参照できないため）。

- [ ] **Step 2: 画像を git 追跡に追加**

Run: `git add home-manager/desktop/hyprland/lock.png && git status --short home-manager/desktop/hyprland/lock.png`
Expected: `A  home-manager/desktop/hyprland/lock.png` が表示される。

- [ ] **Step 3: パレットを再生成**

Run: `home-manager/desktop/hyprland/scripts/gen-lock-colors.sh`
Expected: `generated: .../home-manager/desktop/hyprland/lock-colors.conf` が表示され、エラー無く終了する。

- [ ] **Step 4: 生成結果がトークンを維持しているか確認**

Run:

```bash
for t in lock_clock lock_date lock_shadow lock_input_outline lock_input_bg lock_input_text lock_hint lock_success lock_fail; do
  grep -q "^\$$t " home-manager/desktop/hyprland/lock-colors.conf && echo "OK $t" || echo "MISSING $t"
done
```

Expected: 9 行すべて `OK`（テンプレート由来のトークンが欠けていないこと）。

- [ ] **Step 5: コミット**

```bash
git add home-manager/desktop/hyprland/lock.png home-manager/desktop/hyprland/lock-colors.conf
git commit -m "feat(hyprlock): add fixed lock image and generated palette"
```

---

## Task 5: Nix 配線とクリーンアップ

**Files:**

- Modify: `home-manager/desktop/hyprland/default.nix`
- Modify: `home-manager/desktop/matugen/default.nix`
- Modify: `home-manager/desktop/matugen/config.toml`
- Delete: `home-manager/desktop/matugen/templates/hyprlock-colors.conf`

**Interfaces:**

- Consumes: Task 4 で git 追跡された `lock.png` / `lock-colors.conf`。

- [ ] **Step 1: hyprland/default.nix に lnk エントリを追加**

`home-manager/desktop/hyprland/default.nix` の `xdg.configFile` ブロック、`"hypr/hyprlock.conf"` 行の直後に追加:

```nix
    "hypr/hyprlock.conf".source = lnk ./hyprlock.conf;
    "hypr/lock-colors.conf".source = lnk ./lock-colors.conf;
    "hypr/lock.png".source = lnk ./lock.png;
```

- [ ] **Step 2: matugen/default.nix から旧 hyprlock テンプレート行を削除**

`home-manager/desktop/matugen/default.nix` から次の行を削除:

```nix
    "matugen/templates/hyprlock-colors.conf".source = lnk ./templates/hyprlock-colors.conf;
```

- [ ] **Step 3: config.toml から `[templates.hyprlock]` を削除**

`home-manager/desktop/matugen/config.toml` から次のブロックを削除:

```toml
[templates.hyprlock]
input_path = "~/.config/matugen/templates/hyprlock-colors.conf"
output_path = "~/.config/hypr/colors.conf"
```

- [ ] **Step 4: 旧テンプレートファイルを削除**

Run: `git rm home-manager/desktop/matugen/templates/hyprlock-colors.conf`
Expected: `rm 'home-manager/desktop/matugen/templates/hyprlock-colors.conf'`

- [ ] **Step 5: flake 評価チェック**

Run: `nix eval .#nixosConfigurations.nixos.config.system.build.toplevel.drvPath`
Expected: エラー無く store path（`/nix/store/...-nixos-system-....drv`）が表示される。`lnk ./lock.png` / `lnk ./lock-colors.conf` が解決でき、削除した参照が残っていないこと。

> 失敗時のチェック: `lock.png` と `lock-colors.conf` が git 追跡済みか（Task 4 Step 2/5）、default.nix / config.toml の編集に typo が無いかを確認する。

- [ ] **Step 6: 適用して hyprlock を実機確認**

Run: `sudo nixos-rebuild switch --flake .#nixos`
Then: `hyprlock`（別端末から確認、解除はパスワード入力）。

確認項目:

- 背景が `lock.png` で表示され、ぼかしが無い（写真が主役の明るさ）。
- 左上に時刻（大）と日付。日付が `June 30, 2026` 形式の英語表記。
- 挨拶メッセージが無い。アバターと「Type to unlock」がある。
- 入力欄は空欄時に控えめ、タイプ開始でフェードして出現。
- ロック出現時にフェードイン、解除時にフェードアウト。

- [ ] **Step 7: コミット**

```bash
git add home-manager/desktop/hyprland/default.nix home-manager/desktop/matugen/default.nix home-manager/desktop/matugen/config.toml
git commit -m "chore(hyprlock): wire lock image/palette links, drop live colors.conf template"
```

---

## Self-Review

- **Spec coverage**:
  - 日付英語化 → Task 3（`LC_ALL=C` + `%B %-d, %Y`）。
  - カラートークン見直し（役割ベース）→ Task 1 / Task 3。
  - 専用固定画像・ぼかし無し → Task 3（background）/ Task 4（画像）/ Task 5（リンク）。
  - 固定画像から matugen 生成・生成→コミット・手動トリガー → Task 1（テンプレート）/ Task 2（スクリプト）/ Task 4（生成）。
  - Ambient レイアウト（左上時刻・極小 UI・挨拶削除・アバター/ヒント残す）→ Task 3。
  - 可読性（brightness 控えめ + text shadow）→ Task 3。
  - アニメーション（fadeIn/Out + 入力欄 + fade_on_empty）→ Task 3。
  - クリーンアップ（`[templates.hyprlock]` 削除・旧テンプレ削除）→ Task 5。
  - worktree 作業 → Global Constraints。
- **Placeholder scan**: プレースホルダ無し。全コード・全コマンドを明示。
- **Type consistency**: `$lock_*` トークン 9 個は Task 1（テンプレ＋フォールバック）と Task 3（参照）で一致。`lock-colors.conf` / `lock.png` のパス、`gen-lock-colors.sh` の入出力パスは全タスクで一致。
