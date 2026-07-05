# hyprlock 時刻表示リデザイン Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ロック画面の時刻・日付表示を、caelestia 風の「大きな時計 + 区切り線 + 日付カラム」レイアウト（画面右上・12時間表記・M3 3色スキーム・Inter Display）へ刷新する。

**Architecture:** hyprlock の `label`（Pango マークアップ）でクラスタごとに 1 ラベル、色は `lock-colors.conf` の `$lock_*` トークンを hyprlock.conf で展開してヘルパースクリプト `lock-clock.sh` に引数で渡し、スクリプトが Pango マークアップ文字列を生成する。区切り線は `shape`、日付カラムは複数行単一ラベル（`text_align=left` + `halign=right`）。入力欄は現状維持。

**Tech Stack:** hyprlock v0.9.5 / hyprlang（`$var` 行内置換）/ Pango markup / bash / matugen / NixOS home-manager（`lnk` によるリポジトリ作業ツリーへの symlink）。

## Global Constraints

- 対象は実機 NixOS（`.#nixos`）のみ。WSL は desktop を import しないため影響なし。
- パッケージ宣言は集約 `packages.nix` のみ（CLAUDE.md）。本計画は**設定・スクリプトのみ**でパッケージ追加は無い（`Inter Display` は `nixos/core/fonts` の `inter` に同梱済み）。
- `lnk` は `~/.config/hypr/*` をリポジトリ作業ツリーへ symlink する。よって `hyprlock.conf` / `scripts/` / `lock-colors.conf` の**内容変更はライブ反映**。`nix run .#switch` は新規 `xdg.configFile` エントリ追加時のみ必要（本計画では不要）。
- 検証は `nix run .#build`（Nix 評価）と `nix run .#fmt -- --fail-on-change`（treefmt / シェルは shfmt=タブインデント）を必ず通す。hyprlock 設定の見た目は実機で `hyprlock` を起動して確認する。
- hyprlock の `font_size` と Pango span の `size`/`letter_spacing`/`rise` はいずれも **pt 単位**（hyprgraphics が `set_size(fontSize * PANGO_SCALE)` を使用）。span 内の絶対値（`18432`=18pt 等）はこの単位系。
- 色は `rgba(rrggbbaa)` のまま引数で渡し、`#rrggbb` への変換はスクリプト側で行う（hyprlang は行内 `#` をコメント開始として扱うため conf に `#rrggbb` を直書きしない）。
- スクリプトへ渡す `$lock_*` 引数は**必ずダブルクォートで囲む**（`cmd[]` は `sh -c` 実行。`rgba(...)` の括弧がシェル構文エラーになるのを防ぐ成立条件）。

---

## File Structure

- `home-manager/desktop/matugen/templates/lock-colors.conf` — matugen 描画テンプレート（役割ベーストークン定義）。**改修**（トークン刷新）。
- `home-manager/desktop/hyprland/lock-colors.conf` — 上記テンプレートの生成物（コミット対象）。**再生成**。
- `home-manager/desktop/hyprland/scripts/gen-lock-colors.sh` — 生成スクリプト。**改修**（画像パスを実体へ整合）。
- `home-manager/desktop/hyprland/scripts/lock-clock.sh` — 時刻/日付の Pango マークアップ生成ヘルパー。**新規**。
- `home-manager/desktop/hyprland/hyprlock.conf` — レイアウト本体。**改修**（時刻ラベル + shape + 日付ラベル）。
- `todo.md` — 完了マーク。**改修**。

`default.nix` は `scripts/` ディレクトリごと lnk 済みのため、`lock-clock.sh` 追加に伴う Nix 側の変更は不要。

---

## Task 1: カラートークン刷新と lock-colors 再生成

**Files:**

- Modify: `home-manager/desktop/matugen/templates/lock-colors.conf`
- Modify: `home-manager/desktop/hyprland/scripts/gen-lock-colors.sh`（`IMG` 行）
- Regenerate: `home-manager/desktop/hyprland/lock-colors.conf`

**Interfaces:**

- Produces: hyprlock.conf が参照する色トークン群 `$lock_hour` `$lock_colon` `$lock_minute` `$lock_ampm` `$lock_divider` `$lock_month` `$lock_day` `$lock_weekday` `$lock_shadow` `$lock_input_outline` `$lock_input_bg` `$lock_input_text` `$lock_hint` `$lock_success` `$lock_fail`（各値は `rgba(rrggbbaa)`）。旧 `$lock_clock` `$lock_date` は廃止。

- [ ] **Step 1: matugen テンプレートを役割ベーストークンへ書き換え**

