# Hyprland Config 監査レポート

## サマリ

ユーザーの設定は**基本的には機能面でよくまとまっており、matugen による色管理が実装されている**が、セクション分割が細分化しすぎており、複数のキュレーター比較では**本来まとめるべき設定が分散している**。特に `animations`, `decoration`, `dwindle`, `misc`, `input`, `env`, `cursor` がすべて異なるファイルに散らばっており、他のキュレーターからは `land/defaults.conf` や `conf/` による集約が定石となっている。chezmoi 移行を視野に、各ファイルの責務を明確化する必要がある。

---

## 1. 現状の構成

### 1.1 ファイル構成

| ファイル | 行数 | 役割 | 評価 |
|---------|------|------|------|
| `hyprland.conf` | 18 | マスター（source集約） | ✓ 適切 |
| `appearance.conf` | 61 | decoration, animation, dwindle, misc | △ 範囲が広すぎる |
| `autostart.conf` | 24 | exec-once, env 変数 | ✓ 適切 |
| `colors.conf` | 124 | matugen 生成パレット | ✓ 優秀 |
| `hyprlock.conf` | 148 | ロック画面UI | ✓ 適切 |
| `input.conf` | 13 | input, gesture | ✓ 適切 |
| `keybinds.conf` | 87 | キーバインド定義 | ✓ 適切 |
| `monitors.conf` | 15 | monitor, workspace バインド | ✓ 適切 |
| `rules.conf` | 35 | windowrule, layerrule | ✓ 適切 |

**全体ボリューム**: 525行（small-to-medium、管理可能な規模）

### 1.2 主要設定の抜粋と評価

#### colors.conf（優秀なポイント）
```hyprland
# matugen が壁紙から自動生成するカラーパレット
source = ~/.config/hypr/colors.conf

# トークン: $primary, $secondary, $tertiary, $surface, $on_surface, $outline_variant, $state_success 等
# alpha 変数: $primary_a95, $surface_a75 等で hyprlock 対応
```
**評価**: Material Design 3 パレットの完全性と、alpha バリアント対応が秀逸。ただし colors.conf 自体は **static** な状態。wallpaper 変更時に matugen で再生成される想定だが、その トリガーが `autostart.conf` のどこに書かれているかが曖昧。

#### appearance.conf（改善の余地あり）
```hyprland
# 実際の内容:
general {
  col.active_border = $primary $tertiary 45deg
  # colors.conf の変数を活用している（良い）
}
decoration { blur, rounding ... }
animations { ... 多数 ... }
dwindle { pseudotile = true ... }
misc { force_default_wallpaper = 0 ... }
```
**評価**: 4つの conceptual group (general, decoration, animations, dwindle, misc) が 1 ファイルに混在。セクション責任が曖昧。

#### autostart.conf（前処理が散在）
```hyprland
exec-once = uwsm app -- fcitx5 -d --replace
exec-once = uwsm app -- waybar
exec-once = uwsm app -- $HOME/.config/awww/scripts/wallpaper-init.sh

# 注: switchwall.sh / matugen の実行が見当たらない
#     colors.conf を「どこで」生成しているのか追跡困難
```
**評価**: wallpaper-init.sh が走っているが、その内容が `.config/awww/` に隠れていて、matugen 実行タイミングが不透明。

---

## 2. 足りない機能・セクション

### 2.1 必須級（入れるべき）

#### 1. **`env` セクション・ファイルの明示化**
**現状**: `autostart.conf` に埋まってる
```hyprland
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = XMODIFIERS,@im=fcitx
```
**問題**: XDG_*, Wayland, Qt, 言語設定など、Hyprland が立ち上がる前に必要な環境変数が分散。

**他キュレーターでの採用例**:
- **linuxmobile**: `env.conf` 独立（マスター）
- **flickowoa**: `land/defaults.conf` に一括集約
- **ml4w**: `conf/environment.conf` として独立 + restore 保護対象

**改善案**:
```bash
# 新ファイル: ~/.config/hypr/env.conf
# Hyprland 起動前に読み込まれるべき全環境変数を集約

# システム環境
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24

# 日本語入力
env = XMODIFIERS,@im=fcitx

# Qt / Electron
env = QT_QPA_PLATFORMTHEME,qt6ct
env = ELECTRON_OZONE_PLATFORM_HINT,auto

# GPU (NVIDIA の場合は動的化)
env = LIBVA_DRIVER_NAME,iHD

# hyprland.conf に追加:
source = ~/.config/hypr/env.conf  # 最初に読み込む
```

