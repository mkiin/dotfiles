# hyprlock 時計コーナー減光 + レイアウト再構成 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** ロック画面右上の時計クラスタを、コーナー減光（黒→透明のラジアルグラデーション PNG）で背景から浮かせ、最大幅基準（SEPTEMBER / Wednesday）で区切り線・日付カラムの整列を作り直す。

**Architecture:** ImageMagick で生成した scrim PNG を `image` ウィジェットとしてラベルの背面・右上アンカーに重ねる（壁紙は無加工）。レイアウトは最長日付の実測幅から座標を決め、`lock-clock.sh` に `LOCK_CLOCK_AT` 環境変数を足して最長ケースをスクリーンショットで再現・検証する。撮影は新設の `lock-preview.sh`（hyprlock 起動→grim→SIGUSR1 解除）で行う。

**Tech Stack:** hyprlock v0.9.5（image/shape/label ウィジェット・hyprlang `$var` 展開）/ ImageMagick 7（`nix run nixpkgs#imagemagick`、パッケージ追加なし）/ grim / bash / NixOS home-manager（`lnk` symlink）。

**Spec:** `docs/superpowers/specs/2026-07-08-hyprlock-clock-contrast-design.md`

## Global Constraints

- 対象は実機 NixOS（`.#nixos`）のみ。WSL は desktop を import しないため影響なし。
- **パッケージ追加は一切しない**。ImageMagick は `nix run nixpkgs#imagemagick` で都度呼ぶ（CLAUDE.md の集約 `packages.nix` ルールに抵触させない）。
- `lnk` により `~/.config/hypr/*` はリポジトリ作業ツリーへの symlink。既存ファイルの内容変更は**ライブ反映**。`nix run .#switch` が必要なのは **Task 3 の新規 `xdg.configFile` エントリ追加時の 1 回だけ**。
- 検証は `nix run .#build` と `nix run .#fmt -- --fail-on-change` を必ず通す。シェルスクリプトのインデントは既存（`gen-lock-colors.sh` 等）に合わせ 2 スペース。差分が出たら `nix run .#fmt` で整形してからコミットする。
- hyprlock の `font_size` と Pango span の `size`/`letter_spacing`/`rise` は **pt 単位**（`18432`=18pt 等、値は pt×1024）。
- 色は `rgba(rrggbbaa)` のままスクリプトへ渡し、引数は**必ずダブルクォート**（`cmd[]` は `sh -c` 実行のため括弧がシェル構文エラーになる）。
- 色トークン（`lock-colors.conf` / matugen テンプレート）・入力欄・背景（`lock.jpg`・blur/brightness）・アニメーションは**変更しない**。
- `lock-preview.sh` の実行は**数秒間実際に画面をロックする**（自動解除される）。実行前にその旨を認識しておくこと。

---

## File Structure

- `home-manager/desktop/hyprland/scripts/lock-preview.sh` — 開発用スクショツール。**新規**（Task 1）。
- `home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh` — scrim PNG 生成。**新規**（Task 2）。
- `images/lock/lock-scrim.png` — 生成物（コミット対象）。**新規**（Task 2）。
- `home-manager/desktop/hyprland/default.nix` — scrim の lnk 配線 1 行追加。**改修**（Task 3）。
- `home-manager/desktop/hyprland/hyprlock.conf` — image ウィジェット追加（Task 3）+ 座標再調整（Task 5）。**改修**。
- `home-manager/desktop/hyprland/scripts/lock-clock.sh` — `LOCK_CLOCK_AT` 対応。**改修**（Task 4）。
- `todo.md` — 完了マーク。**改修**（Task 6）。

`scripts/` ディレクトリは丸ごと lnk 済みのため、スクリプト追加に Nix 側の変更は不要。

---

## Task 1: lock-preview.sh（開発用スクリーンショットツール）

**Files:**

- Create: `home-manager/desktop/hyprland/scripts/lock-preview.sh`

