# 壁紙適用と色生成パイプライン再設計 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 壁紙の書き込み経路を冪等な `apply.sh` 1 本に統合し、表示・色・rofi サムネイルの三点不整合を構造的に解消する。

**Architecture:** pyprland の `command` / mode.sh / 手動のすべてが同一の `apply.sh` を同期呼び出しする。正しさは呼び出しタイミングではなく `awww query` の実状態照合（入口の表示照合・出口の表示検証・色メモ化）が担う。awww-daemon は `--no-cache` でキャッシュ復元という隠れた書き手を排除する。

**Tech Stack:** bash / Nix (home-manager) / awww / pyprland / matugen / wallust

**Spec:** `docs/superpowers/specs/2026-08-16-wallpaper-color-pipeline-redesign-design.md`

## Global Constraints

- パッケージ宣言は集約 `packages.nix` のみ。機能ディレクトリの `default.nix` は設定専用（今回パッケージ追加なし）。
- `../` で親ディレクトリへ遡る相対パス参照は禁止。リポジトリ横断参照は `dotfilesDir`、同階層は `lnk ./file`。
- コメントは「なぜ」だけを 1〜2 行。逐条コメント禁止。
- 各タスクの Nix 変更後は `nix run .#fmt -- --fail-on-change` と `nix run .#build` を通す（シェルスクリプトのみの変更は fmt + `bash -n` で足りる。`hypr/scripts` は `lnk` によるディレクトリ symlink 配布のためビルド成果物に影響しない）。
- このリポジトリにはシェルスクリプトの自動テスト基盤がないため、TDD の代わりに「構文検査（`bash -n`）→ fmt → build → 最終タスクでの実機検証チェックリスト」を検証サイクルとする。
- ログイン時の壁紙は pyprland がランダムに選ぶ 1 枚が正（前セッション継続はしない）。

---

### Task 1: apply.sh の新設（set.sh + post.sh の統合）

**Files:**

- Create: `home-manager/desktop/hyprland/scripts/wallpaper/apply.sh`

**Interfaces:**

- Consumes: `~/.config/hypr/scripts/hyprctl-state`（`get` サブコマンド、既存）、`~/.config/hypr/scripts/waybar/reload-css.sh`（既存）
- Produces: `apply.sh <image>` — 引数 1 つ（画像の絶対パス）。成功時 exit 0 で `$XDG_STATE_HOME/hypr/last_wallpaper` と `last_colored` を更新。表示不一致時 exit 1。Task 2〜3 の呼び出し元はこのシグネチャに依存する。

- [ ] **Step 1: apply.sh を作成する**