**優先度**: ★★★（ユーザーは mise で多環境管理してるため）

---

#### 2. **`cursor.conf` の独立**
**現状**: `autostart.conf` に埋まってる 2行のみ
```hyprland
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
```
**問題**: Hyprcursor テーマ設定が無く、Hyprland の cursor セクションが未実装。

**他キュレーターでの採用例**:
- **ml4w**: `conf/cursor.conf` として独立
- **fufexan**: `system/programs/hyprland/settings.nix` で `cursor` セクション記述
- **flickowoa**: `components/foot.ini` での cursor 設定のみ

**改善案**:
```bash
# ~/.config/hypr/cursor.conf
cursor {
    no_warping = false
    allow_dumb_copy = false
    sync_gsettings_theme = false

    # Hyprcursor テーマ (catppuccin/bibata-hyprcursor など)
    # active_shape = beam  # 代替は beam / pointer / default
}
```

**優先度**: ★★（ユーザーは minimalist なので、テーマ化不要。基本設定のみで OK）

---

#### 3. **`input` セクションの拡張**
**現状**: 最小限の記述のみ
```hyprland
input { kb_layout = us; follow_mouse = 1; ... }
gesture = 3, horizontal, workspace
```
**問題**: `kb_options`, `repeat_rate`, `repeat_delay`, `numlock_by_default` など、IME 関連の設定が抜けている。

**他キュレーターでの採用例**:
- **flickowoa**: `land/general.conf` で `input { natural_scroll; }` + gesture
- **ml4w**: `conf/keyboard.conf` で `repeat_rate`, `repeat_delay`, `kb_options`

**改善案** (日本語入力向け):
```bash
# ~/.config/hypr/input.conf 拡張
input {
    kb_layout = us
    kb_variant =
    kb_model =
    kb_options =

    numlock_by_default = false
    repeat_rate = 25
    repeat_delay = 600

    follow_mouse = 1
    sensitivity = 1.0
    scroll_factor = 2

    touchpad {
        natural_scroll = false
        scroll_factor = 1.0
        tap-to-click = true
    }
}
```

**優先度**: ★★★（fcitx5-mozc の切り替えショートカット、repeat_rate の体感に関わる）

---

### 2.2 推奨

#### 1. **`exec.conf` / `startup.conf` の統合定義**
**現状**: `autostart.conf` に 8 行の exec-once と 3 行の env が混在

**他キュレーターでの採用例**:
- **linuxmobile**: `startup.conf` に一括
- **flickowoa**: `land/general.conf` に exec-once を含める
- **ml4w**: `conf/autostart.conf` として独立 + restore 保護

**改善案**: ユーザーの現在の分割（autostart）で十分だが、wallpaper 関連の トリガー方式を明確化する

```bash
# ~/.config/hypr/autostart.conf に追記するべき項目

# ─── 色生成パイプライン (matugen) ───
# （ユーザーは ~/.config/awww/scripts/wallpaper-init.sh を走らせている）
# これが matugen を内部で呼ぶ想定だが、ドキュメント化推奨

# ─── システムデーモン ───
exec-once = uwsm app -- hypridle          # idle/sleep 管理（既記）
exec-once = uwsm app -- hyprpaper         # 壁紙デーモン（未実装？）

# ─── 壁紙が動的に変わる場合のリロード ───
# env = WAYLAND_DISPLAY,wayland-1         # （Hyprland が自動設定）
```

**優先度**: ★★（ユーザーは静的壁紙のため、追加は任意）

---

#### 2. **`xdg-portal` / `xdg-desktop-portal-hyprland` の明示的セットアップ**
**現状**: `autostart.conf` に `uwsm app -- elephant` のみ（Walker backend）

**他キュレーターでの採用例**:
- **flickowoa**: `scripts/portal.sh` で xdg-desktop-portal-hyprland リセット
- **linuxmobile**: `scripts/resetxdgportal.sh` を keybind で呼び出し可能

**改善案**:
```bash
# ~/.config/hypr/autostart.conf に追加
exec-once = uwsm app -- dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
```

