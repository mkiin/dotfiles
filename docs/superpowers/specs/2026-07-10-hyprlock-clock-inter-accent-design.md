# hyprlock 時計の Inter Display SemiBold への刷新とアクセント罫線

- 対象: `home-manager/desktop/hyprland/`（hyprlock.conf・`scripts/lock/lock-clock.sh`・色テンプレート）と `nixos/core/fonts`
- 前提: 2026-07-09 spec のポスター時計（Anton 2トーン）は「コンデンス極太の主張が強すぎる」「日付が時計に対して地味」で不採用。左下ポスター構図と scrim は維持し、書体と要素構成を差し替える。

## デザイン主題

Anton の極太コンデンスをやめ、**Inter Display SemiBold の時計に、オレンジの短い罫線と字間の広い日付を組み合わせる**。

```
║              (キャラ)                 ║
║           [ password ]               ║
║   10:31 ᴬᴹ                           ║  Inter Display SemiBold / 数字=クリーム / AM=アクセント
║   ──                                 ║  shape 罫線・アクセント色
║   F R I D A Y ,  J U L Y  1 0        ║  Inter Display SemiBold・大文字・ワイドトラッキング
```

- 数字は単色クリーム（`on_surface`）。時と分を塗り分けた 2 トーンはやめ、アクセント色は AM/PM と罫線に集約する。色数を絞ることで、書体を細くしなくても圧が下がる。
- AM/PM は数字の右肩に小さく、アクセント色・字間広め・SemiBold。
- 時計と日付の間に、hyprlock の `shape` ウィジェットで短い水平罫線（アクセント色・角丸）を置く。
- 日付は大文字フルスペル 1 行 `FRIDAY, JULY 10`（`%A, %B %d`）のまま、サイズを 19 → 30 に上げ、letter_spacing を大きく取る。「地味」問題はこのサイズとトラッキングで解決する。
- 入力欄・背景・scrim・アニメーションは現状維持。

## トークン再設計

| 役割        | 値                                                                       |
| ----------- | ------------------------------------------------------------------------ |
| 数字        | `$lock_time` = `on_surface` 100%                                         |
| AM/PM・罫線 | `$lock_accent` = `primary` 100%                                          |
| 日付        | `$lock_date` = `on_surface` 95%                                          |
| 廃止        | `$lock_hour` `$lock_colon` `$lock_minute` `$lock_ampm`                   |
| 維持        | `$lock_shadow` `$lock_input_*` `$lock_hint` `$lock_success` `$lock_fail` |

色はすべて matugen 由来を維持する（壁紙変更に追従）。

## レイアウト定数

実機プレビュー（DP-2 で `hyprlock -c` による撮影）で確定させた値。

| 要素  | 値                                                                                      |
| ----- | --------------------------------------------------------------------------------------- |
| 時計  | Inter Display SemiBold・font_size 135・position 70, 175                                 |
| AM/PM | 時計ラベル内の span。size 34816・rise 75000・letter_spacing 3072                        |
| 罫線  | shape・90×4・rounding 2・position 76, 175                                               |
| 日付  | Inter Display（span で semibold）・font_size 30・letter_spacing 10240・position 76, 112 |

- ラベルは時刻・日付の 2 枚と shape 1 枚。すべて `halign = left, valign = bottom` の同一 x 起点なので、日付の文字数が変わっても整列は崩れない。
- AM/PM の rise は font_size 135 の Inter Display に合わせた定数。書体やサイズを変えるときは再調整が要る。

## 変更ファイル

| ファイル                                                   | 変更                                                                                        |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `home-manager/desktop/hyprland/hyprlock.conf`              | 時計・日付ラベルの書体とサイズと位置を更新し、shape 罫線を追加                              |
| `home-manager/desktop/hyprland/lock-colors.template.conf`  | トークン再設計（`$lock_time` `$lock_accent` へ集約）                                        |
| `home-manager/desktop/hyprland/lock-colors.conf`           | 再生成                                                                                      |
| `home-manager/desktop/hyprland/scripts/lock/lock-clock.sh` | time モードを単色数字＋アクセント AM/PM に、date モードを 30px ワイドトラッキング向けに更新 |
| `nixos/core/fonts/default.nix`                             | Anton を削除（本デザインで参照が無くなる）                                                  |

## 受け入れ基準

- 左下にクリーム単色の Inter Display SemiBold 時刻、右肩にアクセント色の AM/PM、その下にアクセント罫線と大文字フルスペル日付が左端揃えで表示される。
- `LOCK_CLOCK_AT=2026-09-23`（WEDNESDAY, SEPTEMBER 23 = 最長級）でも崩れない（左揃えなので原理的に安全だが目視確認する）。
- 3 画面同一。入力欄（中央）は無変更で動作。
- Anton 削除後も他のビルドが通る（参照が残っていない）。
- `nix run .#build` / `nix run .#fmt -- --fail-on-change` 緑。

## 改訂（2026-07-10 実機レビュー後）

Inter Display SemiBold 案は実機確認で不採用となり、実写比較で選ばれたモノスペース案に置き換えた。

- 数字: JetBrainsMono Nerd Font ExtraLight・font_size 115・2 トーン（時=`$lock_time`、コロンと分=`$lock_accent`）
- AM/PM: 数字の右上に浮かせる（span size 30720・rise 56000）・`$lock_ampm` = `on_surface` 60%
- 日付: `FRI · JUL 10` 短縮形・JetBrainsMono Nerd Font Light 24・曜日のみ `$lock_accent`
- 罫線（shape）は廃止。`$lock_rule` を削除し `$lock_ampm` を追加
- 配置は当初のポスター時計と同じ 70,85 / 74,80
