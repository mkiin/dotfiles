# hyprlock ポスター時計 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ロック画面の時計を「左下ポスター型」（Anton 極太 2 トーン時刻 + 大文字フルスペル日付）へ刷新する。

**Architecture:** 時刻・日付の 2 ラベルを `halign=left, valign=bottom` の同一 x に積む自己整列構成。縦棒 shape は削除。scrim は生成スクリプトの焦点を左下角に変えて再利用。色は matugen トークンを再設計して追従性を維持。

**Tech Stack:** hyprlock v0.9.5 / Anton（google-fonts）/ Pango markup / matugen / ImageMagick（`nix run`）。

**Spec:** `docs/superpowers/specs/2026-07-09-hyprlock-poster-clock-design.md`

## Global Constraints

- フォント宣言は `nixos/core/fonts/default.nix` のみ（集約点）。他のパッケージ追加なし。
- `~/.config/hypr/*` は lnk ライブ反映。`nix run .#switch` が必要なのは **Anton 追加時の 1 回だけ**。
- 検証は `nix run .#build` と `nix run .#fmt -- --fail-on-change`。見た目は `scripts/lock/lock-preview.sh`（数秒ロックされる）。
- Pango span の `size`/`letter_spacing`/`rise` は pt×1024。色 `rgba(rrggbbaa)` は引数ダブルクォート必須。
- 入力欄・背景・アニメーションは変更しない。

---

## Task 1: Anton フォント追加

**Files:**

- Modify: `nixos/core/fonts/default.nix`

- [ ] **Step 1: fonts.packages に Anton を追加**

`inter` の行の直後に追加:

```nix
    (google-fonts.override { fonts = [ "Anton" ]; })
```

- [ ] **Step 2: ビルドと反映**

Run: `nix run .#build`
Expected: 成功。

Run: `nix run .#switch`
Expected: 成功。

- [ ] **Step 3: フォント認識を確認**

Run: `fc-list | grep -i anton`
Expected: `Anton` の行が出る（family 名 `Anton`）。

- [ ] **Step 4: コミット**

```bash
git add nixos/core/fonts/default.nix
git commit -m "feat(fonts): ポスター時計用に Anton を追加"
```

---

## Task 2: 色トークン再設計と再生成

**Files:**

- Modify: `home-manager/desktop/hyprland/lock-colors.template.conf`
- Regenerate: `home-manager/desktop/hyprland/lock-colors.conf`

**Interfaces:**

- Produces: `$lock_hour`(on_surface 100%) `$lock_colon`(primary 80%) `$lock_minute`(primary 100%) `$lock_ampm`(on_surface 60%) `$lock_date`(on_surface 90%) + 既存維持分。`$lock_divider/month/day/weekday` は廃止。

- [ ] **Step 1: テンプレートのトークン部を書き換え**

`lock-colors.template.conf` の `$lock_*` 定義を以下で全置換（先頭コメント 1 行は維持）:

```ini
$lock_hour          = rgba({{colors.on_surface.default.hex_stripped}}ff)
$lock_colon         = rgba({{colors.primary.default.hex_stripped}}cc)
$lock_minute        = rgba({{colors.primary.default.hex_stripped}}ff)
$lock_ampm          = rgba({{colors.on_surface.default.hex_stripped}}99)
$lock_date          = rgba({{colors.on_surface.default.hex_stripped}}e6)
$lock_shadow        = rgba(11111baa)
$lock_input_outline = rgba({{colors.primary_container.default.hex_stripped}}d9)
$lock_input_bg      = rgba({{colors.surface.default.hex_stripped}}bf)
$lock_input_text    = rgba({{colors.on_surface.default.hex_stripped}}ff)
$lock_hint          = rgba({{colors.on_surface.default.hex_stripped}}80)
$lock_success       = rgba(a6e3a1e6)
$lock_fail          = rgba(f38ba8e6)
```

- [ ] **Step 2: 再生成と検証**