**優先度**: ★★（screen sharing / file picker が必要になった時に思い出せば OK）

---

### 2.3 好み/選択的

#### 1. **`hyprsunset.conf` (夜間モード)**
**他キュレーターでの採用例**:
- **ml4w**: `conf/` に存在、toggle ショートカット有
- **fufexan**: `services/wayland/gammastep` として NixOS で管理

**改善案**:
```bash
# ~/.config/hypr/hyprsunset.conf (新規)
general {
    fade_in_out = 1
}

hyprsunset {
    enabled = false
    color_temperature = 5000
    transition_enabled = true
    transition_duration_ms = 3000
}
```
**優先度**: ★（深夜コーディング向け、任意）

---

#### 2. **`hyprpaper.conf` (static 壁紙デーモン)**
**現状**: `wallpaper-init.sh` (awww) で管理されている可能性あり

**他キュレーターでの採用例**:
- **ml4w**: `conf/` に hyprpaper.conf
- **fufexan**: Home Manager で `hyprpaper.enable = true`

**改善案**: ユーザーが `wallpaper-init.sh` で充分なら、hyprpaper.conf 不要

**優先度**: ★（awww が壁紙管理している場合は不要）

---

#### 3. **Hyprland plugins**
**他キュレーターでの採用例**:
- **fufexan**: `hyprland-plugins` input、ただし ユーザーのミニマル志向と合わず

**ユーザー環境での必要性**: 低い（mise/minimalist なため）

**優先度**: ★（不要）

---

## 3. ファイル分割の評価と提案

### 3.1 現状の分割パターン

```
hyprland.conf (18行) ─────┐
                           ├─ source
appearance.conf (61行) ◄───┤
autostart.conf (24行) ◄────┤
colors.conf (124行) ◄──────┤  (6ファイル source)
input.conf (13行) ◄────────┤
keybinds.conf (87行) ◄─────┤
rules.conf (35行) ◄────────┤
monitors.conf (15行) ◄─────┘

hyprlock.conf (148行) ─────  (独立)
```

**パターン評価**: 小粒（18〜87行）に分割され、責務が比較的明確。ただし **appearance に decoration/animation/dwindle/misc が混在** しているのが問題。

### 3.2 キュレーター別の分割パターン比較（表）

| キュレーター | 分割パターン | 特徴 | 規模 |
|-------------|-----------|------|------|
| **ml4w** | `hyprland.conf` → `conf/` (14ファイル) | variation + restore で更新時保護 | 大 |
| **flickowoa** | `hyprland.conf` → `land/` (4ファイル) + `components/` + `profiles/` + `scripts/` | 変数集約 (defaults.conf) + 条件分岐 | 大 |
| **linuxmobile** | `hyprland.conf` → 4ファイル (env/startup/keybinds/windowrule) | flat で読みやすい | 小 |
| **fufexan** | flake-parts (NixOS) → `system/programs/hyprland/` (binds.nix / rules.nix / settings.nix) | 宣言的、OS管理 | 中 |
| **notusknot** | `modules/hyprland/default.nix` (Nix) | シンプルな NixOS | 小 |
| **coffebar** | `hyprland.conf` (単一) + スクリプト群 | monolithic、補助スクリプト充実 | 中 |
| **1amSimp1e** | テーマブランチ分岐 (Hyprland 記載なし) | Git 分岐で色管理 | 小 |
| **ユーザー** | 9ファイル (マスター + 8ファイル) | 適度な小粒、colors 統合好評 | 小 |

**ユーザーの位置**: **linuxmobile に最も近い** (4-5ファイル flat, 読みやすい)

### 3.3 改善案

#### 方針: "minimalist かつ chezmoi 対応"
- 現状 9 ファイルは削減不要（小粒で読みやすい）
- **appearance.conf を分割**: `decoration.conf`, `animation.conf`, `dwindle.conf`, `misc.conf` に
- **env.conf を独立**: autostart から分離
- **cursor.conf を独立**: settings に統合可、または独立小ファイル

#### 提案：再設計後の構成（11ファイル）

