# hyprlock 時計 Inter Display SemiBold 刷新 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** hyprlock の時計を Anton 2トーンから Inter Display SemiBold 単色＋アクセント罫線＋大きい日付へ刷新する。

**Architecture:** 左下ポスター構図・scrim・入力欄は現状維持。色トークンを `$lock_time` / `$lock_accent` / `$lock_date` に集約し、`lock-clock.sh` の Pango マークアップと `hyprlock.conf` のラベル定義を差し替え、`shape` ウィジェットで罫線を追加する。Anton は参照が無くなるので削除する。

**Tech Stack:** hyprlock（label / shape / Pango markup）、matugen（色生成）、Nix（フォント宣言）

**Spec:** `docs/superpowers/specs/2026-07-10-hyprlock-clock-inter-accent-design.md`

## Global Constraints

- 罫線などの寸法・色は spec の「レイアウト定数」の値をそのまま使う（時計 135 / 70,175・AM span size 34816 rise 75000 letter_spacing 3072・罫線 90×4 rounding 2 / 76,175・日付 30 / 76,112 letter_spacing 10240）。
- 色はすべて `lock-colors.template.conf` の matugen トークン経由。hex 直書き禁止（`$lock_shadow` 等の既存固定値は除く）。
- 反映（`nix run .#switch`）はユーザーが行う。検証はビルドと `hyprlock -c` の一時 conf プレビューで行う（数秒画面がロックされる）。
- コミットは main へローカルコミットのみ。push は全タスク完了後にユーザー判断。

---

### Task 1: 色トークン・時計スクリプト・hyprlock.conf の刷新

**Files:**

- Modify: `home-manager/desktop/hyprland/lock-colors.template.conf`
- Modify: `home-manager/desktop/hyprland/lock-colors.conf`（スクリプトで再生成）
- Modify: `home-manager/desktop/hyprland/scripts/lock/lock-clock.sh`
- Modify: `home-manager/desktop/hyprland/hyprlock.conf`

**Interfaces:**

- Produces: `lock-clock.sh time <time_color> <accent_color>` / `lock-clock.sh date <date_color>`（色は `rgba(xxxxxxxx)` 形式、hyprlock.conf の cmd から渡す）

- [ ] **Step 1: lock-colors.template.conf のトークンを再設計する**

全文を以下へ置き換える:

```
# scripts/lock/gen-lock-colors.sh が lock-colors.template.conf から生成する。
$lock_time          = rgba({{colors.on_surface.default.hex_stripped}}ff)
$lock_accent        = rgba({{colors.primary.default.hex_stripped}}ff)
$lock_date          = rgba({{colors.on_surface.default.hex_stripped}}f2)
$lock_shadow        = rgba(11111baa)
$lock_input_outline = rgba({{colors.primary_container.default.hex_stripped}}d9)
$lock_input_bg      = rgba({{colors.surface.default.hex_stripped}}bf)
$lock_input_text    = rgba({{colors.on_surface.default.hex_stripped}}ff)
$lock_hint          = rgba({{colors.on_surface.default.hex_stripped}}80)
$lock_success       = rgba(a6e3a1e6)
$lock_fail          = rgba(f38ba8e6)
```

- [ ] **Step 2: lock-colors.conf を再生成する**

Run: `home-manager/desktop/hyprland/scripts/lock/gen-lock-colors.sh`
Expected: `generated: .../lock-colors.conf` と出力され、diff に `$lock_time` `$lock_accent` が現れ、`$lock_hour` `$lock_colon` `$lock_minute` `$lock_ampm` が消える。

- [ ] **Step 3: lock-clock.sh の time / date モードを差し替える**

`case "$mode" in` 以下を次へ置き換える（`d` / `esc` / `span_open` ヘルパーは無変更）:

```bash
time)
  printf '%s%s</span>' "$(span_open "$2" "")" "$(esc "$(d +%-I:%M)")"
  printf '%s %s</span>\n' \
    "$(span_open "$3" "size='34816' rise='75000' letter_spacing='3072' font_weight='semibold'")" \
    "$(esc "$(d +%p)")"
  ;;
date)
  printf '%s%s</span>\n' "$(span_open "$2" "letter_spacing='10240' font_weight='semibold'")" \
    "$(esc "$(d '+%A, %B %d' | tr '[:lower:]' '[:upper:]')")"
  ;;
*)
  echo "usage: lock-clock.sh {time|date} <colors...>" >&2
  exit 1
  ;;
```