**Interfaces:**

- Consumes: `hyprlock` / `grim`（インストール済み）、Hyprland セッション。
- Produces: `lock-preview.sh [出力.png] ["x,y WxH"]` — hyprlock を起動して撮影し PNG を保存、SIGUSR1 で自動解除。第2引数は grim の `-g` 領域指定（省略時は全画面）。Task 3・5 の検証で使う。

- [ ] **Step 1: 未作成であることを確認**

Run: `test ! -e home-manager/desktop/hyprland/scripts/lock-preview.sh && echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: スクリプトを作成**

`home-manager/desktop/hyprland/scripts/lock-preview.sh` を以下の内容で作成する。

```bash
#!/usr/bin/env bash
# hyprlock の見た目確認用スクリーンショットを撮る開発ツール。
# ロック画面は通常の方法では撮れないため、hyprlock を起動して grim で撮影し
# SIGUSR1（hyprlock の正規解除シグナル）で即解除する。数秒間画面がロックされる。
# 使い方: lock-preview.sh [出力.png] ["x,y WxH"(grim -g 領域)]
set -euo pipefail

OUT="${1:-/tmp/hyprlock-preview.png}"
REGION="${2:-}"

hyprlock >/dev/null 2>&1 &
# grim が失敗しても必ず解除してロックアウトを防ぐ
trap 'pkill -USR1 hyprlock 2>/dev/null || true' EXIT
sleep 4
if [[ -n $REGION ]]; then
  grim -g "$REGION" "$OUT"
else
  grim "$OUT"
fi
echo "saved: $OUT"
```

- [ ] **Step 3: 実行権限を付与**

Run: `chmod +x home-manager/desktop/hyprland/scripts/lock-preview.sh`

- [ ] **Step 4: 動作確認（数秒画面がロックされる）**

Run: `./home-manager/desktop/hyprland/scripts/lock-preview.sh /tmp/lock-preview-test.png`
Expected: 約4秒ロック後に自動解除され、`saved: /tmp/lock-preview-test.png` と表示。

Run: `file /tmp/lock-preview-test.png`
Expected: `PNG image data` を含む（サイズが全モニタ結合解像度になっている）。

- [ ] **Step 5: 整形チェック**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで成功。差分が出たら `nix run .#fmt` で整形して再確認。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/lock-preview.sh
git commit -m "feat(hyprlock): ロック画面スクリーンショット撮影の開発ツールを追加"
```

---

## Task 2: gen-lock-scrim.sh と lock-scrim.png の生成

**Files:**

- Create: `home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh`
- Create: `images/lock/lock-scrim.png`（生成物）

**Interfaces:**

- Consumes: `nix run nixpkgs#imagemagick`（ImageMagick 7 の `magick`）。
- Produces: `images/lock/lock-scrim.png` — 1100×650・右上角が黒 α0.55 で左下へ 0 に減衰するラジアルグラデーション（RGBA）。Task 3 が lnk して image ウィジェットで表示する。スクリプト先頭の `W`/`H`/`ALPHA` が調整点（Task 5 で変更しうる）。

- [ ] **Step 1: 未作成であることを確認**

Run: `test ! -e home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh && test ! -e images/lock/lock-scrim.png && echo MISSING`
Expected: `MISSING`

- [ ] **Step 2: 生成スクリプトを作成**

`home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh` を以下の内容で作成する。

```bash
#!/usr/bin/env bash
# hyprlock 右上の時計クラスタ用コーナー減光 PNG (lock-scrim.png) を生成する。
# 右上角が最も濃い黒のラジアルグラデーションで、image ウィジェットとして
# 壁紙の上・文字の下に重ねる（境界線のない減光で文字直載せの透明感を保つ）。
# 使い方: dotfiles リポジトリ内で実行する。
#   ./home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
OUT="$ROOT/images/lock/lock-scrim.png"
W=1100
H=650
# 右上角の黒の濃さ (0.0-1.0)。実機スクショを見て調整する
ALPHA=0.55

nix run nixpkgs#imagemagick -- \
  -size "${W}x${H}" \
  -define "gradient:center=${W},0" \
  -define "gradient:radii=${W},${H}" \
  "radial-gradient:rgba(0,0,0,${ALPHA})-rgba(0,0,0,0)" \
  "PNG32:${OUT}"
echo "generated: $OUT"
echo "git diff で確認してコミットしてください。"
```

