# Scripts Reference

`~/.config/hypr/scripts/` 配下の各スクリプトの責務と呼び出し関係。

## 一覧

| Script | 役割 | トリガ |
|---|---|---|
| `wallset-backend-startup.sh` | awww-daemon 起動 + ランダム壁紙適用 / 前回壁紙の復元 | Hyprland 起動時 (autostart) |
| `wallset-backend.sh` | 壁紙 1 枚 → 全テーマ適用パイプライン | Walker wallselect の activate / 手動 CLI |
| `wallpaper-thumb.sh` | Walker 用サムネイル (416x234 JPEG) を生成 | systemd path triggered (壁紙ディレクトリ変更時) |
| `waybar-reload-css.sh` | Waybar の style.css を in-place rewrite して CSS だけ reload | matugen post_hook (壁紙変更パイプライン中) |
| `bed-mode.sh` | 1モニター運用 (HDMI-A-1) へ動的切替 | `Super+Shift+B` キーバインド |
| `desk-mode.sh` | 3モニター運用 (DP-1/2/3) へ復帰 | `Super+Shift+D` キーバインド |

## 呼び出し関係

```
[Hyprland 起動]
   └─▶ exec-once: wallset-backend-startup.sh    ── awww-daemon 起動
                                                ├─ if WALLSET_RANDOM_ON_STARTUP=true:
                                                │    ランダム壁紙選択 → exec wallset-backend.sh
                                                └─ else: awww restore (前回壁紙)

[Super+W (壁紙選択)]
   └─▶ walker --provider menus:wallselect
         └─▶ Activate: wallset-backend.sh <image>   ── awww img <image>
                                                ├─ matugen image <image>
                                                │    └─ post_hook: waybar-reload-css.sh
                                                └─ hyprctl keyword source colors.conf

[Super+Shift+B (ベッドモード)]
   └─▶ bed-mode.sh                            ── HDMI-A-1 enable, DP-* disable
                                                ├─ ws 1-4 を HDMI-A-1 に dispatch で実体化
                                                └─ awww restore + waybar 再起動

[Super+Shift+D (デスクモード)]
   └─▶ desk-mode.sh                           ── DP-* enable, HDMI-A-1 disable
                                                └─ awww restore + waybar 再起動

[壁紙ディレクトリ変更 (~/pictures/wallpaper)]
   └─▶ wallpaper-thumb.path (systemd)
         └─▶ wallpaper-thumb.service          ── wallpaper-thumb.sh oneshot
                                                  (差分検知でサムネ追加/掃除)
```

## 各スクリプト詳細

### `wallset-backend-startup.sh`

**目的**: 起動時の壁紙適用 entry point。awww-daemon を起こし、設定変数に応じて「ランダム壁紙適用」または「前回壁紙の復元」のいずれかを実行する。

**呼ばれ方**: `~/.config/hypr/autostart.conf` の `exec-once` から、`uwsm app -- ...` 経由。

**動作**:
1. `awww query` で daemon が既に起動しているか確認
2. 起動していなければ `awww-daemon &` で spawn、socket 作成まで最大 5 秒待機
3. `WALLSET_RANDOM_ON_STARTUP` の値で分岐:
   - **`true`** (デフォルト、ランダム経路):
     1. `~/pictures/wallpaper/` 配下の画像を `fd` で列挙
     2. `~/.cache/last_wallpaper` を読んで直前と被らないよう reroll
     3. 選んだ画像パスを `~/.cache/last_wallpaper` に記録
     4. `exec wallset-backend.sh <picked>` で全パイプライン実行 (色再生成含む)
   - **`false`** (復元経路):
     1. `awww restore` で per-monitor キャッシュから復元
     2. キャッシュが空なら fallback 画像 (`~/pictures/wallpaper/1297749.jpg`) を適用
     3. 色再生成は走らせず、前回 session の生成物 (`colors.conf` 等) をそのまま使う

**設計意図**:
- ランダム経路は backend に `exec` で委譲することでパイプラインを重複させない (noro-dotfiles の startup と backend が同じ処理をコピーしている重複問題を回避)。
- 復元経路は色再生成不要なので軽量。前回壁紙を継続したい場合に向く。
- `WALLSET_RANDOM_ON_STARTUP` は本ファイル冒頭で固定。将来 settings UI から切り替える前提で変数化。

---

### `wallset-backend.sh`

**目的**: 壁紙画像 1 枚を引数で受け取り、見た目変更 + 色生成 + 各 consumer 反映の全パイプラインを実行する **エンジン**。

**呼ばれ方**: 主に Walker の wallselect menu の activate アクションから (`Super+W` 経由)。CLI 直叩きも可。

**シグネチャ**: `wallset-backend.sh <image-path>`

**動作**:
1. `awww img <image>` を非同期起動 (3 秒トランジション)
2. `matugen image <image> --source-color-index 0` を非同期起動
3. 両方の `wait` で完了を待つ
4. `hyprctl keyword source ~/.config/hypr/colors.conf` で Hyprland 枠色だけ外科的反映

**ポイント**:
- `matugen --source-color-index 0` 必須: matugen 4.0+ は対話 UI がデフォルトで TTY 無し呼び出しでは失敗する。`0` (最頻色) 固定で対話回避。
- `awww` の transition パラメータ: `--transition-fps 120` `--transition-duration 3` `--transition-step 90` `--transition-bezier .23,1,.32,1` (144Hz モニター + NVIDIA 多モニター環境向けに stutter 抑制チューニング済み)
- **`hyprctl reload` は使わない**。`monitors.conf` も読み直されて bed-mode が吹き飛ぶため。`source` keyword で colors.conf だけ再読込する。

