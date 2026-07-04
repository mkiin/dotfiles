# waybar リファクタ実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** waybar をダークグラス・アイランドの単一スタイルに一新し、島構造を主要 OS の UI に倣った group 6 島 + 例外 1（window）に組み直し、config.json を Nix 分割構成に置き換える。

**Architecture:** `programs.waybar.settings` を Nix（`settings/bar.nix` + `settings/modules.nix`）で構成する。バーに載る要素は原則 group（`group/<名前>#island`）とし、CSS は `.island` 単一クラス + `.island > *` リセット + 状態セレクタの 3 層だけで描く。すりガラスは Hyprland の layerrule（blur + ignore_alpha）で実現する。

**Tech Stack:** NixOS / home-manager, waybar (GTK CSS), Hyprland Lua config, matugen

**Spec:** `docs/superpowers/specs/2026-07-05-waybar-refactor-design.md`

## Global Constraints

- パッケージ宣言は集約 `packages.nix` のみ。機能ディレクトリの `default.nix` に `home.packages` を書かない（今回の変更で新規パッケージは不要）。
- 各タスクの検証は `nix run .#build` と `nix run .#fmt -- --fail-on-change` を両方通すこと。
- main へ push する前にローカルビルドを通す運用（CI は後追いの保険）。push はユーザーが行う。
- コミットメッセージは既存規約に従い `type(scope): 日本語要約` 形式（例: `feat(waybar): ...`）。
- コメントは「なぜ」だけを 1〜2 行。逐条コメント禁止（treefmt の deadnix / fmt を通す）。
- 実機反映（`nix run .#switch`）と目視確認は Task 4。Task 1〜3 はビルド検証のみで進めてよい。

## 前提知識（このリポジトリ固有）

- `lnk` は home-manager モジュールに渡される、リポジトリ内ファイルへの out-of-store symlink ヘルパー。`xdg.configFile."...".source = lnk ./file;` で使う。編集が rebuild なしに実ファイルへ反映される。
- `username` も同様に specialArgs でモジュールに渡ってくる（値は `mkiin`）。
- `~/.config/waybar/colors.css` は matugen が生成する Material Design 3 トークン（`@primary`, `@surface_container`, `@on_surface`, `@error` など全 MD3 色 + `@state_success/warning/critical`）。初回起動時のフォールバック生成は `home-manager/desktop/matugen/default.nix` の activation に**実装済み**。
- `colors-waybar.css`（wallust 生成）は今回 waybar から参照を外すが、wlogout が使うため wallust 側のフォールバックは触らない。
- Hyprland 設定は Lua（`home-manager/desktop/hyprland/lua/*.lua`）。`hl.layer_rule({...})` の書式は `rules.lua` 末尾に既存例あり。`ignore_alpha` は `HL.LayerRuleSpec` でサポート確認済み。
- `hyprland/scripts/waybar/reload-css.sh` は壁紙切替の `post.sh` から呼ばれているため**削除しない**。
- waybar の group 名 `group/<name>#<class>` の `#<class>` 部分は、その group ウィジェットの CSS クラスになる。本計画では全 group を `#island` で統一する。

---

### Task 1: settings の Nix 化と島構造の組み直し（config.json 廃止）

**Files:**

- Create: `home-manager/desktop/waybar/settings/bar.nix`
- Create: `home-manager/desktop/waybar/settings/modules.nix`
- Modify: `home-manager/desktop/waybar/default.nix`（全面書き換え）
- Delete: `home-manager/desktop/waybar/config.json`, `home-manager/desktop/waybar/scripts/pkg-update/`

**Interfaces:**

