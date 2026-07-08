# hyprlock 時計のコーナー減光 + レイアウト再構成 設計

- 対象: `home-manager/desktop/hyprland/`（hyprlock.conf・scripts・default.nix）と `images/lock/`
- hyprlock バージョン: v0.9.5
- 前提: `docs/superpowers/specs/2026-07-06-hyprlock-clock-redesign-design.md` の caelestia 風時刻表示（wip コミット `5aa9a4e` まで実装済み）の続き

## 背景と問題

第一稿（2026-07-06 設計）は実機で以下の問題があり、todo.md に「要再設計」と記録された。

1. **コントラスト不足**: 色トークンは matugen が壁紙 `lock.jpg` から生成するため、原理的に文字と背景が同系色になり溶け込む。現状の弱いドロップシャドウ（`shadow_passes 3 / boost 1.2`）では足りない。
2. **レイアウト崩れ**: 日付カラムは `halign=right` アンカー + 左揃えのため、ラベル幅（=最長行の幅）が月・曜日の文字数で変わり左端が動く。固定座標の区切り線（shape）は長い月で日付に食い込み、短い月で隙間が空きすぎる。

## 決定事項

| 項目       | 決定                                                                                                                                                             |
| ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| スコープ   | コントラスト（装飾）とレイアウト崩れの両方を hyprlock 方式のまま再設計。quickshell 等への方式変更はしない                                                        |
| 装飾方式   | **コーナー減光**: 右上だけ暗くなる境界線のないグラデーションを重ね、文字直載せの透明感を維持する。ガラスカード（scrim 板）・強シャドウ単独・壁紙全体減光は不採用 |
| 文字色     | M3 3色スキーム（時=primary / 分=secondary 等）を**現行トークンのまま維持**。コントラストは減光が担う                                                             |
| 幅変動対処 | **最大幅基準**: 最長ケース（SEPTEMBER / Wednesday）の実測幅で区切り線・間隔を決め、短い月の隙間拡大は許容。フルスペル表記を維持                                  |

## 設計

### 1. コーナー減光（scrim PNG + image ウィジェット）

- 黒→透明のラジアルグラデーション PNG（右上角が最も濃い。目安 1100×650px・角で黒 約55%、左下へ 0 に減衰）を生成し、`images/lock/lock-scrim.png` としてコミットする。
- 生成スクリプトは `home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh`（新規）。ImageMagick は `nix run nixpkgs#imagemagick` で呼び、パッケージ追加はしない（`gen-lock-colors.sh` と同じ「手元で生成してコミット」方式）。
- hyprlock.conf では `image` ウィジェットを**ラベルより前（背面）**に宣言し、右上へアンカーする:

```ini
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

- 配線: `default.nix` の `xdg.configFile` に `"hypr/lock-scrim.png".source = lnk ../../../images/lock/lock-scrim.png;` を追加。**このエントリ追加時のみ `nix run .#switch` が必要**。以後の PNG 再生成はライブ反映。
- モニタ非依存: 時計クラスタと同じ右上アンカー・固定ピクセルサイズなので、解像度の異なる 3 画面すべてで同じ見た目になる。壁紙 `lock.jpg` は無加工のまま。

**スパイク（最初に実機確認する設計リスク）**: hyprlock の image ウィジェットがアルファ付き PNG をグラデーションのまま描画できるか。不可なら壁紙焼き込み（`lock.jpg` にビネットを合成した派生画像を background に使う）へフォールバックする。

### 2. レイアウト再構成（最大幅基準）

- 基準文字列: 月 `SEPTEMBER`（大文字最長）・曜日 `Wednesday`（最長）。この実測幅から区切り線 x と時刻ラベル右端を決める。
- 整列ルール:
  - 区切り線（shape）の高さと縦位置 = 日付カラム 3 行の高さに一致
  - 時刻ラベル右端／日付カラム左端は、最長月でも区切り線と重ならない間隔を確保。短い月は右側の隙間が広がるのを許容
  - 時刻と日付カラムは上下センターを揃える
- 検証用に `lock-clock.sh` へ環境変数 `LOCK_CLOCK_AT`（例 `2026-09-23` = SEPTEMBER / Wednesday）を追加し、`date -d "$LOCK_CLOCK_AT"` で最長ケースを任意の日付で再現できるようにする。未設定時は現在時刻（既存挙動）。

### 3. スクリーンショット駆動の実機調整

- 撮影ループを `home-manager/desktop/hyprland/scripts/lock-preview.sh`（新規）としてコミットする。内容: `hyprlock` をバックグラウンド起動 → 数秒待機 → `grim` で撮影 → `pkill -USR1 hyprlock` で解除。出力先は引数または `/tmp`。
- 座標・濃度の調整はこのスクショループで行う（ロック画面は通常のスクリーンショットが撮れないため。`grim` は wlr-screencopy 経由でロックレイヤーも写り、`SIGUSR1` は hyprlock の正規解除シグナル）。

### 4. 変更ファイル一覧

| ファイル                                                  | 変更                                                   |
| --------------------------------------------------------- | ------------------------------------------------------ |
| `home-manager/desktop/hyprland/scripts/gen-lock-scrim.sh` | 新規（scrim 生成）                                     |
| `images/lock/lock-scrim.png`                              | 新規（生成物・コミット対象）                           |
| `home-manager/desktop/hyprland/default.nix`               | lnk 1 行追加                                           |
| `home-manager/desktop/hyprland/hyprlock.conf`             | image ウィジェット追加・時刻/区切り線/日付の座標再調整 |
| `home-manager/desktop/hyprland/scripts/lock-clock.sh`     | `LOCK_CLOCK_AT` 対応のみ                               |
| `home-manager/desktop/hyprland/scripts/lock-preview.sh`   | 新規（開発用撮影）                                     |
| `todo.md`                                                 | 完了マーク更新                                         |

**変更しないもの**: 色トークン（`lock-colors.conf` / matugen テンプレート）・入力欄・背景（`lock.jpg`・blur/brightness）・アニメーション。

## 受け入れ基準

- `LOCK_CLOCK_AT=2026-09-23`（SEPTEMBER / Wednesday の最長ケース）でも区切り線が日付カラムに重ならず、隙間が破綻しない。
- 時刻・日付が減光の上に載り、壁紙が明るい部分でも文字が明瞭に読める（スクショで目視確認）。
- 減光はグラデーションとして自然に減衰し、カードのような「縁」が見えない。
- 3 画面すべてで同じ見た目（右上アンカー・等倍）。
- `nix run .#build` と `nix run .#fmt -- --fail-on-change` が緑。
