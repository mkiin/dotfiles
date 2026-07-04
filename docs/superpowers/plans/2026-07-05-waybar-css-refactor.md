# waybar 表示密度と CSS クラス構造リファクタ 実装プラン

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** waybar の間隔を詰めて center/right の島衝突を解消し、CSS を「役割 = クラス、個体 = ID」の 7 層構造にリファクタする。

**Architecture:** 設定（settings/_.nix）とスタイル（style/_.nix → render.sh で style.css 生成）の 2 系統を、settings 側 3 タスク → CSS 再構成 1 タスク → トークン縮小 1 タスク → 統合検証 1 タスクの順で変更する。CSS 再構成タスクは見た目が変わらない純リファクタ、トークン縮小タスクだけが密度を変えるので、視覚的な問題の切り分けが commit 単位でできる。

**Tech Stack:** Nix (home-manager), waybar, GTK3 CSS

**Spec:** `docs/superpowers/specs/2026-07-05-waybar-css-refactor-design.md`

## Global Constraints

- `home-manager/desktop/waybar/style.css` は生成物。**手編集禁止**。変更は `style/tokens.nix`・`style/mk-style.nix` を編集して `bash home-manager/desktop/waybar/style/render.sh` で再生成する。
- CSS の寸法値（px）は必ず tokens.nix のトークン参照（`${t.xxx}`）で書く。個別ルールへの px 直書き禁止。
- 各タスクの完了時に `nix run .#fmt -- --fail-on-change` が exit 0 であること（deadnix 検出含む）。
- push 前に `nix run .#build` を通す（最終タスクで実施）。
- コミットメッセージは既存流儀に合わせる: `refactor(waybar): 日本語サマリ` 形式。
- リポジトリルート: `/home/mkiin/ghq/github.com/mkiin/dotfiles`。コマンドはすべてルートで実行。

## 前提知識（waybar の CSS 命名機構）

- 設定キーの `#` サフィックス（`<module>#<id>`、`group/<name>#<id>`)は可視ノードに **CSS クラス**として付与される。設定キー自体も `#` 込みの文字列で参照する（既存の `"group/launcher#island"` と同じ）。
- 全モジュールの可視ノード（label/box）には `.module` クラスが自動付与される。
- `hyprland/window#island` にすると label が `.island` と `.module` を両方持つが、`.island .module` は子孫コンビネータなので**自分自身にはマッチしない**（島の質感が透明化ルールに食われる事故は起きない）。
- privacy モジュールは id クラスを可視ノードに付けない実装のため、ロールクラスを配れない。ID ルールで扱う。

---

### Task 1: sysstats の drawer 廃止と temperature 削除

**Files:**

- Modify: `home-manager/desktop/waybar/settings/bar.nix:37-49`
- Modify: `home-manager/desktop/waybar/settings/modules.nix:63-69`

**Interfaces:**

- Consumes: なし
- Produces: `group/sysstats#island` は `modules = [ "cpu" "memory" ]` の常時表示グループになる。`temperature` モジュールは設定から消滅する（Task 4 の CSS 再構成は `#temperature.critical` ルールを含めない前提で書かれている）。

- [ ] **Step 1: bar.nix の sysstats グループから drawer と temperature を消す**

`home-manager/desktop/waybar/settings/bar.nix` の以下のブロック:

```nix
  "group/sysstats#island" = {
    orientation = "horizontal";
    drawer = {
      transition-duration = 500;
      children-class = "not-cpu";
      transition-left-to-right = false;
    };
    modules = [
      "cpu"
      "temperature"
      "memory"
    ];
  };
```

を次に置き換える:

```nix
  "group/sysstats#island" = {
    orientation = "horizontal";
    modules = [
      "cpu"
      "memory"
    ];
  };
```

- [ ] **Step 2: modules.nix から temperature 定義を削除**

`home-manager/desktop/waybar/settings/modules.nix` から以下のブロックを丸ごと削除する:

```nix
  temperature = {
    hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
    interval = 5;
    critical-threshold = 80;
    format = "󰔏 {temperatureC}°C";
    format-critical = "󰔏 {temperatureC}°C ";
  };
```

- [ ] **Step 3: eval で構文検証**

Run:

```bash
nix eval --impure --expr 'import ./home-manager/desktop/waybar/settings/bar.nix' --json >/dev/null && nix eval --impure --expr 'import ./home-manager/desktop/waybar/settings/modules.nix { username = "mkiin"; }' --json | grep -c temperature
```