- Consumes: モジュール引数 `username`（specialArgs、値 `mkiin`）
- Produces:
  - `settings/bar.nix` … 引数なしの attrset。レイアウトと group 定義。**group 名はすべて `group/<name>#island` 形式**（`#island` が CSS の `.island` クラスになる。Task 2 の CSS がこれに依存）
  - `settings/modules.nix` … `{ username }: attrset`。全モジュール定義
  - バーに載るモジュール ID（Task 2 の CSS セレクタがこれに依存）: `custom/nix`, `hyprland/window`, `hyprland/workspaces`, `custom/time`, `custom/date`, `custom/weather`, `cpu`, `temperature`, `memory`, `network`, `bluetooth`, `pulseaudio`, `privacy`, `tray`, `custom/idle_inhibitor`, `custom/control-center`, `custom/power`

このタスクで削除するもの: `custom/mise`（表示ごと廃止。`scripts/pkg-update/` も使用者がいなくなる）、`custom/separator`、旧 config.json の未使用定義（`battery`, `backlight`, `cava`, `custom/temperature`, `custom/light`）、CSS の管轄である最上位 `font` キー。
改名: 通知ベルは swaync を使っていない（実体は quickshell）ため `custom/swaync` → `custom/control-center` にする。
control-center 島は `custom/idle_inhibitor` + `custom/control-center` + `custom/power` の 3 モジュール構成。group に on-click は無いため、**3 つとも同一の on-click（`qs -c shell ipc call cc toggle`）を持たせて島全体を CC の入口にする**。idle_inhibitor 単体トグルと wlogout 起動は廃止。
クリック動作は 5 種（nix, workspaces, bluetooth, pulseaudio, control-center 島）のみ。

- [ ] **Step 1: `settings/bar.nix` を作成**

```nix
{
  layer = "top";
  margin = "10 8 2 8";
  reload_style_on_change = true;

  modules-left = [
    "group/launcher#island"
    "hyprland/window"
  ];
  modules-center = [
    "group/workspaces#island"
    "group/datetime#island"
  ];
  modules-right = [
    "group/sysstats#island"
    "group/status#island"
    "group/control-center#island"
  ];

  "group/launcher#island" = {
    orientation = "horizontal";
    modules = [ "custom/nix" ];
  };
  "group/workspaces#island" = {
    orientation = "horizontal";
    modules = [ "hyprland/workspaces" ];
  };
  "group/datetime#island" = {
    orientation = "horizontal";
    modules = [
      "custom/time"
      "custom/date"
      "custom/weather"
    ];
  };
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
  "group/status#island" = {
    orientation = "horizontal";
    modules = [
      "network"
      "bluetooth"
      "pulseaudio"
      "privacy"
      "tray"
    ];
  };
  "group/control-center#island" = {
    orientation = "horizontal";
    modules = [
      "custom/idle_inhibitor"
      "custom/control-center"
      "custom/power"
    ];
  };
}
```

- [ ] **Step 2: `settings/modules.nix` を作成**

アイコン glyph（``, `󰥔`など）は旧`config.json` の値をそのまま使う。以下のコードブロック内の glyph は正しい Nerd Font 文字で書かれているので、コピーすればよい。