**矛盾対応**:
- matugen の `[templates.waybar]` には `post_hook = "~/.config/hypr/scripts/waybar-reload-css.sh"` が設定されているので、wallset-backend.sh から waybar に直接シグナルを送る必要はない。

---

### `wallpaper-thumb.sh`

**目的**: Walker の wallselect menu 用サムネイル (416x234 JPEG) を `~/.cache/wallpaper-thumbs/` に生成。

**呼ばれ方**: systemd user の path/service ペアにより、`~/pictures/wallpaper` の変更を検知して oneshot 実行。手動 `Super+W` で wallselect を開いた瞬間に走るのではなく、**事前生成方式**。

**動作**:
1. `~/pictures/wallpaper/` 配下を `fd` で列挙
2. 各画像について `<basename>.jpg` を thumb dir に生成 (mtime 比較で冪等)
3. ImageMagick で 416x234 にリサイズ (208x117 の 2x retina)、`-unsharp` で鮮鋭感補正、`-colorspace sRGB` で色空間明示
4. 孤児サムネ (元画像が消えたもの) を掃除

**Walker 側の連携**: `wallselect.lua` で Icon パスを優先 thumb / fallback 原画像の順で解決。サムネ無しでも壁紙選択は動くが、起動が大幅にもたつく (67MB 画像 9 枚 → 1.2MB サムネ で「瞬時」体感)。

---

### `waybar-reload-css.sh`

**目的**: Waybar の `style.css` を in-place truncate + rewrite し、`reload_style_on_change` を発火させる。

**呼ばれ方**: matugen の `[templates.waybar].post_hook`。matugen が `~/.config/waybar/CSS/colors.css` を書き出した直後に呼ばれる。

**なぜこの間接的なやり方か**:
- matugen が直接書く `colors.css` は `style.css` から `@import` されているだけ。GIO FileMonitor は @import 先の変更を拾わない。
- `style.css` 自体を変更すれば `CHANGES_DONE_HINT` 発火 → Waybar が `Client::reset()` せずに `CssProvider` だけ reload する。
- `SIGUSR2` でも reload できるが、surface 完全再生成 → exclusive_zone 一瞬消失 → 全タイル window 再レイアウト、というガクつきが発生する。in-place rewrite なら surface 維持で滑らか。
- `touch` (mtime のみ) では `IN_ATTRIB` 止まりで `CHANGES_DONE_HINT` にならないので不可。

---

### `bed-mode.sh`

**目的**: 4枚同時接続のうち HDMI-A-1 (ベッド側モニター) のみを有効化し、デスク 3 枚 (DP-1/2/3) を disable する動的切替。

**呼ばれ方**: `Super+Shift+B`。CLI 直叩きも可。

**動作**:
1. `hyprctl --batch` で atomically:
   - HDMI-A-1 を `1920x1080@144,0x0` で enable
   - DP-3, DP-2, DP-1 を disable
2. `hyprctl dispatch focusmonitor HDMI-A-1` でカーソルを寄せる
3. `hyprctl dispatch dpms on HDMI-A-1` で DPMS スタンバイ保険
4. ws 1-4 を `dispatch workspace N` で HDMI-A-1 に visit して実体化
5. `awww restore` + waybar 再起動で layer surface を新位置で作り直す

**設計のキモ**:
- **--batch の atomicity**: 重複チェックは末状態のみで評価。HDMI-A-1 modeset を batch 先頭に置いて DRM レベルでも先行発行 → 信号断回避。
- **monitors.conf を書き換えない**: 動的に runtime だけ変える。`hyprctl reload` で必ず desk-mode に戻る。
- **dispatch でワークスペース実体化**: `hyprctl keyword workspace ...` では config の rule (ws 1→DP-3 等) を上書きできない。dispatch すると home monitor が disable でも現在有効なモニターに ws を作れる。
- **layer 再構築**: Hyprland はモニター位置変更を layer surface に伝播しない既知バグがあるため、awww (壁紙) と waybar の layer は手動で作り直す。

---

### `desk-mode.sh`

**目的**: bed-mode から復帰し、monitors.conf の真の状態 (DP-1/2/3 enable, HDMI-A-1 disable) に戻す。

**呼ばれ方**: `Super+Shift+D`。

**動作**:
1. `hyprctl --batch` で DP-3/DP-2/DP-1 enable + HDMI-A-1 disable
2. `awww restore` + waybar 再起動

**ポイント**: monitors.conf の workspace rule (ws 1-3 が DP-* に persistent でピン留め) が真なので、ws の戻りは Hyprland 側で自動。スクリプトは monitor 切替と layer 再構築だけに専念。

## 削除済み / 統合された機構 (歴史メモ)

| 項目 | 何だった | なぜ消えた |
|---|---|---|
| state file (`hypr-monitor-mode`) | wallset-backend.sh が bed/desk を判別する状態ファイル | `disable_autoreload = true` 1 行で問題が消え、不要になった |
| 動的 hjkl rebind | bed-mode で `hjkl` を ws 移動に振り替え、desk で movefocus に戻す | `Super+I/O` をグローバルにすることで「モードでキー意味が変わる」負債を排除 |
| `hyprctl reload` (in wallset-backend.sh) | 壁紙変更後に全 config 再読込 | `hyprctl keyword source colors.conf` の外科的 reload に置換 |

## 関連ドキュメント

- [Architecture](./architecture.md) — システム全体像
- [File Structure](./file-structure.md) — ディレクトリレイアウト
- [Theming Pipeline](./theming-pipeline.md) — 色生成の流れ