- [ ] **Step 3: 実行権限を付与して生成**

Run: `chmod +x home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh && ./home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh`
Expected: `generated: .../images/lock/lock-scrim.png` と表示されエラー終了しない。

- [ ] **Step 4: 生成物を検証（寸法とアルファ）**

Run: `nix run nixpkgs#imagemagick -- identify images/lock/lock-scrim.png`
Expected: `PNG 1100x650` を含む。

Run: `nix run nixpkgs#imagemagick -- images/lock/lock-scrim.png -format '%[pixel:p{1099,0}]\n%[pixel:p{0,649}]\n' info:`
Expected: 1 行目（右上角）はアルファ約 0.55（例 `srgba(0,0,0,0.54902)` / `graya(0,0.54902)` 表記ゆれ可）、2 行目（左下角）はアルファ 0。

- [ ] **Step 5: 整形チェック**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで成功。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh images/lock/lock-scrim.png
git commit -m "feat(hyprlock): コーナー減光 scrim PNG と生成スクリプトを追加"
```

---

## Task 3: 配線とスパイク（image ウィジェットのアルファ描画確認）

**Files:**

- Modify: `home-manager/desktop/hyprland/default.nix`（`xdg.configFile` に 1 行）
- Modify: `home-manager/desktop/hyprland/hyprlock.conf`（image ブロック追加）

**Interfaces:**

- Consumes: Task 1 の `lock-preview.sh`、Task 2 の `images/lock/lock-scrim.png`。
- Produces: `~/.config/hypr/lock-scrim.png`（lnk）と、hyprlock 右上に描画される scrim。**この Task は設計のスパイク**: アルファ付き PNG がグラデーションのまま描画されなければ、以降を中断して壁紙焼き込みフォールバック（スペック参照）へ設計を差し戻す。

- [ ] **Step 1: default.nix に lnk 行を追加**

`home-manager/desktop/hyprland/default.nix` の `xdg.configFile` 内、`"hypr/lock.jpg"` の行の直後に追加する。

変更前:

```nix
    "hypr/lock.jpg".source = lnk ../../../images/lock/lock.jpg;
  };
```

変更後:

```nix
    "hypr/lock.jpg".source = lnk ../../../images/lock/lock.jpg;
    "hypr/lock-scrim.png".source = lnk ../../../images/lock/lock-scrim.png;
  };
```

- [ ] **Step 2: hyprlock.conf に image ウィジェットを追加**

`home-manager/desktop/hyprland/hyprlock.conf` の `background { ... }` ブロックの直後（`# 時刻クラスタ（右上）` コメントの前）に以下を挿入する。**ラベルより前に宣言することで背面（壁紙の上・文字の下）に描画される。**

```ini
# コーナー減光: 時計クラスタの背面に敷く黒→透明グラデーション（境界線なし）
image {
    monitor =
    path = ~/.config/hypr/lock-scrim.png
    size = 650          # PNG 実寸の短辺 = 等倍表示
    rounding = 0
    border_size = 0
    position = 0, 0
    halign = right
    valign = top
}
```

- [ ] **Step 3: ビルド確認と switch（新規 xdg エントリの反映）**

Run: `nix run .#build`
Expected: エラーなく完了。

Run: `nix run .#switch`
Expected: 成功し、`ls -la ~/.config/hypr/lock-scrim.png` が リポジトリの `images/lock/lock-scrim.png` への symlink を示す。

- [ ] **Step 4: スパイク検証（数秒画面がロックされる）**