```nix
{ username }:
{
  "custom/nix" = {
    format = "  ${username}";
    tooltip = false;
    on-click = "qs -c shell ipc call launcher toggle";
  };
  "hyprland/window" = {
    format = "{}";
    separate-outputs = true;
    max-length = 40;
  };

  "hyprland/workspaces" = {
    format = "{icon}";
    on-click = "activate";
    show-special = true;
    special-visible-only = true;
    format-icons = {
      "1" = "1";
      "2" = "2";
      "3" = "3";
      "4" = "4";
      "5" = "5";
      special = " ";
    };
    persistent-workspaces = {
      "*" = [
        1
        2
        3
        4
        5
      ];
    };
  };
  "custom/time" = {
    format = "󰥔 {}";
    exec = "date '+%H:%M'";
    interval = 60;
    tooltip = false;
  };
  "custom/date" = {
    format = "󰸗 {}";
    exec = "date '+%m/%d'";
    interval = 3600;
    tooltip = false;
  };
  "custom/weather" = {
    format = "{}";
    tooltip = true;
    return-type = "json";
    exec = "~/.config/waybar/scripts/weather/weather.sh";
    interval = 900;
  };

  cpu = {
    interval = 10;
    format = "󰻠 {usage}%";
    tooltip = true;
    tooltip-format = "CPU {usage}%  Load {load}";
  };
  temperature = {
    hwmon-path = "/sys/class/hwmon/hwmon2/temp1_input";
    interval = 5;
    critical-threshold = 80;
    format = "󰔏 {temperatureC}°C";
    format-critical = "󰔏 {temperatureC}°C ";
  };
  memory = {
    interval = 30;
    format = "󰍛 {}%";
    tooltip-format = "{used:0.1f}G/{total:0.1f}G";
  };

  network = {
    format = "{ifname}";
    format-wifi = "󰖩 wifi";
    format-ethernet = "󰈀 ethernet";
    format-disconnected = "";
    tooltip-format = "{ifname} via {gwaddr} 󰌘";
    tooltip-format-wifi = "{essid} ({signalStrength}%) ";
    tooltip-format-ethernet = "{ifname} ";
    tooltip-format-disconnected = "Disconnected";
    max-length = 50;
  };
  bluetooth = {
    format = "{icon} {status}";
    format-icons = {
      enabled = "󰂯";
      disabled = "󰂲";
    };
    tooltip-format = "{device_alias}";
    on-click = "qs -c bluetooth -n";
  };
  pulseaudio = {
    format = "{icon} {volume}%";
    format-bluetooth = "{icon} 󰂰 {volume}%";
    format-muted = "󰝟 {volume}%";
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
  privacy = {
    icon-spacing = 6;
    icon-size = 14;
    transition-duration = 250;
  };
  tray = {
    icon-size = 21;
    spacing = 10;
    icons = {
      blueman = "bluetooth";
      TelegramDesktop = "$HOME/.local/share/icons/hicolor/16x16/apps/telegram.png";
    };
  };

  # control-center 島: 3 モジュールに同一 on-click を与え、島全体を CC の入口にする
  # (waybar の group は on-click を持てないため)
  "custom/idle_inhibitor" = {
    format = "{}";
    return-type = "json";
    interval = 2;
    exec-if = "which qs";
    exec = "qs -c shell ipc call idle status";
    on-click = "qs -c shell ipc call cc toggle";
  };
  "custom/control-center" = {
    tooltip = true;
    format = "{icon}";
    format-icons = {
      notification = "󱅫";
      none = "󰂜";
      dnd-notification = "󰂠";
      dnd-none = "󰪓";
      inhibited-notification = "󰂛";
      inhibited-none = "󰪑";
      dnd-inhibited-notification = "󰂛";
      dnd-inhibited-none = "󰪑";
    };
    return-type = "json";
    interval = 2;
    exec-if = "which qs";
    exec = "qs -c shell ipc call cc status";
    on-click = "qs -c shell ipc call cc toggle";
    escape = true;
  };
  "custom/power" = {
    format = "󰐥";
    tooltip = false;
    on-click = "qs -c shell ipc call cc toggle";
  };
}
```

- [ ] **Step 3: `default.nix` を書き換え**