`home-manager/desktop/matugen/templates/lock-colors.conf` を以下の内容で全置換する。

```ini
# hyprlock 専用カラートークン（役割ベース）。
# scripts/gen-lock-colors.sh が lock.jpg からこのテンプレートを描画して
# home-manager/desktop/hyprland/lock-colors.conf を生成する。
$lock_hour          = rgba({{colors.primary.default.hex_stripped}}ff)
$lock_colon         = rgba({{colors.tertiary.default.hex_stripped}}cc)
$lock_minute        = rgba({{colors.secondary.default.hex_stripped}}ff)
$lock_ampm          = rgba({{colors.secondary.default.hex_stripped}}ff)
$lock_divider       = rgba({{colors.primary.default.hex_stripped}}cc)
$lock_month         = rgba({{colors.secondary.default.hex_stripped}}ff)
$lock_day           = rgba({{colors.primary.default.hex_stripped}}ff)
$lock_weekday       = rgba({{colors.secondary.default.hex_stripped}}e6)
$lock_shadow        = rgba(11111baa)
$lock_input_outline = rgba({{colors.primary_container.default.hex_stripped}}d9)
$lock_input_bg      = rgba({{colors.surface.default.hex_stripped}}bf)
$lock_input_text    = rgba({{colors.on_surface.default.hex_stripped}}ff)
$lock_hint          = rgba({{colors.on_surface.default.hex_stripped}}80)
$lock_success       = rgba(a6e3a1e6)
$lock_fail          = rgba(f38ba8e6)
```

- [ ] **Step 2: gen-lock-colors.sh の画像パスを実体へ整合**

`home-manager/desktop/hyprland/scripts/gen-lock-colors.sh` の `IMG` 行を修正する。実画像は `images/lock/lock.jpg`（`default.nix` が lnk している場所）にあり、旧パス `home-manager/desktop/hyprland/lock.jpg` には存在しない。

変更前:

```bash
IMG="$ROOT/home-manager/desktop/hyprland/lock.jpg"
```

変更後:

```bash
IMG="$ROOT/images/lock/lock.jpg"
```

- [ ] **Step 3: 再生成前テスト（新トークンが未反映であることを確認）**

Run: `grep -c 'lock_hour' home-manager/desktop/hyprland/lock-colors.conf`
Expected: `0`（まだ旧トークンのみ = 未生成）

- [ ] **Step 4: lock-colors.conf を再生成**

Run: `./home-manager/desktop/hyprland/scripts/gen-lock-colors.sh`
Expected: `generated: .../home-manager/desktop/hyprland/lock-colors.conf` と表示され、エラー終了しない。

- [ ] **Step 5: 生成結果を検証**

Run: `grep -E '^\$lock_(hour|colon|minute|ampm|divider|month|day|weekday)' home-manager/desktop/hyprland/lock-colors.conf | wc -l`
Expected: `8`

Run: `grep -cE '^\$lock_(clock|date) ' home-manager/desktop/hyprland/lock-colors.conf`
Expected: `0`（旧トークンが消えている）

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/matugen/templates/lock-colors.conf \
        home-manager/desktop/hyprland/scripts/gen-lock-colors.sh \
        home-manager/desktop/hyprland/lock-colors.conf
git commit -m "feat(hyprlock): 時刻表示用の役割ベースカラートークンへ刷新し再生成"
```

---

## Task 2: lock-clock.sh ヘルパー作成

**Files:**

- Create: `home-manager/desktop/hyprland/scripts/lock-clock.sh`

**Interfaces:**

- Consumes: `$lock_*` 色トークン（`rgba(rrggbbaa)`）を CLI 引数で受け取る。
- Produces: 呼び出し規約
  - `lock-clock.sh time <hour> <colon> <minute> <ampm>` → 1 行の Pango マークアップ（`12:22 AM` 相当。AM は `size='18432' rise='40960'` で上寄せ）。
  - `lock-clock.sh date <month> <day> <weekday>` → 3 行の Pango マークアップ（月=大文字/letter_spacing 4pt、日=`size='26624'`、曜日）。
  - 各 `<...>` は `rgba(rrggbbaa)`。hyprlock.conf の `text = cmd[...] lock-clock.sh ...` から呼ばれる。

- [ ] **Step 1: 未作成テスト（スクリプトがまだ無いことを確認）**

Run: `test ! -e home-manager/desktop/hyprland/scripts/lock-clock.sh && echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: スクリプトを作成**