Run: `./home-manager/desktop/hyprland/scripts/lock-preview.sh /tmp/scrim-spike.png`
撮影画像を確認し、以下を判定する:

- 右上に黒のグラデーション減光が出ている（矩形の「縁」や枠線が見えない）
- グラデーションが滑らか（縞・バンディングが目立たない）
- 時刻・日付ラベルは scrim の**上**に描画されている
- 3 画面すべての右上に同じ見た目で出ている

**判定 NG の場合はここで中断**: 見えた症状（ベタ塗り・市松模様・枠付き等）を記録し、スペックのフォールバック（壁紙焼き込み）へ設計を差し戻す。以降の Task は実施しない。

- [ ] **Step 5: 整形チェック**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで成功。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/hyprland/default.nix home-manager/desktop/hyprland/hyprlock.conf
git commit -m "feat(hyprlock): コーナー減光 scrim を右上に配線"
```

---

## Task 4: lock-clock.sh の LOCK_CLOCK_AT 対応

**Files:**

- Modify: `home-manager/desktop/hyprland/scripts/lock-clock.sh`

**Interfaces:**

- Consumes: 既存の `lock-clock.sh {time|date} <colors...>` 呼び出し規約（変更しない）。
- Produces: 環境変数 `LOCK_CLOCK_AT`（`date -d` が解釈できる文字列。例 `2026-09-23 09:50`）が設定されているときだけ、その日時で出力する。未設定時は現在時刻（既存挙動そのまま）。Task 5 が最長ケース再現に使う。

- [ ] **Step 1: 現状確認（LOCK_CLOCK_AT 未対応であること）**

Run: `grep -c 'LOCK_CLOCK_AT' home-manager/desktop/hyprland/scripts/lock-clock.sh`
Expected: `0`

- [ ] **Step 2: date 呼び出しをヘルパー経由に変更**

`home-manager/desktop/hyprland/scripts/lock-clock.sh` に以下の変更を加える。

`esc()` 定義の直前に追加:

```bash
# 検証用: LOCK_CLOCK_AT="2026-09-23 09:50" 等で任意日時の出力を再現できる
d() {
  if [ -n "${LOCK_CLOCK_AT:-}" ]; then
    date -d "$LOCK_CLOCK_AT" "$@"
  else
    date "$@"
  fi
}
```

`time)` 節の 3 行を置換:

```bash
  h="$(esc "$(d +%-I)")"
  m="$(esc "$(d +%M)")"
  p="$(esc "$(d +%p)")"
```

`date)` 節の 3 行を置換:

```bash
  mo="$(esc "$(d +%B | tr '[:lower:]' '[:upper:]')")"
  d="$(esc "$(d +%d)")"
  wd="$(esc "$(d +%A)")"
```

**注意**: `date)` 節の変数 `d` はヘルパー関数 `d` と名前が衝突する。変数を `dy` に改名すること。置換後の `date)` 節全体:

```bash
date)
  mo="$(esc "$(d +%B | tr '[:lower:]' '[:upper:]')")"
  dy="$(esc "$(d +%d)")"
  wd="$(esc "$(d +%A)")"
  printf '%s%s</span>\n' "$(span_open "$2" "letter_spacing='3072' font_weight='800' size='24576'")" "$mo"
  printf '%s%s</span>\n' "$(span_open "$3" "letter_spacing='2048' font_weight='medium' size='18432'")" "$dy"
  printf '%s%s</span>' "$(span_open "$4" "letter_spacing='1024' size='14336'")" "$wd"
  ;;
```

- [ ] **Step 3: 最長ケースの再現を検証**

Run:

```bash
LOCK_CLOCK_AT=2026-09-23 ./home-manager/desktop/hyprland/scripts/lock-clock.sh date \
  "rgba(e3c0a6ff)" "rgba(ffb77cff)" "rgba(e3c0a6e6)"