`lib` 引数と importJSON、username 連結ハックを消し、settings を 2 ファイルのマージで組む。`styles/` のリンク行は実ファイルがまだあるため**このタスクでは残す**（Task 2 で削除）。

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
      (import ./settings/bar.nix // import ./settings/modules.nix { inherit username; })
    ];
  };
  xdg.configFile."waybar/style.css".source = lnk ./style.css;
  xdg.configFile."waybar/styles".source = lnk ./styles;
  xdg.configFile."waybar/scripts".source = lnk ./scripts;
}
```

- [ ] **Step 4: `config.json` と `scripts/pkg-update/` を削除**

```bash
git rm home-manager/desktop/waybar/config.json
git rm -r home-manager/desktop/waybar/scripts/pkg-update
```

- [ ] **Step 5: settings の出力を確認**

```bash
nix eval .#nixosConfigurations.nixos.config.home-manager.users.mkiin.programs.waybar.settings --json | jq '.[0] | {left: .["modules-left"], center: .["modules-center"], right: .["modules-right"], nix_format: .["custom/nix"].format, status: .["group/status#island"].modules, cc: .["group/control-center#island"].modules}'
```

期待値:

```json
{
  "left": ["group/launcher#island", "hyprland/window"],
  "center": ["group/workspaces#island", "group/datetime#island"],
  "right": [
    "group/sysstats#island",
    "group/status#island",
    "group/control-center#island"
  ],
  "nix_format": "  mkiin",
  "status": ["network", "bluetooth", "pulseaudio", "privacy", "tray"],
  "cc": ["custom/idle_inhibitor", "custom/control-center", "custom/power"]
}
```

あわせて廃止と CC 入口の確認:

```bash
nix eval .#nixosConfigurations.nixos.config.home-manager.users.mkiin.programs.waybar.settings --json | jq '.[0] | has("custom/mise"), has("custom/swaync"), has("custom/separator"), has("battery"), has("cava")'
nix eval .#nixosConfigurations.nixos.config.home-manager.users.mkiin.programs.waybar.settings --json | jq '.[0] | [.["custom/idle_inhibitor"], .["custom/control-center"], .["custom/power"]] | map(.["on-click"]) | unique'
```

期待: 1 本目はすべて `false`。2 本目は `["qs -c shell ipc call cc toggle"]`（3 モジュールの on-click が同一）。

- [ ] **Step 6: ビルドと整形を通す**

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

期待: 両方成功（fmt が差分を出したら `nix run .#fmt` で整形して再実行）。

- [ ] **Step 7: コミット**

```bash
git add home-manager/desktop/waybar/
git commit -m "refactor(waybar): config.jsonをNix分割構成に置き換え、島をOS準拠の6島に組み直し"
```

---

### Task 2: ダークグラス style.css への統合

**Files:**

- Modify: `home-manager/desktop/waybar/style.css`（全面書き換え）
- Modify: `home-manager/desktop/waybar/default.nix`（styles リンク行を削除）
- Delete: `home-manager/desktop/waybar/styles/`（7 ファイル）, `home-manager/desktop/waybar/FAVORITES.md`

**Interfaces:**

- Consumes: Task 1 の `#island` クラス（全 group）とモジュール ID。matugen トークン（`@primary`, `@on_primary`, `@on_surface`, `@secondary_container`, `@on_secondary_container`, `@tertiary`, `@on_tertiary`, `@error`, `@on_error`, `@state_critical`）
- Produces: なし（最終成果物）

CSS の機構は 3 層だけ: `.island`（島の質感）, `.island > *`（島内リセット）, 状態セレクタ（効き色）。旧構成の「`.cluster` クラス + 単独モジュール ID 列挙」の二重機構を廃止する。

- [ ] **Step 1: `style.css` を全面書き換え**

```css
/* ダークグラス・アイランド単一スタイル。
 * 色は matugen 生成の colors.css (MD3 トークン) のみに依存する。
 * すりガラスは hyprland 側 layerrule (blur + ignore_alpha) が担当し、
 * ここでは半透明ティントと縁取り・影だけを描く。 */

@import "colors.css";

/* ============================================================
   Tokens
   ============================================================ */
@define-color glass_tint rgba(10, 12, 18, 0.58);
@define-color glass_border rgba(255, 255, 255, 0.08);
/* tooltip は blur が乗らない別サーフェスなので濃いめにして可読性を確保 */
@define-color tooltip_bg rgba(10, 12, 18, 0.92);

/* ============================================================
   Reset
   ============================================================ */
* {
  border: none;
  border-radius: 0;
  font-family:
    "JetBrainsMono Nerd Font", "Iosevka Nerd Font", "Font Awesome 6 Free";
  font-size: 14px;
  margin: 0;
  padding: 0;
  min-height: 1px;
}

window#waybar {
  background-color: transparent;
  color: @on_surface;
}

/* GTK4 Adwaita 既定の button/tooltip 装飾を無効化 */
button {
  box-shadow: none;
  outline: none;
  text-shadow: none;
  background-image: none;
}

button:hover,
button:focus,
button:focus-visible {
  box-shadow: none;
  outline: none;
  background-image: none;
}

tooltip {
  background-image: none;
  text-shadow: none;
}

tooltip label {
  background-image: none;
}

/* ============================================================
   Island
   バーに載る group は全部 `group/<name>#island` で .island class を持つ。
   #window だけは group で包むと空タイトル時に空枠が残るため裸のまま
   同じ質感を当てる (唯一の例外)。
   ============================================================ */