`home-manager/desktop/hyprland/scripts/lock-clock.sh` を以下の内容（インデントはタブ）で作成する。

```bash
#!/usr/bin/env bash
# hyprlock の時刻/日付ラベル用 Pango マークアップを出力する。
# 色は hyprlock.conf 側で $lock_* トークン（rgba(rrggbbaa)）が展開され引数で渡る。
# 使い方:
#   lock-clock.sh time <hour> <colon> <minute> <ampm>
#   lock-clock.sh date <month> <day> <weekday>
# <...> は rgba(rrggbbaa) 形式。
set -euo pipefail
export LC_ALL=C

esc() { printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }

# $1=rgba(rrggbbaa), $2=追加属性 → <span ...> 開きタグ
span_open() {
	local v="${1#rgba(}"
	v="${v%)}"
	local hex="#${v:0:6}"
	local a=$((16#${v:6:2}))
	local attrs="foreground='$hex'"
	if [ "$a" -lt 255 ]; then
		attrs="$attrs fgalpha='$(((a * 100 + 127) / 255))%'"
	fi
	printf "<span %s %s>" "$attrs" "$2"
}

mode="$1"
case "$mode" in
time)
	h="$(esc "$(date +%-I)")"
	m="$(esc "$(date +%M)")"
	p="$(esc "$(date +%p)")"
	printf '%s%s</span>' "$(span_open "$2" "font_weight='800'")" "$h"
	printf '%s%s</span>' "$(span_open "$3" "font_weight='800'")" ':'
	printf '%s%s</span>' "$(span_open "$4" "font_weight='800'")" "$m"
	printf '%s %s</span>\n' "$(span_open "$5" "font_weight='medium' size='18432' rise='40960'")" "$p"
	;;
date)
	mo="$(esc "$(date +%B | tr '[:lower:]' '[:upper:]')")"
	d="$(esc "$(date +%d)")"
	wd="$(esc "$(date +%A)")"
	printf '%s%s</span>\n' "$(span_open "$2" "letter_spacing='4096' font_weight='bold'")" "$mo"
	printf '%s%s</span>\n' "$(span_open "$3" "letter_spacing='2048' font_weight='medium' size='26624'")" "$d"
	printf '%s%s</span>\n' "$(span_open "$4" "letter_spacing='2048'")" "$wd"
	;;
*)
	echo "usage: lock-clock.sh {time|date} <colors...>" >&2
	exit 1
	;;
esac
```

- [ ] **Step 3: 実行権限を付与**

Run: `chmod +x home-manager/desktop/hyprland/scripts/lock-clock.sh`

- [ ] **Step 4: time モードの出力構造を検証**

Run:

```bash
home-manager/desktop/hyprland/scripts/lock-clock.sh time \
  "rgba(ffb77cff)" "rgba(9fd8c8cc)" "rgba(dcc2e6ff)" "rgba(dcc2e6ff)"
```

Expected（時刻の数字は実行時刻で変わる。構造が一致すればよい）:

- `foreground='#ffb77c'` を含む（時の色）
- コロン span に `fgalpha='80%'`（cc=204/255≒80%）を含む
- 末尾 span に `size='18432' rise='40960'` と ` AM`/` PM` を含む
- `<span ...>` タグがきちんと閉じている（`</span>` が4つ）

確認コマンド:

```bash
home-manager/desktop/hyprland/scripts/lock-clock.sh time \
  "rgba(ffb77cff)" "rgba(9fd8c8cc)" "rgba(dcc2e6ff)" "rgba(dcc2e6ff)" \
  | grep -oE '</span>' | wc -l
```

Expected: `4`

- [ ] **Step 5: date モードの出力構造を検証**

Run:

```bash
home-manager/desktop/hyprland/scripts/lock-clock.sh date \
  "rgba(dcc2e6ff)" "rgba(ffb77cff)" "rgba(dcc2e6e6)" | wc -l
```

Expected: `3`（月・日・曜日の 3 行）

Run:

```bash
home-manager/desktop/hyprland/scripts/lock-clock.sh date \
  "rgba(dcc2e6ff)" "rgba(ffb77cff)" "rgba(dcc2e6e6)" | head -1
```

Expected: 月名が**大文字**で `letter_spacing='4096' font_weight='bold'` を含む（例 `...>JULY</span>`）。

- [ ] **Step 6: shfmt 整形チェック**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで成功（スクリプトはタブインデント済み）。差分が出たら `nix run .#fmt` で整形してから再確認。