Expected: `0`（temperature への参照が残っていない。grep -c が 0 で exit 1 になるのは想定どおりなので `|| true` を付けてよい）

- [ ] **Step 4: fmt 検証**

Run: `nix run .#fmt -- --fail-on-change`
Expected: exit 0

- [ ] **Step 5: Commit**

```bash
git add home-manager/desktop/waybar/settings/bar.nix home-manager/desktop/waybar/settings/modules.nix
git commit -m "refactor(waybar): sysstatsのdrawerを廃止しcpu+memory常時表示に、temperatureを削除"
```

---

### Task 2: pulseaudio マイク統合と network アイコン化

**Files:**

- Modify: `home-manager/desktop/waybar/settings/modules.nix`（pulseaudio と network のブロック）

**Interfaces:**

- Consumes: なし
- Produces: pulseaudio がスピーカーとマイクを併記（`󰕾 40% 󰍬 35%`）、network はアイコンのみ表示。

- [ ] **Step 1: pulseaudio の format にマイクを統合**

`home-manager/desktop/waybar/settings/modules.nix` の pulseaudio ブロックを次に置き換える（format 系 5 行の変更と format-source 2 行の追加。format-icons 以下は現状のまま）:

```nix
  pulseaudio = {
    format = "{icon} {volume}% {format_source}";
    format-bluetooth = "{icon} 󰂰 {volume}% {format_source}";
    format-muted = "󰝟 {volume}% {format_source}";
    format-source = "󰍬 {volume}%";
    format-source-muted = "󰍭";
    format-icons = {
      headphone = "󰋋";
      hands-free = "󰜟";
      headset = "󰋎";
      default = [
        "󰕿"
        "󰖀"
        "󰕾"
      ];
    };
    on-click = "qs -c audio -n";
    # クリックはセレクタ起動に一本化し、スクロール音量変更は無効化
    scroll-step = 0;
    ignored-sinks = [ "Easy Effects Sink" ];
  };
```

- [ ] **Step 2: network をアイコンのみに**

同ファイルの network ブロックの 2 行を変更する:

```nix
    format-wifi = "󰖩";
    format-ethernet = "󰈀";
```

（変更前は `"󰖩 wifi"` / `"󰈀 ethernet"`。`format` と `format-disconnected`、tooltip 系は変更しない）

- [ ] **Step 3: eval と fmt で検証**

Run:

```bash
nix eval --impure --expr 'import ./home-manager/desktop/waybar/settings/modules.nix { username = "mkiin"; }' --json >/dev/null && nix run .#fmt -- --fail-on-change
```

Expected: どちらも exit 0

- [ ] **Step 4: Commit**

```bash
git add home-manager/desktop/waybar/settings/modules.nix
git commit -m "feat(waybar): pulseaudioにマイク音量を併記、networkをアイコンのみに短縮"
```

---

### Task 3: `#` サフィックスによる改名（island/accent クラスの配布）

**Files:**

- Modify: `home-manager/desktop/waybar/settings/bar.nix`
- Modify: `home-manager/desktop/waybar/settings/modules.nix`

**Interfaces:**

- Consumes: なし
- Produces: 可視ノードに `.island`（hyprland/window）と `.accent`（custom/nix、custom/power）クラスが付く。group の box ノード名が `#ws` になり `#workspaces` はモジュール専用 ID になる。**Task 4 の CSS はこれらのクラス名・ノード名を前提とする。**

このタスク単独では見た目は変わらない（`.island` は既存 `#window` ルールと同値、`.accent` はまだ CSS に存在せず、既存の `#custom-nix`/`#custom-power` ID ルールが引き続き効く）。

- [ ] **Step 1: bar.nix の参照を改名**

`home-manager/desktop/waybar/settings/bar.nix` で以下 4 箇所を変更する:

```nix
  modules-left = [
    "group/launcher#island"
    "hyprland/window#island"
  ];
  modules-center = [
    "group/ws#island"
    "group/datetime#island"
  ];
```

group キーとモジュール参照:

```nix
  "group/launcher#island" = {
    orientation = "horizontal";
    modules = [ "custom/nix#accent" ];
  };
  "group/ws#island" = {
    orientation = "horizontal";
    modules = [ "hyprland/workspaces" ];
  };
```

control-center グループ内:

```nix
    modules = [
      "custom/idle_inhibitor"
      "custom/notify"
      "custom/power#accent"
    ];
```

- [ ] **Step 2: modules.nix の設定キーを改名**

`home-manager/desktop/waybar/settings/modules.nix` で 3 つのキーを改名する（値は変更しない）:

- `"custom/nix"` → `"custom/nix#accent"`
- `"hyprland/window"` → `"hyprland/window#island"`
- `"custom/power"` → `"custom/power#accent"`

- [ ] **Step 3: 参照とキーの対応を検証**

Run:

```bash
nix eval --impure --expr 'let b = import ./home-manager/desktop/waybar/settings/bar.nix; m = import ./home-manager/desktop/waybar/settings/modules.nix { username = "mkiin"; }; refs = b.modules-left ++ b.modules-center ++ b.modules-right ++ b."group/launcher#island".modules ++ b."group/ws#island".modules ++ b."group/datetime#island".modules ++ b."group/sysstats#island".modules ++ b."group/status#island".modules ++ b."group/control-center#island".modules; all = b // m; in builtins.filter (r: !(builtins.hasAttr r all) && !(builtins.elem r [ "hyprland/workspaces" ])) refs'
```

Expected: `[ ]`（bar が参照する全モジュール名が、group キーか modules.nix のキーに解決される。hyprland/workspaces は modules.nix にキーがあるので除外リストから外してもよいが、上式は defensive に除外している）

- [ ] **Step 4: fmt 検証**

Run: `nix run .#fmt -- --fail-on-change`
Expected: exit 0

- [ ] **Step 5: Commit**

```bash
git add home-manager/desktop/waybar/settings/bar.nix home-manager/desktop/waybar/settings/modules.nix
git commit -m "refactor(waybar): #サフィックスでisland/accentクラスを配布しws名前衝突を解消"
```

---

### Task 4: mk-style.nix の 7 層レイヤ再構成

**Files:**

- Modify: `home-manager/desktop/waybar/style/mk-style.nix`（全面書き換え）
- Regenerate: `home-manager/desktop/waybar/style.css`（render.sh 経由。手編集しない）

**Interfaces:**

- Consumes: Task 3 が配布した `.island`（hyprland/window の label）、`.accent`（custom/nix、custom/power）、group ノード名 `#ws`。Task 1 で temperature が消えている前提（`#temperature.critical` ルールは書かない）。
- Produces: 7 層構造の style.css。トークン名は現行 tokens.nix のまま（Task 5 で値だけ変える）。

このタスクは見た目が変わらない純リファクタ（層の整理と例外の解消のみ。全トークン値は現状維持）。

- [ ] **Step 1: mk-style.nix を全面書き換え**

`home-manager/desktop/waybar/style/mk-style.nix` を次の内容に置き換える:

```nix
# tokens.nix を受けて style.css の中身を返す。render.sh から使う。
t: ''
  /* ===== 生成ファイル: 手編集禁止 =====
   * 寸法・質感は style/tokens.nix で変更し、style/render.sh で再生成する。
   * レイヤ構造 (カスケード順に単方向。下の層は上の層の寸法を上書きしない):
   *   0 Reset / 1 Bar / 2 Island / 3 Module / 4 Component / 5 Role,State / 6 Surface
   * 色は matugen 生成の colors.css (MD3 トークン) のみに依存。
   * すりガラスは hyprland 側 layerrule が担当。 */

  @import "colors.css";

  @define-color glass_tint ${t.glassTint};
  @define-color glass_border ${t.glassBorder};
  /* tooltip は blur が乗らない別サーフェスなので濃いめにして可読性を確保 */
  @define-color tooltip_bg ${t.tooltipBg};

  /* ============================================================
     0 Reset: box-model の初期化と GTK テーマ既定装飾の無効化のみ
     ============================================================ */
  * {
    border: none;
    border-radius: 0;
    margin: 0;
    padding: 0;
    min-height: 1px;
  }

  button,
  button:hover,
  button:focus,
  button:focus-visible {
    box-shadow: none;
    outline: none;
    text-shadow: none;
    background-image: none;
  }

  tooltip,
  tooltip label {
    background-image: none;
    box-shadow: none;
    text-shadow: none;
  }

  /* ============================================================
     1 Bar: タイポグラフィと基調色 (font 系は GTK CSS で継承される)
     ============================================================ */
  window#waybar {
    background-color: transparent;
    color: @on_surface;
    font-family:
      "JetBrainsMono Nerd Font", "Iosevka Nerd Font", "Font Awesome 6 Free";
    font-size: ${t.fontSize};
  }

  /* ============================================================
     2 Island: ガラス質感と島同士の間隔
     `group/<name>#island` と `hyprland/window#island` の可視ノードが
     .island クラスを持つ (waybar の #サフィックス機構)。
     ============================================================ */
  .island {
    background-color: @glass_tint;
    border: 1px solid @glass_border;
    border-radius: ${t.radiusIsland};
    padding: 0 ${t.padIslandX};
    margin: 0 ${t.gapIsland};
    color: @on_surface;
  }

  /* フォーカスウィンドウが無いときは window 島を消灯 */
  window#waybar.empty #window {
    background-color: transparent;
    border: none;
    padding: 0;
    margin: 0;
  }

  /* ============================================================
     3 Module: 島の背景に乗るだけ。間隔は margin で取る
     (GTK3 は eventbox への padding をレイアウトに反映しない)。
     子孫コンビネータなので .island.module を両方持つ window の
     label 自身にはマッチしない。
     ============================================================ */
  .island .module {
    background-color: transparent;
    margin: 0 ${t.gapModule};
    padding: 0;
  }

  /* ============================================================
     4 Component: workspaces
     非アクティブは小ドット (文字色を透明にして丸だけ見せる)、
     アクティブは @primary の横長ピル。
     ============================================================ */
  #workspaces button {
    min-width: ${t.wsDotSize};
    min-height: ${t.wsDotSize};
    padding: 0;
    margin: ${t.wsDotMarginY} ${t.wsDotGap};
    color: transparent;
    background-color: alpha(@on_surface, 0.35);
    border-radius: ${t.radiusIsland};
    transition:
      background 0.25s cubic-bezier(0.4, 0, 0.2, 1),
      color 0.25s cubic-bezier(0.4, 0, 0.2, 1),
      min-width 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  }

  #workspaces button.active {
    color: @on_primary;
    background-color: @primary;
    min-width: ${t.wsActiveMinWidth};
  }

  #workspaces button:hover {
    background-color: @secondary_container;
    color: @on_secondary_container;
  }

  #workspaces button.urgent {
    background-color: @error;
    color: @on_error;
  }

  #workspaces button.special {
    color: @on_tertiary;
    background-color: @tertiary;
  }

  /* ============================================================
     5 Role, State: 色のみ。寸法を持たない。
     .accent は #サフィックスで配るロールクラス (custom/nix, custom/power)。
     privacy は id クラス非対応の実装なので ID 指定で残す。
     状態クラス (.muted 等) は waybar が動的に付与する。
     ============================================================ */
  .accent,
  #privacy {
    color: @primary;
  }

  #network.disconnected {
    color: @state_critical;
  }

  #pulseaudio.muted {
    color: @primary;
  }

  #custom-idle_inhibitor.activated {
    color: @primary;
  }

  #custom-notify.dnd-none,
  #custom-notify.dnd-notification,
  #custom-notify.dnd-inhibited-none,
  #custom-notify.dnd-inhibited-notification {
    color: @primary;
  }

  /* ============================================================
     6 Surface: tooltip (バー外の別サーフェス)
     ============================================================ */
  tooltip {
    background-color: @tooltip_bg;
    border: 1px solid @glass_border;
    border-radius: ${t.radiusTooltip};
    padding: ${t.padTooltip};
  }

  tooltip label {
    color: @on_surface;
    padding: ${t.padTooltipLabel};
  }
''
```

旧版から消えたもの（意図的な削除）:

- `.island, #window` の列挙 → `.island` 単独（Task 3 で `#island` id を付けたため）
- `#custom-nix` と `#custom-power` の ID ルール → `.accent` に集約
- `#temperature.critical` → Task 1 で temperature ごと削除済み
- `*` 内の font 指定 → 層 1 `window#waybar` へ移動（継承で全体に効く）
- `.island .module` 内の `border: none; border-radius: 0;` → Reset 層が既に保証

- [ ] **Step 2: style.css を再生成**

Run: `bash home-manager/desktop/waybar/style/render.sh`
Expected: `rendered: /home/mkiin/ghq/github.com/mkiin/dotfiles/home-manager/desktop/waybar/style.css`