```bash
#!/usr/bin/env bash
set -euo pipefail

# 壁紙の唯一の書き込み経路。表示(awww)と色(matugen/wallust)の順序をプロセス内の
# 逐次実行で保証する。正しさは呼び出しタイミングではなく awww query の実状態照合が担う。
# 呼び出し元: pyprland wallpapers command / mode.sh / 手動。

STATE="$HOME/.config/hypr/scripts/hyprctl-state"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
LOG="$STATE_DIR/wallpaper-apply.log"
LAST="$STATE_DIR/last_wallpaper"
LAST_COLORED="$STATE_DIR/last_colored"

img="${1:?usage: apply.sh <image>}"
mkdir -p "$STATE_DIR"

log() { printf '[%s pid=%d apply] %s\n' "$(date +%FT%T.%3N)" "$$" "$*" >>"$LOG"; }

# pyprland ローテーションと mode.sh の同時呼び出しを直列化し後勝ちで収束させる
exec {LOCK_FD}>"$STATE_DIR/apply.lock"
flock -x "$LOCK_FD"

if [[ -s $LOG ]] && (($(wc -l <"$LOG") > 2000)); then
  tail -n 1000 "$LOG" >"$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

log "=== invoked img=$img"

displayed() { awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | sort -u; }

apply_img() {
  awww img "$img" \
    --transition-type "$("$STATE" get AWWW_TRANSITION_TYPE)" \
    --transition-fps "$("$STATE" get AWWW_TRANSITION_FPS)" \
    --transition-duration "$("$STATE" get AWWW_TRANSITION_DURATION)" \
    --transition-step "$("$STATE" get AWWW_TRANSITION_STEP)" \
    --transition-bezier "$("$STATE" get AWWW_TRANSITION_BEZIER)"
}

# --- 1. output 揃い待ち ---------------------------------------------------
# ソケット応答だけでは output 0 個でも通る(起動レースの原因)ため monitor 数と照合する。
expected=$(hyprctl monitors -j 2>/dev/null | jq 'length' || echo 0)
[[ $expected =~ ^[0-9]+$ ]] || expected=0
if ((expected > 0)); then
  for _ in $(seq 1 50); do
    (($(awww query 2>/dev/null | wc -l) == expected)) && break
    sleep 0.1
  done
  actual=$(awww query 2>/dev/null | wc -l)
  ((actual == expected)) || log "output wait timeout actual=$actual expected=$expected"
else
  # hyprctl が使えない環境ではソケット応答待ちまで劣化させる
  for _ in $(seq 1 50); do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
  done
fi

# --- 2-4. 表示 ------------------------------------------------------------
if [[ "$(displayed)" == "$img" ]]; then
  # 照合: 同一画像の再適用(mode.sh 経由等)は再描画アニメーションごと省く
  log "display up-to-date, skip img"
else
  apply_img
  # 検証: awww img の正常終了は IPC 受理しか意味しない。実表示を読み直す
  if [[ "$(displayed)" != "$img" ]]; then
    log "verify failed, re-push"
    apply_img
  fi
fi

if [[ "$(displayed)" != "$img" ]]; then
  # 古い画像から色を作らない。無限リトライせず次の契機(次の呼び出し)で収束させる
  log "MISMATCH shown=[$(displayed | paste -sd' ' -)]"
  exit 1
fi

# --- 5-7. 色 ---------------------------------------------------------------
if [[ "$(cat "$LAST_COLORED" 2>/dev/null)" == "$img" ]]; then
  log "colors up-to-date, skip"
else
  declare -a PIDS=() TAGS=()
  PIPELINE_OK=1
  spawn() {
    local tag="$1"
    shift
    ("$@") >>"$LOG" 2>&1 &
    PIDS+=("$!")
    TAGS+=("$tag")
  }
  wait_all() {
    local i rc
    for i in "${!PIDS[@]}"; do
      rc=0
      wait "${PIDS[$i]}" || rc=$?
      ((rc == 0)) || PIPELINE_OK=0
      log "${TAGS[$i]} exit=$rc"
    done
    PIDS=()
    TAGS=()
  }
  # matugen が指定 index で失敗したら 0 で再試行する safety net
  matugen_with_fallback() {
    matugen image "$1" --source-color-index "$2" ||
      matugen image "$1" --source-color-index 0
  }

  # --source-color-index 省略時に非 tty 起動で対話 UI に落ちて失敗するため必須
  if [[ "$("$STATE" get MATUGEN_RANDOM_INDEX)" == "true" ]]; then
    source_idx=$((RANDOM % 4))
  else
    source_idx=$("$STATE" get MATUGEN_SOURCE_INDEX)
  fi
  log "matugen SOURCE_IDX=$source_idx"

  spawn matugen matugen_with_fallback "$img" "$source_idx"
  # wallust: matugen が出さない @color0..15 (Pywal 系) を waybar style 用に追加生成
  spawn wallust wallust run "$img" --quiet
  wait_all

  "$HOME/.config/hypr/scripts/waybar/reload-css.sh" 2>>"$LOG" ||
    log "waybar/reload-css failed rc=$?"
  # ghostty: theme は window 起動時にしか読まれないため SIGUSR2 で reload_config を要求
  pkill -x -SIGUSR2 ghostty 2>>"$LOG" &&
    log "ghostty SIGUSR2 sent" ||
    log "ghostty SIGUSR2 failed rc=$? (no running ghostty?)"
  # Hyprland の $variable は parse 時に値置換されるため新色の伝播に全 reload が必要
  hyprctl reload 2>>"$LOG" || log "hyprctl reload failed rc=$?"

  # 失敗時は記録しない → 次の呼び出しが色生成を再試行できる
  if ((PIPELINE_OK)); then
    echo "$img" >"$LAST_COLORED"
  fi
fi

# --- 8. 記録 ---------------------------------------------------------------
echo "$img" >"$LAST"
log "=== complete last_wallpaper=$img"
```