.island,
#window {
  background-color: @glass_tint;
  border: 1px solid @glass_border;
  border-radius: 20px;
  padding: 0 10px;
  margin: 0 5px;
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.3);
  color: @on_surface;
}

/* 島内モジュールは島の背景に乗るだけ。個別 ID は列挙しない */
.island > * {
  background-color: transparent;
  border: none;
  border-radius: 0;
  margin: 0;
  padding: 0 6px;
  box-shadow: none;
}

/* フォーカスウィンドウが無いときは window 島ごと消す */
window#waybar.empty #window {
  background-color: transparent;
  border: none;
  box-shadow: none;
  padding: 0;
  margin: 0;
}

/* ============================================================
   Workspaces
   非アクティブは小ドット (文字色を透明にして丸だけ見せる)、
   アクティブは @primary の横長ピル。
   ============================================================ */
#workspaces button {
  min-width: 20px;
  margin: 5px 3px;
  color: transparent;
  background-color: alpha(@on_surface, 0.35);
  border-radius: 20px;
  transition:
    background 0.25s cubic-bezier(0.4, 0, 0.2, 1),
    color 0.25s cubic-bezier(0.4, 0, 0.2, 1),
    min-width 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

#workspaces button.active {
  color: @on_primary;
  background-color: @primary;
  min-width: 50px;
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
   状態色
   ============================================================ */
#custom-nix {
  color: @primary;
}

#custom-power {
  color: @primary;
}

#network.disconnected {
  color: @state_critical;
}

#pulseaudio.muted {
  color: @primary;
}

#privacy {
  color: @primary;
}

#temperature.critical {
  color: @state_critical;
}

#custom-idle_inhibitor.activated {
  color: @primary;
}

#custom-control-center.dnd-none,
#custom-control-center.dnd-notification,
#custom-control-center.dnd-inhibited-none,
#custom-control-center.dnd-inhibited-notification {
  color: @primary;
}

/* ============================================================
   Tooltip
   ============================================================ */
tooltip {
  background-color: @tooltip_bg;
  border: 1px solid @glass_border;
  border-radius: 12px;
  padding: 6px 8px;
}

tooltip label {
  color: @on_surface;
  padding: 2px 4px;
}
```

- [ ] **Step 2: styles/ と FAVORITES.md を削除し、default.nix のリンク行を消す**

```bash
git rm -r home-manager/desktop/waybar/styles home-manager/desktop/waybar/FAVORITES.md
```

`default.nix` から次の 1 行を削除:

```nix
  xdg.configFile."waybar/styles".source = lnk ./styles;