Run: `./home-manager/desktop/hyprland/scripts/lock/gen-lock-colors.sh`
Run: `grep -cE '^\$lock_(divider|month|day|weekday)' home-manager/desktop/hyprland/lock-colors.conf`
Expected: `0`

Run: `grep -cE '^\$lock_date ' home-manager/desktop/hyprland/lock-colors.conf`
Expected: `1`

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/hyprland/lock-colors.template.conf home-manager/desktop/hyprland/lock-colors.conf
git commit -m "feat(hyprlock): ポスター時計向けに色トークンを再設計"
```

---

## Task 3: lock-clock.sh をポスター構成へ改修

**Files:**

- Modify: `home-manager/desktop/hyprland/scripts/lock/lock-clock.sh`

**Interfaces:**

- Produces: `lock-clock.sh time <hour> <colon> <minute> <ampm>` → `10:38 PM` 相当 1 行（スペーサ廃止・AM/PM は小サイズ上寄せ）。`lock-clock.sh date <date>` → `WEDNESDAY, JULY 08` 1 行（引数 1 個に変更）。

- [ ] **Step 1: time / date 節を書き換え**

`case` 全体を以下に置換（`d()`/`esc()`/`span_open()` は変更なし）:

```bash
mode="$1"
case "$mode" in
time)
  h="$(esc "$(d +%-I)")"
  m="$(esc "$(d +%M)")"
  p="$(esc "$(d +%p)")"
  printf '%s%s</span>' "$(span_open "$2" "")" "$h"
  printf '%s%s</span>' "$(span_open "$3" "")" ':'
  printf '%s%s</span>' "$(span_open "$4" "")" "$m"
  printf '%s %s</span>\n' "$(span_open "$5" "size='40960' rise='81920'")" "$p"
  ;;
date)
  printf '%s%s</span>\n' "$(span_open "$2" "letter_spacing='4096' font_weight='bold'")" \
    "$(esc "$(d '+%A, %B %d' | tr '[:lower:]' '[:upper:]')")"
  ;;
*)
  echo "usage: lock-clock.sh {time|date} <colors...>" >&2
  exit 1
  ;;
esac
```

（Anton は単一ウェイトのため `font_weight` 指定を外す。3 文字略記は廃止しフルスペル 1 行へ戻す。）

- [ ] **Step 2: 出力検証**

Run: `LOCK_CLOCK_AT="2026-07-09 22:38" ./home-manager/desktop/hyprland/scripts/lock/lock-clock.sh time "rgba(e5e1ddff)" "rgba(ffb77ccc)" "rgba(ffb77cff)" "rgba(e5e1dd99)"`
Expected: `10`・`:`・`38`・` PM`（`size='40960' rise='81920'`）を含む 1 行・`</span>` 4 個。

Run: `LOCK_CLOCK_AT=2026-07-09 ./home-manager/desktop/hyprland/scripts/lock/lock-clock.sh date "rgba(e5e1dde6)"`
Expected: `THURSDAY, JULY 09` を含む 1 行。

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/lock/lock-clock.sh
git commit -m "feat(hyprlock): lock-clock.sh をポスター構成（1行日付・Anton前提）へ改修"
```

---

## Task 4: scrim の左下化と hyprlock.conf 組み直し

**Files:**

- Modify: `home-manager/desktop/hyprland/scripts/lock/gen-lock-scrim.sh`（焦点を左下角へ）
- Regenerate: `images/lock/lock-scrim.png`
- Modify: `home-manager/desktop/hyprland/hyprlock.conf`

- [ ] **Step 1: gen-lock-scrim.sh の焦点変更と再生成**

`gradient:center` を `0,${H}`（左下角）へ変更:

```bash
  -define "gradient:center=0,${H}" \
```

Run: `./home-manager/desktop/hyprland/scripts/lock/gen-lock-scrim.sh`
Run: `nix run nixpkgs#imagemagick -- images/lock/lock-scrim.png -format '%[pixel:p{0,799}]\n%[pixel:p{1399,0}]\n' info:`
Expected: 1 行目（左下角）α≈0.6、2 行目（右上角）α=0。