- [ ] **Step 2: 実行権限を付与し構文検査する**

Run: `chmod +x home-manager/desktop/hyprland/scripts/wallpaper/apply.sh && bash -n home-manager/desktop/hyprland/scripts/wallpaper/apply.sh`
Expected: 出力なし（構文エラーなし）

- [ ] **Step 3: fmt を通す**

Run: `nix run .#fmt -- --fail-on-change`
Expected: exit 0（shfmt の整形差分があれば `nix run .#fmt` で整形してから再実行）

- [ ] **Step 4: Commit**

```bash
git add home-manager/desktop/hyprland/scripts/wallpaper/apply.sh
git commit -m "feat(wallpaper): 冪等な apply.sh を新設し表示と色の逐次保証を1本化"
```

---

### Task 2: pyprland の配線変更と旧スクリプトの削除

**Files:**

- Modify: `home-manager/desktop/pyprland/default.nix`（`[wallpapers]` セクションと awww-daemon の ExecStart）
- Delete: `home-manager/desktop/hyprland/scripts/wallpaper/set.sh`
- Delete: `home-manager/desktop/hyprland/scripts/wallpaper/post.sh`

**Interfaces:**

- Consumes: Task 1 の `apply.sh <image>`
- Produces: pyprland が壁紙適用のたびに `apply.sh` を 1 回だけ呼ぶ構成。awww-daemon はキャッシュ復元なしで起動する。

- [ ] **Step 1: pyprland/default.nix の `[wallpapers]` を書き換える**

現在の 2 行:

```toml
    command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/set.sh [file]"
    post_command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/post.sh [file]"
```

を次の 1 行に置き換える（post_command は廃止。表示と色の順序は apply.sh 内で保証するため分割フックは不要）:

```toml
    command = "${config.home.homeDirectory}/.config/hypr/scripts/wallpaper/apply.sh [file]"
```

- [ ] **Step 2: awww-daemon に --no-cache を付ける**

同ファイルの:

```nix
      ExecStart = "${pkgs.awww}/bin/awww-daemon";
```

を次に置き換える:

```nix
      # キャッシュ復元は apply.sh を通らない隠れた書き手になるため無効化。
      # 起動時の壁紙は pyprland のランダム1枚が正(spec 参照)。
      ExecStart = "${pkgs.awww}/bin/awww-daemon --no-cache";
```

- [ ] **Step 3: 旧スクリプトを削除する**

```bash
git rm home-manager/desktop/hyprland/scripts/wallpaper/set.sh \
       home-manager/desktop/hyprland/scripts/wallpaper/post.sh
```

- [ ] **Step 4: 参照残りがないことを確認する**

Run: `grep -rn "set\.sh\|post\.sh" home-manager/ nixos/ hosts/ lib/ --include="*.nix" --include="*.sh" --include="*.lua"`
Expected: ヒットなし（docs/ 内の過去の設計文書は対象外でよい）

- [ ] **Step 5: fmt と build を通す**

Run: `nix run .#fmt -- --fail-on-change && nix run .#build`
Expected: 両方 exit 0

- [ ] **Step 6: Commit**

```bash
git add -A home-manager/desktop/pyprland/default.nix home-manager/desktop/hyprland/scripts/wallpaper/
git commit -m "feat(wallpaper): pyprland を apply.sh 1本呼びに変更し awww キャッシュ復元を廃止"
```

---

### Task 3: mode.sh の壁紙処理を apply.sh へ委譲

**Files:**

- Modify: `home-manager/desktop/hyprland/scripts/mode.sh`

**Interfaces:**

- Consumes: Task 1 の `apply.sh <image>`、`$XDG_STATE_HOME/hypr/last_wallpaper`（apply.sh が成功時に書く）
- Produces: mode.sh はモニタ構成切替に純化し、壁紙は configreloaded 後の `apply.sh` 委譲 1 行になる。

- [ ] **Step 1: 壁紙ブロックを委譲に置き換える**

mode.sh の以下のブロック（awww ポーリングから `awww restore` フォールバックまで）:

```bash
# awww-daemon は wayland output 通知経由で反映するので configreloaded 後でも
# 数十ms ラグが残る可能性がある。短い poll で確認 (旧 100ms×10 → 50ms×5)。
expected=$(hyprctl monitors -j 2>/dev/null | jq 'length')
for _ in {1..5}; do
  (($(awww query 2>/dev/null | wc -l) == expected)) && break
  sleep 0.05
done

# Hyprland はモニター構成変更を layer surface に伝播しないバグがあるため awww と waybar を作り直す。
# `awww restore` は disable 中だったモニターのキャッシュが残ってモード間で壁紙が割れるので last_wallpaper を明示適用する。
LAST="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last_wallpaper"
if [[ -f $LAST ]] && [[ -r "$(<"$LAST")" ]]; then
  awww img --transition-type none "$(<"$LAST")" >/dev/null 2>&1 || true
else
  awww restore >/dev/null 2>&1 || true
fi
```

を次に置き換える（output 揃い待ちと表示検証は apply.sh 側に吸収される。last_wallpaper が無い初回は pyprland の起動時適用が正を作るのでスキップでよい）:

```bash
# 壁紙は apply.sh(唯一の書き込み経路)へ委譲。output 待ち・表示検証・色の整合は
# apply.sh 内の実状態照合が担う。last_wallpaper 不在時は pyprland の適用に任せる。
LAST="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last_wallpaper"
if [[ -f $LAST ]] && [[ -r "$(<"$LAST")" ]]; then
  "$HOME/.config/hypr/scripts/wallpaper/apply.sh" "$(<"$LAST")" >/dev/null 2>&1 || true
fi
```

直後の waybar 再起動とワークスペース復帰の処理は変更しない。

- [ ] **Step 2: 構文検査と fmt**

Run: `bash -n home-manager/desktop/hyprland/scripts/mode.sh && nix run .#fmt -- --fail-on-change`
Expected: exit 0

- [ ] **Step 3: Commit**

```bash
git add home-manager/desktop/hyprland/scripts/mode.sh
git commit -m "refactor(hyprland): mode.sh の壁紙処理を apply.sh へ委譲し書き込み経路を一本化"
```

---

### Task 4: rofi サムネイルの情報源を実表示に変更

**Files:**

- Modify: `home-manager/desktop/rofi/launch.sh`

**Interfaces:**

- Consumes: `awww query` の出力形式（`... currently displaying: image: <path>` 行）
- Produces: rofi の imagebox 背景が常に実表示と一致する。

- [ ] **Step 1: launch.sh の情報源を awww query に変更する**

現在の行:

```bash
wp="$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/hypr/last_wallpaper" 2>/dev/null || true)"
```

を次に置き換える（last_wallpaper は「apply.sh が最後に成功した記録」であり実表示と乖離しうる。実表示そのものを読む。複数 output は先頭を使う）:

```bash
wp="$(awww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -n1 || true)"
```

後続の `[[ -n $wp && -f $wp ]]` ガードは変更しない（daemon 停止時や色指定壁紙時は空/非ファイルになり、imagebox なしで一覧を出す既存動作に倒れる）。

- [ ] **Step 2: 構文検査と fmt**

Run: `bash -n home-manager/desktop/rofi/launch.sh && nix run .#fmt -- --fail-on-change`
Expected: exit 0

- [ ] **Step 3: Commit**

```bash
git add home-manager/desktop/rofi/launch.sh
git commit -m "fix(rofi): サムネ背景の情報源を last_wallpaper から awww の実表示に変更"
```

---

### Task 5: waybar style.css の実ファイル化と reload の修復

**Files:**

- Modify: `home-manager/desktop/waybar/default.nix`
- Modify: `.claude/CLAUDE.md`（waybar セクションの配布機構の記述 1 文）

**Interfaces:**

- Consumes: `home-manager/desktop/waybar/style.nix`（CSS 文字列を返す。単一情報源のまま）
- Produces: `~/.config/waybar/style.css` が書き込み可能な実ファイルになり、`reload-css.sh` の O_TRUNC 書き直しが成功する。

- [ ] **Step 1: waybar/default.nix を書き換える**

現在の内容:

```nix
{
  lnk,
  username,
  ...
}:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [
      (import ./bar.nix // import ./modules.nix { inherit username; })
    ];
    style = import ./style.nix;
  };
  xdg.configFile."waybar/scripts".source = lnk ./scripts;
}
```

を次に置き換える:

```nix
{
  lnk,
  lib,
  pkgs,
  username,
  ...
}:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = [
      (import ./bar.nix // import ./modules.nix { inherit username; })
    ];
  };
  xdg.configFile."waybar/scripts".source = lnk ./scripts;

  # style.css は reload-css.sh が O_TRUNC で書き直して reload_style_on_change を
  # 発火させるため、store への symlink ではなく書き込み可能な実ファイルとして配布する。
  # 情報源は style.nix のまま。switch のたびに上書きされ手編集は残らない。
  home.activation.waybarStyle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    t="$HOME/.config/waybar/style.css"
    $DRY_RUN_CMD rm -f "$t"
    $DRY_RUN_CMD install -Dm644 ${pkgs.writeText "waybar-style.css" (import ./style.nix)} "$t"
  '';
}
```

- [ ] **Step 2: CLAUDE.md の waybar セクションの記述を現実に合わせる**

`.claude/CLAUDE.md` の waybar セクションにある文:

```
`style` として `programs.waybar.style` に渡り、home-manager がビルド時に評価して `style.css` を生成するので、反映は `nix run .#switch` のみ（手動生成スクリプトは無い）。
```

を次に置き換える:

```
`style.nix` の評価結果は home.activation が書き込み可能な実ファイル `style.css` として配布する（reload-css.sh の O_TRUNC 書き直しで reload_style_on_change を発火させるため symlink にしない）。反映は `nix run .#switch` のみ（手動生成スクリプトは無い）。
```

- [ ] **Step 3: fmt と build を通す**

Run: `nix run .#fmt -- --fail-on-change && nix run .#build`
Expected: 両方 exit 0

- [ ] **Step 4: Commit**

```bash
git add home-manager/desktop/waybar/default.nix .claude/CLAUDE.md
git commit -m "fix(waybar): style.css を実ファイル配布に変更し reload-css の書き直しを修復"
```

---

### Task 6: 実機反映と検証

**Files:**

- なし（反映と検証のみ）

**Interfaces:**

- Consumes: Task 1〜5 のすべて

- [ ] **Step 1: switch で反映する**

Run: `nix run .#switch`
Expected: exit 0。`systemctl --user status awww-daemon pyprland` が両方 active で、awww-daemon の CommandLine に `--no-cache` が含まれる。

- [ ] **Step 2: 通常の壁紙切替を検証する**

Run: `pypr wall next` を実行後、次で三点一致を確認する:

```bash
awww query | sed -n 's/.*currently displaying: image: //p' | sort -u
cat ~/.local/state/hypr/last_wallpaper
cat ~/.local/state/hypr/last_colored
tail -n 20 ~/.local/state/hypr/wallpaper-apply.log
```

Expected: 3 つの出力が同一画像パス。log に `MISMATCH` と `waybar/reload-css failed` が無い。waybar・rofi の色が新画像に追従している。

- [ ] **Step 3: 冪等性を検証する**

Run: 同一画像で `~/.config/hypr/scripts/wallpaper/apply.sh "$(cat ~/.local/state/hypr/last_wallpaper)"` を手動実行し、log を確認する。
Expected: `display up-to-date, skip img` と `colors up-to-date, skip` が記録され、画面の再描画アニメーションが起きない。

- [ ] **Step 4: モード切替を検証する**

Run: SUPER+SHIFT+B（bed）→ SUPER+SHIFT+D（desk）で往復する。
Expected: 各切替後に全モニタが同一壁紙（割れなし）。壁紙と色は切替前から変わらない（log は `display up-to-date` または apply 成功のみ。色生成はスキップされる）。waybar が再起動して表示される。

- [ ] **Step 5: rofi のサムネ一致を検証する**

Run: SUPER+A で rofi を開く。
Expected: imagebox 背景が現在表示中の壁紙と同一。

- [ ] **Step 6: 再ログインで起動レースの解消を検証する**

Run: ログアウト → ログイン後、Step 2 と同じ三点一致確認を行う。
Expected: 三点が pyprland の選んだ 1 枚（前セッションと異なっていてよい）で一致する。`awww query` に前セッションの画像が残っていない。

- [ ] **Step 7: 変更を push する**

```bash
git push
```

（main 直 push のため、ローカル build 済みであることが前提。CI は後追いの保険。）