- [ ] **Step 7: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/lock-clock.sh
git commit -m "feat(hyprlock): 時刻/日付の Pango マークアップ生成ヘルパーを追加"
```

---

## Task 3: hyprlock.conf の時刻クラスタ再構成

**Files:**

- Modify: `home-manager/desktop/hyprland/hyprlock.conf`

**Interfaces:**

- Consumes: Task 1 の色トークン、Task 2 の `lock-clock.sh`（`~/.config/hypr/scripts/lock-clock.sh`）。
- Produces: 右上に `[時刻][区切り線][日付カラム]`、中央に入力欄（現状維持）のロック画面レイアウト。

- [ ] **Step 1: hyprlock.conf を全置換**

`home-manager/desktop/hyprland/hyprlock.conf` を以下の内容で全置換する（`source`/`general`/`animations`/`background`/`input-field` は現状維持。時刻・日付ラベルを差し替え、`shape` を追加）。

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
    animation = fadeOut, 1, 3, lockEase
    animation = inputFieldDots, 1, 3, default
    animation = inputFieldColors, 1, 4, default
    animation = inputFieldFade, 1, 4, default
}

background {
    monitor =
    path = ~/.config/hypr/lock.jpg
    blur_passes = 0
    brightness = 0.8
    contrast = 1.0
}

# 時刻クラスタ（右上）: 12:22 AM を1ラベルに Pango マークアップで色分け
label {
    monitor =
    text = cmd[update:10000] ~/.config/hypr/scripts/lock-clock.sh time "$lock_hour" "$lock_colon" "$lock_minute" "$lock_ampm"
    font_size = 72
    font_family = Inter Display
    position = -235, -70
    halign = right
    valign = top
    shadow_passes = 3
    shadow_size = 4
    shadow_color = $lock_shadow
    shadow_boost = 1.2
}

# 区切り線（時刻と日付カラムの間）
shape {
    monitor =
    size = 3, 96
    rounding = -1
    color = $lock_divider
    position = -150, -78
    halign = right
    valign = top
}

# 日付カラム（右上・左揃え・複数行1ラベル）
label {
    monitor =
    text = cmd[update:10000] ~/.config/hypr/scripts/lock-clock.sh date "$lock_month" "$lock_day" "$lock_weekday"
    text_align = left
    font_size = 15
    font_family = Inter Display
    position = -60, -74
    halign = right
    valign = top
    shadow_passes = 2
    shadow_size = 3
    shadow_color = $lock_shadow
    shadow_boost = 1.2
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
    position = 0, -80
    halign = center
    valign = center
}
```

- [ ] **Step 2: 旧トークン参照が残っていないことを検証**

Run: `grep -cE '\$lock_(clock|date)\b' home-manager/desktop/hyprland/hyprlock.conf`
Expected: `0`

Run: `grep -c 'lock-clock.sh' home-manager/desktop/hyprland/hyprlock.conf`
Expected: `2`（time と date の 2 箇所）

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/hyprland/hyprlock.conf
git commit -m "feat(hyprlock): 時刻表示を右上の caelestia 風レイアウトへ再構成"
```

---

## Task 4: Nix 評価と整形の統合検証

**Files:** （変更なし。検証のみ）

- [ ] **Step 1: Nix 構成がビルドできることを確認**

Run: `nix run .#build`
Expected: エラー無く完了（`lnk` の各パスが解決し nixos toplevel が評価できる）。

- [ ] **Step 2: treefmt が緑であることを確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで成功。差分が出たら `nix run .#fmt` で整形し、変更を該当タスクのコミットに含める。

- [ ] **Step 3: 未使用 let 束縛が無いことを確認（deadnix は treefmt に内包）**

Step 2 が成功していれば OK。失敗時は指摘箇所を修正して再実行。

---

## Task 5: 実機での見た目調整

**Files:**

- Modify: `home-manager/desktop/hyprland/hyprlock.conf`（位置・サイズの数値のみ）

`lnk` により hyprlock.conf・scripts はリポジトリ作業ツリーへ symlink されているため、**リポジトリのファイルを編集して `hyprlock` を再起動するだけでライブ反映**される（`nix run .#switch` 不要）。ロック中に締め出されないよう、別 TTY か SSH セッションを確保するか、確認後すぐ解除できる状態で行う。

- [ ] **Step 1: hyprlock を起動して表示を確認**

Run: `hyprlock`
確認（解除は正しいパスワード入力、または別セッションから `pkill hyprlock`）:

- 右上に `12:22 AM │ JUNE / 21 / Sunday` 相当が表示される。
- 時＝アクセント色・コロン＝別色・分＝別色の 3 色になっている。
- 区切り線が時刻と日付の間に縦線として出る。
- 日付カラムが左揃えの縦積みになっている。
- マークアップが生表示（`<span ...>` がそのまま見える）していない → 出ていたら Pango 解析失敗。`lock-clock.sh` の出力を端末で再確認する。
- 時刻に `$lock_hour` 等が生で出ていない → 出ていたら hyprlang の `$var` 展開が効いていない。`lock-colors.conf` が `source` 行で読まれているか、トークン名の綴りを確認する。

- [ ] **Step 2: 数値を調整**

必要に応じて `hyprlock.conf` の以下を実機で詰める。編集後は再度 `hyprlock` を起動して確認する。

- 時刻ラベル: `font_size`(72)・`position`(-235, -70)
- AM の `size`(18432=18pt)・`rise`(40960=40pt) … `lock-clock.sh` の time 節を編集
- 区切り線: `size`(3, 96)・`position`(-150, -78)
- 日付ラベル: `font_size`(15)・`position`(-60, -74)、日の `size`(26624=26pt)・`letter_spacing` … `lock-clock.sh` の date 節を編集
- 3 要素の右端・縦位置が揃い、隙間が均等になるよう `position` を調整する。

- [ ] **Step 3: 日付カラムの改行描画を確認**

日付が 3 行に分かれて表示されているか（`printf '...\n'` の改行が Pango で行分割されているか）を目視確認する。1 行に潰れている場合は各行末の改行が失われていないか `lock-clock.sh date ... | cat -A` で確認する。

- [ ] **Step 4: 調整値をコミット**

```bash
git add home-manager/desktop/hyprland/hyprlock.conf home-manager/desktop/hyprland/scripts/lock-clock.sh
git commit -m "style(hyprlock): 時刻クラスタの位置・サイズを実機で調整"
```

（数値変更が無ければこのコミットは省略してよい。）

---

## Task 6: todo.md の更新

**Files:**

- Modify: `todo.md`

- [ ] **Step 1: 該当項目を完了へ更新**

`todo.md` の「ロック画面のデザイン調整 / 時計と日付のサイズを大きくしたい」項目を、caelestia 風時刻表示の実装完了として更新する（例: 見出しに ✅ を付け、実装内容と設計/計画ドキュメントのパスを 1〜2 行で追記）。

追記例:

```markdown
## ロック画面のデザイン調整 ✅ 完了

caelestia 風の右上時刻表示（12時間 + AM/PM・区切り線・日付カラム・Inter Display・M3 3色）へ刷新。
設計 `docs/superpowers/specs/2026-07-06-hyprlock-clock-redesign-design.md` / 計画 `docs/superpowers/plans/2026-07-06-hyprlock-clock-redesign.md`。
```

- [ ] **Step 2: コミット**

```bash
git add todo.md
git commit -m "docs(todo): ロック画面時刻表示リデザインを完了として更新"
```

---

## Self-Review

**Spec coverage（設計スペックの各節 → タスク対応）:**

- 右上レイアウト / 区切り線 / 日付カラム → Task 3
- 12時間 + AM/PM・英語日付 → Task 2（`lock-clock.sh`）
- M3 3色スキーム・トークン再設計 → Task 1 + Task 2
- Inter Display → Task 3（`font_family`）。フォント追加宣言不要（Global Constraints に明記）
- Pango マークアップ + `$var` 引数展開（案A）→ Task 3（conf）+ Task 2（script）
- 実装要件（ダブルクォート / Pango エスケープ / rgba のまま渡す / update:10000）→ Global Constraints + Task 2 の `esc()` + Task 3 の conf
- 生成パイプライン（gen-lock-colors.sh 踏襲・画像パス整合）→ Task 1
- 入力欄・背景・アニメ現状維持 → Task 3（全置換内で保持）
- build / fmt 緑 → Task 4
- 受け入れ基準（見た目）→ Task 5

**Placeholder scan:** 「TBD/後で」等の未確定記述なし。Task 5 の数値調整は「完成した設定の pt 値を実機で詰める」工程であり、コード自体はすべて具体値で埋まっている（プレースホルダではない）。

**Type consistency:** 色トークン名は Task 1（定義）/ Task 2（引数受け）/ Task 3（conf 展開）で一致（`$lock_hour/$lock_colon/$lock_minute/$lock_ampm/$lock_divider/$lock_month/$lock_day/$lock_weekday/$lock_shadow`）。`lock-clock.sh` の呼び出し規約（`time`/`date` サブコマンドと引数順）も Task 2 の Produces と Task 3 の conf で一致。
