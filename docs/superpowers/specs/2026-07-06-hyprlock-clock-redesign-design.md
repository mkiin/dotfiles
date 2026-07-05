# hyprlock 時刻表示リデザイン 設計

- 日付: 2026-07-06
- 対象: `home-manager/desktop/hyprland/hyprlock.conf`・関連スクリプト・matugen ロックカラーテンプレート
- hyprlock バージョン: v0.9.5
- 参考デザイン: caelestia-shell の `DesktopClock.qml`（Reddit "bad caelestia apple"）

## 目的

ロック画面の時刻・日付表示を、caelestia 風の「大きな時計 + 区切り線 + 日付カラム」レイアウトに刷新する。todo.md の「時計と日付のサイズを大きくしたい」への対応がメイン。既存の Ambient 方向（写真主役・極小 UI・入力欄中央）は維持し、**時刻表示クラスタのみ**を再設計・再配置する。アバター・挨拶・ヒント等の新規要素は追加しない（スコープ外）。

## 参考デザインの解析結果

caelestia の `DesktopClock.qml` を実解析した結果、以下の構成だった。

- フォント: `GoogleSansFlex`（バリアブル、丸み軸 `ROND=25`）を時刻・日付とも使用。
- 配色は Material 3 の 3 ロール（primary / secondary / tertiary）を使い分ける。

| 要素          | M3 ロール       | 装飾                          |
| ------------- | --------------- | ----------------------------- |
| 時 `12`       | primary         | Bold                          |
| `:`           | tertiary @0.8   | 少し上へオフセット            |
| 分 `22`       | secondary       | Bold                          |
| `AM`/`PM`     | secondary       | 小・上寄せ                    |
| 区切り線      | primary @0.8    | 幅4・角丸 full                |
| 月 `JUNE`     | secondary       | letter_spacing 4・Bold・大文字 |
| 日 `21`       | primary         | letter_spacing 2・Medium      |
| 曜日 `Sunday` | secondary       | letter_spacing 2・Normal      |

レイアウトは左から `[時刻][区切り線][日付カラム]` を横に並べ、全体を右上に配置。日付カラムは月・日・曜日の縦積みで左揃え。

## 決定事項

| 項目           | 決定                                                                       |
| -------------- | -------------------------------------------------------------------------- |
| 配置           | 画面右上（参考に忠実。`valign=top, halign=right`、右/上マージン ~60px）     |
| 時刻形式       | 12 時間 + AM/PM（`%-I:%M %p`）                                              |
| 日付形式       | 月 `%B`(大文字) / 日 `%d` / 曜日 `%A`（`LC_ALL=C` で英語強制）              |
| フォント       | `Inter Display`（採用）。代打案は後述                                       |
| 配色           | caelestia の M3 3 色スキームを踏襲（primary/secondary/tertiary + divider）  |
| 時刻の色分け   | Pango マークアップ（1 ラベル）+ ヘルパースクリプトで現在時刻とマークアップ出力 |
| 区切り線       | `shape`（細い角丸矩形）                                                     |
| 日付カラム     | 複数行の単一ラベル（`text_align=left` + `halign=right` アンカー）           |
| 入力欄         | 現状維持（中央・設定変更なし）                                              |
| 追加要素       | 無し（アバター・挨拶・ヒントは足さない）                                    |

### フォント（採用と代打案）

- **採用: `Inter Display`**。`nixos/core/fonts/default.nix` の `inter` パッケージに同梱済みで**追加宣言不要**。ExtraBold で大きな時計数字、日付は月=Bold・日=Medium・曜日=Normal。
- **代打案**（本設計では採用しない）:
  - `GoogleSansFlex` … caelestia 完全準拠。ただし現行 nixpkgs の `google-fonts` に含まれず自前パッケージ化が必要。かつ hyprlock はバリアブルフォントの軸（`ROND=25` の丸み）を制御できずデフォルト値になる。
  - `Inter`（無印）/ `DejaVu Sans` … 既存フォントで方向性が近い。
  - `JetBrainsMono Nerd Font ExtraBold` … 現状維持（等幅）。システム全体と統一されるが参考の雰囲気にはならない。

## 詳細設計

### 1. レイアウト

```
                                          ┌─ 右上アンカー (valign=top, halign=right)
       12:22 AM  │  JUNE                  │  右マージン ~60px / 上マージン ~60px
                 │   21
                 │  Sunday


                    [ password ]          ← 入力欄は現状のまま中央
```

- 左から `[時刻クラスタ] [区切り線] [日付カラム]`。全体を右上へ寄せる。
- 各要素は hyprlock の絶対座標（`position` オフセット + `halign/valign`）で配置。QML のような自動レイアウトは無いため、隣接要素の隙間・縦位置は実機で微調整する。
- ピクセル値・フォントサイズ・`rise`/`letter_spacing` の量は実装時に実機で詰める。

### 2. 時刻クラスタ（Pango マークアップ + ヘルパー）

hyprlock のラベルは Pango マークアップを解釈するため、`<span foreground='...'>` で部分ごとの色分け、`<span rise='...'>` で AM の持ち上げ、`<span size='...'>` で AM の縮小が 1 ラベルで表現できる。時刻は毎分変わるためラベルは `cmd[update:60000]` でヘルパースクリプトを呼び、スクリプトが現在時刻を埋めたマークアップ文字列を出力する。

hyprlock は `cmd[]` の出力内では `$var` を展開しない。色の単一情報源は `lock-colors.conf` に保つため、色の受け渡しは実装時に次のどちらかへ確定する。

