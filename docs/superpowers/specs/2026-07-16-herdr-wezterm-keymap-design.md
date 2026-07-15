# herdr キーマップの wezterm 整合 設計

- 日付: 2026-07-16
- 対象: `home-manager/cli/herdr/default.nix`, `home-manager/cli/herdr/MANUAL.md`

## 背景と目的

herdr（AI エージェント向けターミナルマルチプレクサ）の現行キー設定が使いづらい。
普段使いの wezterm（`home-manager/desktop/terminal/wezterm/wezterm.lua`）と操作の
筋肉記憶を共有できるよう、herdr のキー割り当てを wezterm 側へ寄せる。

ユーザーが挙げた「使い心地が最悪」の主因（複数該当）:

1. 文字割り当てが wezterm と違う（分割・新タブ・タブ移動など）
2. prefix 不要の `ctrl+alt+*` 直接 chord が覚えられない／衝突する
3. `q` の挙動が正反対（wezterm=タブを閉じる / herdr=detach）で事故る
4. prefix キー自体（`ctrl+b`）… ただし後述の制約から据え置き

## 制約（設計判断の前提）

- **wezterm のリーダーキー CapsLock は herdr で再現不可**。CapsLock は
  `caps:none` で VoidSymbol 化され wezterm が横取りする。herdr は wezterm の
  _中で_ 動く TUI なので、CapsLock はターミナル層で消費され herdr に届かない。
  そもそも CapsLock はロックモディファイアで、TUI がキー入力として受け取れない。
  → prefix キーそのものは wezterm と一致させられない。**`ctrl+b` を据え置き**、
  「prefix→単一文字」のモーダル操作リズムだけを wezterm と一致させる方針にする。

- **herdr にキーボードのコピーモードは存在しない**。`herdr --default-config` に
  `copy_mode` 相当のキー項目は無い。スクロール／コピーは次の3手段のみ:
  - マウスホイールでスクロール（`ui.mouse_scroll_lines`）
  - マウスのドラッグ／ダブルクリックで選択コピー（`ui.copy_on_select`）
  - `prefix+e`（`edit_scrollback`）でスクロールバックを外部エディタで開く
    → wezterm のスクロール／コピー系キーは寄せる先が無い。herdr 流を受け入れる。

## 方針

- prefix = `ctrl+b` 維持。押下後の**単一文字**を wezterm の `LEADER+文字` に一致させる。
- `ctrl+alt+*` の直接 chord は**全廃**し、全操作を `prefix→文字` に一本化する。
  これは同一操作への別入力経路を消すだけで、操作自体は prefix 経由で全て残る（減機能ではない）。
- 危険な衝突を解消: `q`=タブを閉じる、detach は `prefix+d`（tmux 定番）へ退避。
- スクロール／コピーは `prefix+e` + マウスに集約し、キーで無理に寄せない。

## キー対応表

| 操作                   | wezterm `LEADER+X` | 新 herdr                   | 現 herdr     | herdr アクション名                    |
| ---------------------- | ------------------ | -------------------------- | ------------ | ------------------------------------- |
| ペイン移動 左/下/上/右 | `h`/`j`/`k`/`l`    | `prefix+h`/`j`/`k`/`l`     | 同左(+chord) | `focus_pane_left`/`down`/`up`/`right` |
| 分割 左右              | `s`                | `prefix+s`                 | (minus)      | `split_*`（★向き検証）                |
| 分割 上下              | `v`                | `prefix+v`                 | `v`          | `split_*`（★向き検証）                |
| ペインを閉じる         | `m`                | `prefix+m`                 | `x`          | `close_pane`                          |
| ズーム                 | `z`                | `prefix+z`                 | `z`          | `zoom`                                |
| リサイズモード         | `r`                | `prefix+r`                 | `r`          | `resize_mode`                         |
| 新しいタブ             | `n`                | `prefix+n`                 | `c`          | `new_tab`                             |
| タブを閉じる           | `q`                | `prefix+q`                 | `shift+x`    | `close_tab`                           |
| 前/次のタブ            | `H`/`L`            | `prefix+shift+h`/`shift+l` | `p`/`n`      | `previous_tab`/`next_tab`             |
| タブ 1〜5              | `1`〜`5`           | `prefix+1..9`              | 同左         | `switch_tab`                          |
| detach                 | ―（概念なし）      | `prefix+d`                 | `q`          | `detach`                              |
| scrollback/コピー      | (copy モード)      | `prefix+e` + マウス        | `prefix+e`   | `edit_scrollback`                     |

navigate モードの素の `h`/`j`/`k`/`l`（`navigate_pane_*`）は現状維持。

### ★実機検証事項（switch 後に潰す）

1. **分割の向き**: herdr の `split_vertical`/`split_horizontal` が作る見た目
   （左右／上下）を確認する。wezterm 基準（`s`=左右, `v`=上下）と逆なら、
   herdr 側のキー割り当てを入れ替えて**見た目基準で一致**させる。
2. `prefix+q`=close_tab、`prefix+d`=detach が意図通り効くこと。

## wezterm にあって herdr へ寄せられないもの

MANUAL に「herdr 流」として明記し、無理にキー割り当てしない。

- スクロール系（`J`/`K` ページ, `g`/`G` 端, `,`/`.` プロンプト移動, `y` コピーモード）
  → herdr にキー機構が無い。マウス + `prefix+e`。
- ペイン選択オーバーレイ（wezterm `e`=PaneSelect）→ `prefix+g`(goto)/navigate モード。
- コマンドパレット（`ctrl+shift+p`）→ `prefix+s`(settings)。

## 成果物

1. `home-manager/cli/herdr/default.nix` の `keys` を上表へ書き換え。
   - `focus_pane_*` から `ctrl+alt+*` を削除し `prefix+hjkl` のみに。
   - `new_tab`/`close_tab`/`previous_tab`/`next_tab`/`split_*`/`close_pane`/
     `detach` を上表の割り当てに設定。
   - navigate モード（`navigate_pane_*`）は据え置き。
2. `MANUAL.md` を新キーで全面更新。
   - 「5. コピーモード（vim 操作）」の節は herdr に該当機能が無いため**削除**し、
     マウス + `prefix+e` の実態に直す。
   - vim chord 早見表・「まず覚える5つ」を新キーに更新。detach を `prefix+d` に。
3. 反映: `nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl`。
   反映後、実機で ★検証事項（分割の向き・q/d）を確認し、必要なら向きを入れ替える。

## 非目標（YAGNI）

- prefix キーの変更（`ctrl+a` 等）。制約検討の結果 `ctrl+b` 据え置きで確定。
- スクロール／コピーの vim 化。herdr に機構が無いため対象外。
- テーマ・UI 設定の変更。今回はキーのみ。