- [ ] **Step 2: hyprlock.conf の時計クラスタを全置換**

image / 時刻 label / shape / 日付 label のブロックを以下へ置き換える（`source`/`general`/`animations`/`background`/`input-field` は現状維持。shape は削除）:

```ini
image {
    monitor =
    path = ~/.config/hypr/lock-scrim.png
    size = 800 # lock-scrim.png の短辺に一致させる
    rounding = 0
    border_size = 0
    position = 0, 0
    halign = left
    valign = bottom
}

label {
    monitor =
    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh time "$lock_hour" "$lock_colon" "$lock_minute" "$lock_ampm"
    font_size = 150
    font_family = Anton
    position = 70, 130
    halign = left
    valign = bottom
    shadow_passes = 3
    shadow_size = 4
    shadow_color = $lock_shadow
    shadow_boost = 1.2
}

label {
    monitor =
    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh date "$lock_date"
    font_size = 19
    font_family = Inter
    position = 74, 80
    halign = left
    valign = bottom
    shadow_passes = 2
    shadow_size = 3
    shadow_color = $lock_shadow
    shadow_boost = 1.2
}
```

- [ ] **Step 3: 旧参照の残存チェック**

Run: `grep -cE '\$lock_(divider|month|day|weekday)' home-manager/desktop/hyprland/hyprlock.conf`
Expected: `0`

- [ ] **Step 4: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/lock/gen-lock-scrim.sh images/lock/lock-scrim.png home-manager/desktop/hyprland/hyprlock.conf
git commit -m "feat(hyprlock): 左下ポスター時計へ組み直し・scrim を左下減光に変更"
```

---

## Task 5: スクショ批評ループと最終検証

**Files:**

- Modify（数値のみ）: `hyprlock.conf`・`lock-clock.sh`（AM/PM の size/rise）・`gen-lock-scrim.sh`（W/H/ALPHA）

- [ ] **Step 1: 撮影と批評**

Run: `./home-manager/desktop/hyprland/scripts/lock/lock-preview.sh /tmp/poster-1.png "1920,940 1300x500"`
（左下領域。全画面でも可）確認項目:

- 時=白 / 分=アクセントの 2 トーンが成立し、Anton で描画されている（フォールバックの細い数字が出ていたら fc-list と family 名を確認）
- AM/PM が数字の上端付近に小さく付く（`rise` を実測調整）
- 日付が太い大文字 1 行で時刻と左端が揃う
- scrim が左下を減光し文字が読める・縁なし
- 入力欄（中央）が無事

- [ ] **Step 2: 最長日付と 2 桁時の確認**

`hyprlock.conf` の 2 つの cmd に一時的に `LOCK_CLOCK_AT='2026-09-23 10:59' ` を前置 → 撮影 → `WEDNESDAY, SEPTEMBER 23` と `10:59` で崩れないことを確認 → 前置を除去。

Run: `grep -c 'LOCK_CLOCK_AT' home-manager/desktop/hyprland/hyprlock.conf`
Expected: `0`

- [ ] **Step 3: 統合検証とコミット**

Run: `nix run .#build` / `nix run .#fmt -- --fail-on-change`
Expected: 両方緑。

```bash
git add -A home-manager/desktop/hyprland images/lock
git commit -m "style(hyprlock): ポスター時計の位置・サイズを実機調整"
```

---

## Self-Review

**Spec coverage:** フォント導入→Task 1 / トークン→Task 2 / 1 行日付・2 トーン→Task 3 / 左下構成・scrim→Task 4 / 受け入れ基準→Task 5。
**Placeholder scan:** なし（Task 5 の数値調整は実測工程）。
**Type consistency:** `date` モードの引数が 1 個（`$lock_date`）である点を Task 3（実装）と Task 4（conf）で一致させた。トークン名は Task 2 定義と Task 4 の conf 参照で一致。