- **案A（追加ファイル無し）**: `text = cmd[update:60000] lock-clock.sh "$lock_hour" "$lock_colon" "$lock_minute" "$lock_ampm"` のように hyprlock 側で `$var` を引数展開し、スクリプトが `rgba(rrggbbaa)` を Pango の `#rrggbb` + `fgalpha` に変換してマークアップを組む。hyprlock が text 値内の `$var` を展開する前提。実装時に v0.9.5 で要検証。
- **案B（確実）**: `gen-lock-colors.sh` に matugen テンプレートを 1 つ追加し、shell から source 可能な `lock-colors.sh`（`hour_hex=...` 等）も生成・コミットする。ヘルパーはそれを source する。生成物が 1 つ増えるが色源は matugen のまま一元化される。

実装は案 A を先に検証し、動かなければ案 B にフォールバックする。

### 3. 区切り線（shape）

```ini
shape {
    monitor =
    size = 3, 120        # 幅3px・高さは時刻の高さに合わせ実機調整
    rounding = -1        # full
    color = $lock_divider
    position = ...       # 時刻クラスタと日付カラムの間
    halign = right
    valign = top
}
```

hyprlock v0.9.5 の `shape` は `size/rounding/color/position/halign/valign` を持つ。細い角丸矩形で縦の区切り線を描く。

### 4. 日付カラム（複数行の単一ラベル）

```ini
label {
    monitor =
    text = cmd[update:60000] lock-date.sh     # または lock-clock.sh に mode 引数
    text_align = left
    halign = right
    valign = top
    position = ...
    font_family = Inter Display
    ...
}
```

- ラベル 1 つに `\n` 区切りで月・日・曜日を格納し、`text_align=left` で左揃え、`halign=right` で右端を固定する。これによりモニタ幅に依存せず左揃えカラムになる。
- 各行の色（secondary/primary/secondary）・サイズ・`letter_spacing` は Pango マークアップで行ごとに指定。時刻クラスタと同様、色源の受け渡しは 2 節の案 A/B に従う。

### 5. カラートークン再設計

現状の `$lock_clock`（primary 高アルファ）・`$lock_date`（primary_fixed）の 2 トークンでは 3 色スキームを表現できないため、matugen テンプレート `matugen/templates/lock-colors.conf` を役割別に作り直す。

| トークン        | matugen ソース（目安）      | 用途           |
| --------------- | --------------------------- | -------------- |
| `$lock_hour`    | primary                     | 時             |
| `$lock_colon`   | tertiary（低アルファ）      | コロン         |
| `$lock_minute`  | secondary                   | 分             |
| `$lock_ampm`    | secondary                   | AM/PM          |
| `$lock_divider` | primary（低アルファ）       | 区切り線       |
| `$lock_month`   | secondary                   | 月             |
| `$lock_day`     | primary                     | 日             |
| `$lock_weekday` | secondary                   | 曜日           |

- 入力欄系（`$lock_input_outline`/`$lock_input_bg`/`$lock_input_text`/`$lock_hint`）と `$lock_success`/`$lock_fail` は現状維持。
- 旧 `$lock_clock`/`$lock_date`/`$lock_shadow` は用途消滅により廃止（`$lock_shadow` は左上ラベル前提だったが右上クラスタでは shadow_passes を各ラベルに直接指定する運用に変える。影の要否は実装時に判断）。
- 生成は既存 `gen-lock-colors.sh`（`lock.jpg` 由来）を踏襲。テンプレート差し替え後に再生成し、生成物 `lock-colors.conf` をコミットする。案 B を採る場合は `lock-colors.sh` 用テンプレートと出力も追加する。

### 6. 背景・アニメーション

- 背景（`lock.jpg`・ぼかし無し・brightness 0.8）は現状維持。
- アニメーション（fadeIn/fadeOut/inputField 系）も現状維持。時刻クラスタの登場は全体フェードに乗る。

## 変更ファイル一覧

- 改修:
  - `home-manager/desktop/hyprland/hyprlock.conf`（右上クラスタ・shape・日付ラベル・時刻ラベルの cmd 化）
  - `home-manager/desktop/matugen/templates/lock-colors.conf`（トークン役割別に再設計）
  - `home-manager/desktop/hyprland/lock-colors.conf`（再生成・コミット）
  - `home-manager/desktop/hyprland/default.nix`（ヘルパースクリプトは `hypr/scripts` 配線済みのため基本追加不要。案 B 採用時は `lock-colors.sh` の lnk を追加）
- 新規:
  - `home-manager/desktop/hyprland/scripts/lock-clock.sh`（時刻クラスタのマークアップ出力。日付も mode 引数で兼ねるか `lock-date.sh` を別途）
  - （案 B 時）`home-manager/desktop/matugen/templates/lock-colors.sh` と生成物 `home-manager/desktop/hyprland/lock-colors.sh`
- 変更不要:
  - フォント（`Inter Display` は `nixos/core/fonts` の `inter` に同梱済み）

## 受け入れ基準

- 時刻・日付クラスタが画面右上に、`[時刻][区切り線][日付カラム]` の順で表示される。
- 時刻が 12 時間 + AM/PM（例 `12:22 AM`）で、時=primary・コロン=tertiary・分=secondary の 3 色で表示される。
- 日付カラムが月（大文字・字間広め）/ 日 / 曜日の縦積み・左揃えで表示され、英語表記になっている。
- 区切り線が時刻と日付の間に細い縦線として表示される。
- フォントが `Inter Display` で、時計数字が大きく視認できる。
- 入力欄は従来どおり中央に表示され、挙動が変わらない。
- 壁紙を変更してもロック画面の色・背景が変わらない（`lock.jpg` 由来で独立）。
- `nix run .#build` が通り、`nix run .#fmt -- --fail-on-change` が緑になる。

## 作業方法

- git worktree を切って作業する。
- 実機で `hyprlock` を起動して見た目を確認しながらピクセル値・サイズを詰める。