```

Expected: 1 行目に `SEPTEMBER`、2 行目に `23`、3 行目に `Wednesday` を含む 3 行の Pango マークアップ。

Run:

```bash
LOCK_CLOCK_AT="2026-09-23 09:50" ./home-manager/desktop/hyprland/scripts/lock-clock.sh time \
  "rgba(ffb77cff)" "rgba(e3c0a6ff)" "rgba(e3c0a6ff)" "rgba(e3c0a6ff)"
```

Expected: `>9<` 相当の時・`50` の分・` AM` を含む 1 行のマークアップ。

- [ ] **Step 4: 既存挙動（未設定時）の確認**

Run: `./home-manager/desktop/hyprland/scripts/lock-clock.sh date "rgba(e3c0a6ff)" "rgba(ffb77cff)" "rgba(e3c0a6e6)" | head -1`
Expected: 今日の月名（大文字）が出力され、exit 0。

- [ ] **Step 5: 整形チェック**

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで成功。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/hyprland/scripts/lock-clock.sh
git commit -m "feat(hyprlock): lock-clock.sh に検証用 LOCK_CLOCK_AT を追加"
```

---

## Task 5: レイアウト再構成（最大幅基準の座標決め）

**Files:**

- Modify: `home-manager/desktop/hyprland/hyprlock.conf`（時刻・区切り線・日付の座標/サイズ）
- Modify（必要時）: `home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh`（`W`/`H`/`ALPHA`）+ `images/lock/lock-scrim.png` 再生成

**Interfaces:**

- Consumes: Task 3 の scrim 表示、Task 4 の `LOCK_CLOCK_AT`、Task 1 の `lock-preview.sh`。
- Produces: スペックの受け入れ基準を満たす最終レイアウト。整列ルール: (1) 区切り線の高さ・縦位置 = 日付カラム 3 行に一致 (2) 最長月でも線と日付が重ならない (3) 時刻と日付カラムの上下センター一致。

- [ ] **Step 1: 最長ケースを固定表示にする（一時変更・コミットしない）**

`hyprlock.conf` の 2 つの `cmd[update:10000]` 行に `LOCK_CLOCK_AT` プレフィックスを付ける（`cmd[]` は `sh -c` なので env 前置が有効）:

```ini
    text = cmd[update:10000] LOCK_CLOCK_AT='2026-09-23 09:50' ~/.config/hypr/scripts/lock-clock.sh time "$lock_hour" "$lock_colon" "$lock_minute" "$lock_ampm"
```

```ini
    text = cmd[update:10000] LOCK_CLOCK_AT='2026-09-23 09:50' ~/.config/hypr/scripts/lock-clock.sh date "$lock_month" "$lock_day" "$lock_weekday"
```

- [ ] **Step 2: 初期座標を設定**

`hyprlock.conf` の時刻・区切り線・日付を以下の初期値にする（SEPTEMBER の概算幅 210px を右マージン 60px に足した見積もり。以降のステップで実測調整する）:

- 日付ラベル: `position = -60, -74`（現状維持）
- 区切り線 shape: `position = -290, -84`・`size = 3, 110`
- 時刻ラベル: `position = -320, -70`（`font_size = 96` は維持）

- [ ] **Step 3: スクショ→調整の反復**

Run: `./home-manager/desktop/hyprland/scripts/lock-preview.sh /tmp/lock-layout.png "3700,0 900x500"`
（領域は中央モニタ右上。全画面で撮って位置を掴んでもよい。lnk により conf 編集は保存だけでライブ反映、`switch` 不要）

画像を確認し、以下がすべて満たされるまで座標編集→撮影を繰り返す:

- 区切り線が `SEPTEMBER` の左端に重ならず、時刻側・日付側の余白がほぼ均等
- 区切り線の上端・下端が日付カラム 3 行の上端・下端と揃う（`size = 3, H` の H を調整）
- 時刻（数字の上端〜下端）と日付カラムの上下センターが揃う
- scrim がクラスタ全体を覆っている。足りなければ `gen-lock-scrim.sh` の `W`/`H` を増やして再生成し、`hyprlock.conf` の `size` も PNG 短辺に合わせて更新。濃さが不足/過剰なら `ALPHA` を変えて再生成
- 文字が壁紙の明るい部分でも明瞭に読める

