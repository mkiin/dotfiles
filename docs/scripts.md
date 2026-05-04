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
     2. `~/.local/state/hypr/last_wallpaper` を読んで直前と被らないよう reroll
     3. 選んだ画像パスを `~/.local/state/hypr/last_wallpaper` に記録
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
4. `~/.local/state/hypr/last_wallpaper` に画像パスを記録 (mode 切替時の壁紙同期用)
5. `hyprctl reload` で全 config を再評価 → border 等の `$variable` 参照箇所が新色を反映

**ポイント**:
- `matugen --source-color-index 0` 必須: matugen 4.0+ は対話 UI がデフォルトで TTY 無し呼び出しでは失敗する。`0` (最頻色) 固定で対話回避。
- `awww` の transition パラメータ: `--transition-fps 120` `--transition-duration 3` `--transition-step 90` `--transition-bezier .23,1,.32,1` (144Hz モニター + NVIDIA 多モニター環境向けに stutter 抑制チューニング済み)
- **`hyprctl reload` を使う理由**: Hyprland は `$variable` を parse 時に値置換するので、`colors.conf` だけ再 source しても `col.active_border = $primary $tertiary` 等の既評価ルールには新色が伝播しない。全 reload で初めて全ファイルが再評価され border 色等が更新される。
- **bed-mode が吹き飛ばないのは monitors.conf の分割が担保**: `monitors.conf → monitors-active.conf → 現モードの定義` という間接経由で reload 後も現モードが維持される。

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

**動作** (4 ステップ):
1. `monitors-active.conf` に `source = monitors-bed.conf` を書き込んで永続化
2. `hyprctl reload` で全 config 再評価 → monitor 切替 + workspace rule 適用 + 既存 ws の reassign を Hyprland が一括処理
3. **awww-daemon が reload 後の monitor 構成を認識するまでポーリング待ち** (最大 1 秒)
4. layer surface (waybar / awww) を手動再構築 (Hyprland のバグ workaround)

**設計のキモ**:
- **monitor/workspace 定義は monitors-bed.conf に一元化**: スクリプトは「どのモードか」を active.conf に書くだけで、具体的な monitor 設定や ws rule は持たない。設定変更したい時は monitors-bed.conf を編集すれば自動で次回切替に反映される。
- **`hyprctl reload` 一発で済む**: 旧版は `--batch keyword monitor` (即時 monitor 切替) + workspace dispatch ループ + focus/dpms 補正を持っていたが、reload が同じ事を一括でやる (monitor 設定、persistent:true による空 ws の auto-materialize、focus 自動補正)。reload は monitor 重複や signal 断も Hyprland 側で吸収するので --batch 相当の atomicity も不要。
- **awww 認識待ちのポーリングが必須**: `hyprctl reload` は async で、戻り値の直後に `awww img` を打つと awww-daemon の view にまだ新規 enable monitor が来ておらず取りこぼされる (例: bed→desk 直後 DP-2 だけ更新されて DP-1/3 が古いキャッシュのまま)。`awww query` の monitor 数 = `hyprctl monitors` の数になるまで 100ms 単位で待つ。
- **layer 再構築は必須**: Hyprland はモニター位置変更を layer surface に伝播しない既知バグがあるため、awww (壁紙) と waybar の layer だけは reload では復活せず、手動再起動が必要。
- **モード間壁紙同期**: awww-daemon は per-monitor で壁紙キャッシュを持つため、`awww restore` だと disable 中だったモニターは過去のキャッシュが残ってモード間で壁紙が割れる。`~/.local/state/hypr/last_wallpaper` (wallset-backend.sh が更新) を明示適用することで両モードに同じ壁紙が乗る。`--transition-type none` でモード切替の即時性を担保。

---

### `desk-mode.sh`

**目的**: bed-mode から復帰し、monitors.conf の真の状態 (DP-1/2/3 enable, HDMI-A-1 disable) に戻す。

**呼ばれ方**: `Super+Shift+D`。

**動作** (4 ステップ、bed-mode.sh と完全対称):
1. `monitors-active.conf` に `source = monitors-desk.conf` を書き込んで永続化
2. `hyprctl reload` で全 config 再評価 → 既存 ws 1-3 が DP-3/2/1 へ自動 reassign される
3. awww-daemon が新 monitor 構成を認識するまでポーリング待ち
4. layer surface (waybar / awww) を手動再構築

**ポイント**: bed-mode.sh とほぼ同じ。違いは active.conf に書く参照先 (bed か desk か) だけ。具体的な monitor / workspace 設定は monitors-desk.conf 側に集約。

## 削除済み / 統合された機構 (歴史メモ)

| 項目 | 何だった | なぜ消えた |
|---|---|---|
| 動的 hjkl rebind | bed-mode で `hjkl` を ws 移動に振り替え、desk で movefocus に戻す | `Super+I/O` をグローバルにすることで「モードでキー意味が変わる」負債を排除 |
| `hyprctl keyword source colors.conf` (外科的 reload) | 壁紙変更時に colors.conf だけ再 source して全 reload を回避 | `$variable` の textual substitution により `col.active_border` 等の既評価ルールに新色が伝播しない問題が判明。monitors.conf を分割して mode-aware にした上で `hyprctl reload` (全 reload) に戻した |
| bed/desk-mode.sh の `hyprctl --batch keyword monitor` + workspace dispatch ループ + focus/dpms 補正 | 外科的 reload 時代の名残。monitor だけ runtime で動かしたい時の atomicity 確保や、空 ws を visit して実体化、フォーカスの後始末などを手動でやっていた | `monitors-active.conf` 経由の `hyprctl reload` 設計に切替 → reload が monitor 切替・persistent ws 実体化・focus 補正を一括処理するため不要に。スクリプトは active.conf 書換 + reload + layer rebuild の 3 ステップに簡素化 |

## 関連ドキュメント

- [Architecture](./architecture.md) — システム全体像
- [File Structure](./file-structure.md) — ディレクトリレイアウト
- [Theming Pipeline](./theming-pipeline.md) — 色生成の流れ