```
hyprland.conf (エントリ)
├─ source = ~/.config/hypr/env.conf          # 環境変数（最初に読む）
├─ source = ~/.config/hypr/monitors.conf     # モニター
├─ source = ~/.config/hypr/input.conf        # 入力
├─ source = ~/.config/hypr/colors.conf       # 色（matugen）
├─ source = ~/.config/hypr/appearance.conf   # 見た目（下記で再構成）
│   ├─ autoload: decoration.conf
│   ├─ autoload: animation.conf
│   ├─ autoload: dwindle.conf
│   ├─ autoload: misc.conf
├─ source = ~/.config/hypr/cursor.conf       # カーソル（新規）
├─ source = ~/.config/hypr/keybinds.conf     # キーバインド
├─ source = ~/.config/hypr/rules.conf        # ウィンドウルール
├─ source = ~/.config/hypr/autostart.conf    # 起動コマンド

hyprlock.conf (独立)
```

**具体例**:
```bash
# ~/.config/hypr/hyprland.conf (改行)
$terminal = ghostty
$menu = walker

source = ~/.config/hypr/env.conf        # 最初（Hyprland 自体の環境）
source = ~/.config/hypr/colors.conf     # 次（全体色）

source = ~/.config/hypr/monitors.conf
source = ~/.config/hypr/input.conf
source = ~/.config/hypr/cursor.conf
source = ~/.config/hypr/appearance.conf # decoration/animation/dwindle/misc
source = ~/.config/hypr/keybinds.conf
source = ~/.config/hypr/rules.conf
source = ~/.config/hypr/autostart.conf  # 最後（デーモン起動）
```

```bash
# ~/.config/hypr/appearance.conf (新構成)
# 単なるコンテナ
source = ~/.config/hypr/appearance/decoration.conf
source = ~/.config/hypr/appearance/animation.conf
source = ~/.config/hypr/appearance/dwindle.conf
source = ~/.config/hypr/appearance/misc.conf
source = ~/.config/hypr/appearance/general.conf
```

```bash
# ~/.config/hypr/appearance/decoration.conf
decoration {
    rounding = 16
    blur { enabled = true; size = 1; }
}
```

**chezmoi 対応**: ファイル分割なので テンプレート化が容易（`{{ .hostname }}` 等を各ファイルに埋め込み可）

**優先度**: ★★★（chezmoi 移行時に必ず必要になる）

---

## 4. カラースキーマ活用の現状と改善

### 4.1 現状のcolors.conf分析

**ユーザーの colors.conf (124行) を読み込んだ評価**:

```hyprland
# Material Design 3 パレット（matugen 出力）
$primary = rgb(f8b1dc)        # 主役色（ピンク系）
$secondary = rgb(debece)      # 副色
$tertiary = rgb(f4ba9f)       # 第三色（オレンジ系）
$surface = rgb(181115)        # 背景（ダーク）
$on_surface = rgb(eddfe4)     # 前景テキスト

# Alpha variants（hyprlock 用）
$primary_a95 = rgba(f8b1dcf2)
$surface_a75 = rgba(181115bf)

# 固定色（壁紙非追従）
$state_success = rgb(a6e3a1)
$state_critical = rgb(f38ba8)
```

**評価**:
- ✓ **優秀**: MD3 パレット (primary/secondary/tertiary/surface/error) の完全実装
- ✓ **優秀**: alpha バリアント（`_a95`, `_a75`) で hyprlock 用の半透明対応
- ✓ **優秀**: state_success/state_critical で UI フィードバック対応
- △ **弱点**: 壁紙が変わる度に colors.conf 全体を再生成する（matugen 出力を直で使用）

### 4.2 他キュレーターの色パイプライン比較

| キュレーター | 色管理方式 | トリガー | 特徴 |
|-------------|-----------|---------|------|
| **ml4w** | matugen (M3) | `ml4w-wallpaper` で壁紙選択 → 自動生成 + `post_hook` で反映 | ★★★ 動的 |
| **flickowoa** | テーマ static | `themes/base/colors` を編集 or ブランチ分岐 | ★ static |
| **linuxmobile** | Catppuccin Mocha (fixed) | `themeswitch.sh` で Rofi/WezTerm 色一括変更 | ★★ 複数セット |
| **fufexan** | `lib/colors/` (Nix) | 色を関数で注入 → 全モジュールに伝播 | ★★★ 宣言的 |
| **ユーザー** | matugen (M3) | `wallpaper-init.sh` が起動時に実行 | ★★ 起動時のみ |