- [ ] **Step 4: 一時変更を外して現在日付で最終確認**

Step 1 の `LOCK_CLOCK_AT='2026-09-23 09:50' ` プレフィックスを両方の行から削除する。

Run: `./home-manager/desktop/hyprland/scripts/lock-preview.sh /tmp/lock-final.png`
Expected: 今日の日付・現在時刻で崩れなく表示され、3 画面すべて同じ見た目。

Run: `grep -c 'LOCK_CLOCK_AT' home-manager/desktop/hyprland/hyprlock.conf`
Expected: `0`（消し忘れ検出）

- [ ] **Step 5: ビルド・整形チェック**

Run: `nix run .#build`
Expected: エラーなく完了。

Run: `nix run .#fmt -- --fail-on-change`
Expected: 差分なしで成功。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/hyprland/hyprlock.conf
# scrim を再生成した場合のみ:
git add home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh images/lock/lock-scrim.png
git commit -m "style(hyprlock): 最大幅基準で時計クラスタの整列を再構成"
```

---

## Task 6: todo.md 更新と統合検証

**Files:**

- Modify: `todo.md`

- [ ] **Step 1: 統合検証**

Run: `nix run .#build && nix run .#fmt -- --fail-on-change`
Expected: 両方成功。

- [ ] **Step 2: todo.md の該当項目を更新**

`todo.md` の「ロック画面のデザイン調整 ⚠️ 要再設計（第一稿は不採用レベル）」ブロック（現在 32〜38 行目付近）を以下で置き換える:

```markdown
- ロック画面のデザイン調整 ✅ 完了
  - caelestia 風の右上時刻表示に、コーナー減光（scrim PNG + image ウィジェット）と最大幅基準（SEPTEMBER / Wednesday）の整列再構成を加えて完成。
  - 設計 `docs/superpowers/specs/2026-07-08-hyprlock-clock-contrast-design.md` / 計画 `docs/superpowers/plans/2026-07-08-hyprlock-clock-contrast.md`（第一稿: `docs/superpowers/specs/2026-07-06-hyprlock-clock-redesign-design.md`）。
```

- [ ] **Step 3: コミット**

```bash
git add todo.md
git commit -m "docs(todo): ロック画面時刻表示のコーナー減光対応を完了として更新"
```

---

## Self-Review

**Spec coverage:**

- コーナー減光（PNG 生成・image ウィジェット・lnk 配線・switch 1 回）→ Task 2 + Task 3
- スパイク（アルファ描画確認・NG 時フォールバック中断）→ Task 3 Step 4
- 最大幅基準レイアウト（整列 3 ルール・SEPTEMBER/Wednesday）→ Task 5
- `LOCK_CLOCK_AT` → Task 4
- `lock-preview.sh` → Task 1
- 変更しないもの（色トークン・入力欄・背景・アニメ）→ Global Constraints
- 受け入れ基準（最長ケース・可読性・縁なし・3 画面・build/fmt 緑）→ Task 5 Step 3-5 + Task 6 Step 1

**Placeholder scan:** 未確定値なし。Task 5 の座標は初期値を明示した上での実測調整工程（スペックが要求する進め方）。

**Type consistency:** `LOCK_CLOCK_AT` の名前と形式（`date -d` 互換）は Task 4（実装）と Task 5（利用）で一致。`lock-preview.sh` の引数規約（出力パス・grim 領域）は Task 1（定義）と Task 3/5（利用）で一致。scrim の `W=1100/H=650` と conf の `size = 650`（短辺）は Task 2 と Task 3 で一致し、Task 5 に変更時の同期手順を明記。