```

- [ ] **Step 3: ビルドと整形を通す**

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

期待: 両方成功。

- [ ] **Step 4: コミット**

```bash
git add home-manager/desktop/waybar/
git commit -m "feat(waybar): ダークグラス単一スタイルに統合しstyles切替を廃止"
```

---

### Task 3: Hyprland layerrule でブラーを有効化

**Files:**

- Modify: `home-manager/desktop/hyprland/lua/rules.lua`（末尾に追記）

**Interfaces:**

- Consumes: waybar の layer namespace は `waybar`（waybar 既定値）。`style.css` の `@glass_tint` alpha が 0.58 なので、`ignore_alpha` の閾値はそれ未満の 0.2 とし、完全透過部分（バー背景）にはブラーを乗せない
- Produces: なし

- [ ] **Step 1: `rules.lua` 末尾に layer_rule を追記**

既存の `logout-dim` ルールの後に追加する:

```lua
hl.layer_rule({
	name = "waybar-glass-blur",
	match = { namespace = "waybar" },
	blur = true,
	ignore_alpha = 0.2,
})
```

- [ ] **Step 2: ビルドと整形を通す**

```bash
nix run .#build
nix run .#fmt -- --fail-on-change
```

期待: 両方成功（Lua はビルド時に評価されないため、実効確認は Task 4 の実機で行う）。

- [ ] **Step 3: コミット**

```bash
git add home-manager/desktop/hyprland/lua/rules.lua
git commit -m "feat(hyprland): waybarにblur layerruleを追加"
```

---

### Task 4: 実機反映と目視検証

**Files:** 変更なし（検証のみ）。実機 NixOS 上で実行する。

**Interfaces:**

- Consumes: Task 1〜3 の全成果物

- [ ] **Step 1: フォールバックとリロード動線の確認（コード変更なし）**

```bash
grep -n "colors.css" home-manager/desktop/matugen/default.nix
grep -n "reload-css" home-manager/desktop/hyprland/scripts/wallpaper/post.sh
```

期待: matugen 側 activation に colors.css フォールバックが存在すること、`reload-css.sh` が post.sh から参照されていること（spec の「初回起動フォールバック」は実装済み、reload-css.sh は削除不可、の再確認）。

- [ ] **Step 2: 実機反映**

```bash
nix run .#switch
systemctl --user restart waybar
```

期待: waybar が起動しエラーログなし（`journalctl --user -u waybar -n 50` で確認）。

- [ ] **Step 3: 目視チェックリスト**

- 島がダークグラス（半透明 + 細フチ + 影 + 背面ブラー）で描画されている
- `.island > *` のリセットが効いており、島の中に二重の枠や背景が出ていない
- 明るい壁紙と暗い壁紙の両方で島の境界が識別できる（壁紙切替: 既存の壁紙スクリプトを使用）
- 壁紙切替でアクセント色（アクティブ WS のピルなど）が追従する
- 構成: 左 = launcher 島 + ウィンドウタイトル、中央 = ws 島 + 時刻/日付/天気島、右 = sysstats 島（drawer 開閉可）+ status 島（network, BT, 音量, privacy, tray）+ control-center 島（idle, ベル, 電源）
- ウィンドウを全部閉じたとき window の空枠が残らない
- クリック: nix→ランチャー、ws→移動、BT→bluetooth ポップアップ、音量→オーディオセレクタ が動く
- control-center 島は idle・ベル・電源の**どこをクリックしても**コントロールセンターが開く
- 廃止確認: pulseaudio スクロールで音量が変わらない、mise がバーに存在しない、wlogout がバーから起動できない
- tooltip が濃色背景で読める

- [ ] **Step 4: 問題なければユーザーに push 判断を委ねる**

todo.md の waybar 関連項目（「waybarのリデザイン」「初回起動時の colors.css」）の整理は、todo.md に別の未コミット変更があるためユーザーと相談して行う。

---

## Self-Review 結果

- Spec coverage: 島構造の組み直しと mise/pkg-update 削除 = Task 1、swaync→control-center 改名と CC 島（3 モジュール同一 on-click）= Task 1、ダークグラス CSS と 3 層セレクタ構造・styles 廃止・wallust 依存削除 = Task 2、Hyprland blur = Task 3、フォールバック確認と検証 = Task 4。
- Placeholder scan: なし（全コード完載）。
- Type consistency: 全 group の `#island` サフィックスと CSS `.island`、`#window` 例外の扱い、モジュール ID と CSS セレクタ（`#custom-control-center`, `#custom-idle_inhibitor` 含む）、CC 島 3 モジュールの on-click 同一性、`username` 引数の受け渡しを照合済み。`.island > *` が workspaces ボタンへ波及しない点は specificity（`#workspaces button` が優位）で担保、実機確認は Task 4 のチェックリストに含めた。