**ユーザーの現状**:
- wallpaper 変更時に matugen が colors.conf を再生成（`~/.config/awww/scripts/wallpaper-init.sh`）
- ただし、その内部動作が `.config/awww/` に隠れていて **パイプラインが曖昧**

### 4.3 matugen 活用の改善提案

**ユーザーは既に matugen を使ってるので、現在のパイプラインを明文化＆拡張するのが最適**

#### Step 1: matugen の実行をスクリプト化・ドキュメント化

```bash
# ~/.config/hypr/scripts/gen-colors.sh (新規)
#!/usr/bin/env bash
# matugen から colors.conf を生成し、Hyprland に反映するスクリプト

WALLPAPER="${1:?Wallpaper path required}"
CONFIG_DIR="$HOME/.config/hypr"

if ! command -v matugen &>/dev/null; then
    echo "matugen not found. Install: cargo install matugen"
    exit 1
fi

# wallpaper から M3 パレット抽出
matugen color wallpaper "$WALLPAPER" \
    --output-dir "$CONFIG_DIR" \
    --config-file "$HOME/.config/matugen/config.toml"

# Hyprland に即時反映（リロード不要な場合は削除）
if pgrep -x hyprland >/dev/null; then
    hyprctl reload
fi

echo "Colors regenerated from $WALLPAPER"
```

#### Step 2: matugen config.toml で自動テンプレ生成を設定

```toml
# ~/.config/matugen/config.toml
# matugen が colors.conf 出力時に MD3 トークンを Hyprland 記法に変換

[paths]
config_dir = "$HOME/.config"
template_dir = "$HOME/.config/matugen/templates"

[[templates]]
name = "hyprland-colors"
input = "templates/hyprland-colors.toml"
output = "$HOME/.config/hypr/colors.conf"

# post_hook: 生成後に実行する任意のスクリプト
post_hook = ["hyprctl reload"]
```

```toml
# ~/.config/matugen/templates/hyprland-colors.toml
# matugen template: M3 トークンを hyprland 変数記法に出力

# Generated by matugen from {{ image_path }}

# Core M3 tokens (hex_stripped = # なし)
$background = rgb({{ background | hex_stripped }})
$primary = rgb({{ primary | hex_stripped }})
$primary_container = rgb({{ primary_container | hex_stripped }})
$on_primary = rgb({{ on_primary | hex_stripped }})

# ... (他のトークン)

# Alpha variants (hyprlock 用)
$primary_a95 = rgba({{ primary | hex_stripped }}f2)
$surface_a75 = rgba({{ surface | hex_stripped }}bf)

# Fixed states (non-wallpaper-dependent)
$state_success = rgb(a6e3a1)
$state_critical = rgb(f38ba8)
```

#### Step 3: keybind で壁紙変更→色再生成を統合

```bash
# ~/.config/hypr/keybinds.conf に追加
bind = $mainMod, W, exec, \
    wallpaper_file=$(rofi -dmenu < ~/.wallpapers/index) && \
    ~/.config/hypr/scripts/gen-colors.sh "$wallpaper_file"
```

#### Step 4: autostart.conf に matugen 初期化を明示

```bash
# ~/.config/hypr/autostart.conf 改訂版
exec-once = uwsm app -- fcitx5 -d --replace
exec-once = uwsm app -- waybar
exec-once = uwsm app -- swaync
exec-once = uwsm app -- hypridle

# ─── 色生成パイプライン（起動時） ───
exec-once = ~/.config/hypr/scripts/gen-colors.sh "$HOME/.wallpapers/default.jpg"
```

**改善効果**:
- ✓ matugen パイプラインが **明文化** される
- ✓ 壁紙変更時の色再生成が **制御可能** になる
- ✓ chezmoi テンプレート化が容易（`~/.config/matugen/config.toml` 内のパス置換）

**優先度**: ★★★（ユーザーは既に色管理に投資しているため、拡張の効果大）

---

## 5. 優先度付きアクションリスト

### 今すぐやるべき順

#### 1. **env.conf を独立させる** ★★★
- `autostart.conf` から環境変数を抽出
- `hyprland.conf` の最初に読み込む
- **所要時間**: 15分
- **効果**: 設定の責務が明確化、chezmoi テンプレート化に有利