- [ ] **Step 4: スクリプト単体で出力を確認する**

Run:

```bash
LOCK_CLOCK_AT=2026-09-23 home-manager/desktop/hyprland/scripts/lock/lock-clock.sh date 'rgba(efe0d6f2)'
home-manager/desktop/hyprland/scripts/lock/lock-clock.sh time 'rgba(efe0d6ff)' 'rgba(ffb77cff)'
```

Expected: 1 行目が `WEDNESDAY, SEPTEMBER 23` を含む単一 span、2 行目が `H:MM` の span ＋ `rise='75000'` 付き AM/PM span。

- [ ] **Step 5: hyprlock.conf のラベルを差し替え shape を追加する**

時刻 label・日付 label（37〜63 行目）を以下へ置き換える（`source`・`general`・`animations`・`background`・`image`・`input-field` は無変更）:

```
label {
    monitor =
    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh time "$lock_time" "$lock_accent"
    font_size = 135
    font_family = Inter Display SemiBold
    position = 70, 175
    halign = left
    valign = bottom
    shadow_passes = 3
    shadow_size = 4
    shadow_color = $lock_shadow
    shadow_boost = 1.2
}

shape {
    monitor =
    size = 90, 4
    color = $lock_accent
    rounding = 2
    position = 76, 175
    halign = left
    valign = bottom
}

label {
    monitor =
    text = cmd[update:10000] ~/.config/hypr/scripts/lock/lock-clock.sh date "$lock_date"
    font_size = 30
    font_family = Inter Display
    position = 76, 112
    halign = left
    valign = bottom
    shadow_passes = 2
    shadow_size = 3
    shadow_color = $lock_shadow
    shadow_boost = 1.2
}
```

- [ ] **Step 6: 実写プレビューで確認する（数秒ロックされる）**

deployed 側はまだ旧構成なので、参照パスをリポジトリ側へ差し替えた一時 conf で確認する:

```bash
ROOT="$(git rev-parse --show-toplevel)"
HY="$ROOT/home-manager/desktop/hyprland"
TMP="$(mktemp --suffix=.conf)"
sed "s|~/.config/hypr/lock-colors.conf|$HY/lock-colors.conf|; s|~/.config/hypr/scripts/lock/lock-clock.sh|$HY/scripts/lock/lock-clock.sh|" "$HY/hyprlock.conf" > "$TMP"
hyprlock -c "$TMP" --no-fade-in --immediate-render & sleep 2.5
grim -g "1920,700 1300x740" /tmp/hyprlock-new.png
pkill -USR1 hyprlock
```

Expected: 左下にクリーム単色時計＋オレンジ AM＋罫線＋大文字日付。スクリーンショットを目視確認する。

- [ ] **Step 7: Commit**

```bash
git add home-manager/desktop/hyprland/lock-colors.template.conf \
        home-manager/desktop/hyprland/lock-colors.conf \
        home-manager/desktop/hyprland/scripts/lock/lock-clock.sh \
        home-manager/desktop/hyprland/hyprlock.conf
git commit -m "feat(hyprlock): 時計を Inter Display SemiBold 単色＋アクセント罫線へ刷新"
```

---

### Task 2: Anton フォントの削除とビルド検証

**Files:**

- Modify: `nixos/core/fonts/default.nix`

**Interfaces:**

- Consumes: Task 1 完了後（Anton の参照が repo から消えていること）

- [ ] **Step 1: Anton の参照が残っていないことを確認する**

Run: `grep -rni anton --include='*.nix' --include='*.conf' --include='*.sh' . | grep -v docs/`
Expected: `nixos/core/fonts/default.nix` の 1 件のみ。

- [ ] **Step 2: fonts.packages から Anton を削除する**

`nixos/core/fonts/default.nix` から次の 1 行を削除する:

```nix
    (google-fonts.override { fonts = [ "Anton" ]; })
```

- [ ] **Step 3: フォーマットとビルドを通す**

Run: `nix run .#fmt -- --fail-on-change && nix run .#build`
Expected: fmt 変更なし、`Build successful!`。

- [ ] **Step 4: Commit**

```bash
git add nixos/core/fonts/default.nix
git commit -m "chore(fonts): 未使用になった Anton を削除"
```

---

## 完了後の反映（ユーザー操作）

- `nix run .#switch` で反映後、`~/.config/hypr/scripts/lock/lock-preview.sh` で本番構成を最終確認する。
- push は CI フルビルドを伴うため、ローカル検証後にユーザーが行う。