- [ ] **Step 3: 差分を目視確認**

Run: `git diff home-manager/desktop/waybar/style.css`
Expected: 上記「消えたもの」に対応する削除と、層コメントの再編成だけが出る。トークン由来の寸法値（12px、9px、20px 等）は**一切変わっていない**こと。

- [ ] **Step 4: 実機で見た目が変わっていないことを確認**

style.css は lnk 経由でライブ反映される（`reload_style_on_change`）。ただし settings 変更（Task 1〜3）は switch するまで実機に載らないため、この時点の実機は「旧 settings + 新 CSS」の組み合わせになる。旧 settings では `#window` に `.island` が無く、**window 島だけ質感が消えて見える（想定内・switch で解消）**。それ以外（他の島の質感・間隔・workspaces の丸）が変わっていないことを確認する。

- [ ] **Step 5: fmt 検証と Commit**

Run: `nix run .#fmt -- --fail-on-change`
Expected: exit 0

```bash
git add home-manager/desktop/waybar/style/mk-style.nix home-manager/desktop/waybar/style.css
git commit -m "refactor(waybar): style.cssを7層レイヤ構造に再編、#window例外とID列挙を解消"
```

---

### Task 5: 間隔トークンの縮小

**Files:**

- Modify: `home-manager/desktop/waybar/style/tokens.nix:6-9`
- Regenerate: `home-manager/desktop/waybar/style.css`

**Interfaces:**

- Consumes: Task 4 の 7 層 CSS（gapIsland / gapModule の意味は変わらない）
- Produces: モジュール間 14px、島間 12px の密度

- [ ] **Step 1: tokens.nix の 2 トークンを縮小**

`home-manager/desktop/waybar/style/tokens.nix` の該当 2 行を変更する。gapModule のコメントは実装（margin）と食い違っている（「片側パディング」と書かれている）ので、あわせて直す:

```nix
  # 島の外側
  gapIsland = "6px"; # 島同士の間隔 (片側マージン)
  # 島の内側
  padIslandX = "12px"; # 島の左右パディング
  gapModule = "7px"; # 島内モジュール間 (片側マージン。モジュール間は 2 倍効く)
```

- [ ] **Step 2: style.css を再生成**

Run: `bash home-manager/desktop/waybar/style/render.sh`
Expected: `rendered: .../style.css`。`git diff home-manager/desktop/waybar/style.css` で変わるのは `margin: 0 9px` → `margin: 0 6px`（island）と `margin: 0 12px` → `margin: 0 7px`（module）の 2 箇所のみ。

- [ ] **Step 3: 実機で密度を確認**

CSS はライブ反映される。バーを見て、モジュール間と島間が詰まったこと、島同士が重ならないことを確認する。

- [ ] **Step 4: fmt 検証と Commit**

Run: `nix run .#fmt -- --fail-on-change`
Expected: exit 0

```bash
git add home-manager/desktop/waybar/style/tokens.nix home-manager/desktop/waybar/style.css
git commit -m "feat(waybar): 間隔トークンを縮小(gapModule 7px, gapIsland 6px)"
```

---

### Task 6: 統合検証

**Files:** なし（検証のみ）

**Interfaces:**

- Consumes: Task 1〜5 の全コミット
- Produces: push 可能な検証済み main

- [ ] **Step 1: フルビルド**

Run: `nix run .#build`
Expected: 正常終了（エラーなし）。時間がかかる。

- [ ] **Step 2: fmt 最終確認**

Run: `nix run .#fmt -- --fail-on-change`
Expected: exit 0

- [ ] **Step 3: switch と実機確認（ユーザー操作）**

settings 変更（Task 1〜3）は switch しないと実機に載らない。ユーザーに以下を依頼する:

```
! nix run .#switch
```

switch 後の確認項目:

- sysstats 島に cpu と memory が常時 2 つ並ぶ（hover 展開なし）
- pulseaudio が `󰕾 40% 󰍬 35%` の形式（マイクミュート時は 󰍭 のみ）
- network がアイコンのみ
- window 島の質感が復活している（Task 4 Step 4 の一時的な消灯が解消）
- 空ワークスペースにフォーカスすると window 島が消灯する
- custom/nix と custom/power が primary 色のまま
- 間隔: モジュール間 14px、島間 12px 相当の密度

- [ ] **Step 4: push**

確認が取れたら `git push` する（CI は後追いの保険）。