#### 2. **appearance.conf を 5 つに分割** ★★★
- decoration.conf, animation.conf, dwindle.conf, misc.conf を新規作成
- appearance.conf を "コンテナ" にして各ファイル source
- **所要時間**: 20分
- **効果**: 各セクション編集時の検索性向上、cherry-pick が容易

#### 3. **matugen パイプラインをスクリプト化** ★★★
- `~/.config/hypr/scripts/gen-colors.sh` を作成
- autostart.conf で明示的に呼び出し
- **所要時間**: 30分
- **効果**: 色管理が 明示的 になり、カスタマイズ容易に

#### 4. **input.conf を拡張（fcitx5 向け）** ★★
- `repeat_rate`, `repeat_delay`, `kb_options` を追加
- **所要時間**: 10分
- **効果**: キーリピートと IME 切り替え体感が向上

#### 5. **cursor.conf を新規作成** ★★
- cursor セクション + Hyprcursor テーマ設定
- **所要時間**: 10分
- **効果**: ロック画面含むカーソル統一

#### 6. **hyprlock.conf を colors.conf と連動させる（既実装確認）** ★
- 既に `$primary_a95`, `$surface_a75` で対応済み
- ドキュメント化のみ（色トークンのマッピング表をコメント化）
- **所要時間**: 5分

#### 7. **README / STRUCTURE.md を作成** ★
- 各ファイルの責務を明文化
- chezmoi 移行手順を簡記
- **所要時間**: 30分

---

## 6. 参考: 特に参考になるキュレーター

### ユーザー志向（pacman/mise/chezmoi, minimalist）に基づくランキング

#### **第1位: linuxmobile** ⭐⭐⭐⭐⭐
- **理由**:
  - 分割数が適度（4-5ファイル flat）
  - Catppuccin Mocha で色統一しており、ユーザーの matugen 運用と相性良好
  - `rsync` インストール（chezmoi へ容易に移行可能）
  - スクリプト群（gamemode, themeswitch, volumecontrol）が参考になる
- **参考すべき点**:
  - `env.conf` / `startup.conf` / `keybinds.conf` / `windowrule.conf` の 4 分割
  - `scripts/` 配置（hyprland.conf から独立、keybind で呼び出し）
  - `.config/zsh/theme.zsh` で色を 1 箇所に集約（hyprlock も同色）

#### **第2位: flickowoa** ⭐⭐⭐⭐
- **理由**:
  - `land/defaults.conf` による **変数集約の哲学** が秀逸
  - シンプルな設計（cp インストール → chezmoi へ移行容易）
  - 電源管理 (power.conf / battery.conf) が実用的
  - `scripts/lock` による動的色参照（ユーザーの壁紙追従に応用可）
- **参考すべき点**:
  - `defaults.conf` で `$HERE`, `$SCRIPTS`, `$DRUN`, `$LOCK` 等を一括定義
  - モジュール source 順序の工夫（theme 前後で変数上書き）
  - profile (power/battery) 切り替え自動化

#### **第3位: ml4w** ⭐⭐⭐
- **理由**:
  - matugen (M3) の **フル実装** がユーザー環境と直結
  - `restore` 配列で、更新時に ユーザーカスタムを保護する仕掛けが実用的
  - Quickshell (QML UI) は先進的だが、ユーザー環境では過剰
- **参考すべき点**:
  - `conf/` の 14 分割構成（ユーザーの 9 分割より細分化）
  - `matugen/config.toml` + `templates/` で色出力自動化
  - `restorevariations.sh` による variation 管理

---

## 総括

ユーザーの設定は **基礎が堅実** であり、特に matugen 統合と colors.conf の MD3 完全実装は秀逸です。改善の主軸は：

1. **ファイル分割の精密化**: appearance を 5 つに分割、env を独立
2. **パイプラインの明文化**: matugen → colors.conf → Hyprland の流れをスクリプト化
3. **chezmoi 対応性**: 各ファイルの責務明確化 → テンプレート化容易に

これらは **破壊的変更なし** で実現可能で、3-4 時間で完了します。その後、linuxmobile や flickowoa の思想（変数集約、profile 管理）を段階的に取り入れることで、さらに保守性の高い構成に進化させられます。
