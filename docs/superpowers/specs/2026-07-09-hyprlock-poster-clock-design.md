# hyprlock ポスター時計（左下・Anton 2トーン）設計

- 対象: `home-manager/desktop/hyprland/`（hyprlock.conf・`scripts/lock/`・色テンプレート）と `nixos/core/fonts`
- 前提: caelestia 風右上時計（2026-07-06 / 2026-07-08 spec）は「縦棒の印象が薄い・日付が細い・絶対座標での 3 要素整列が hyprlock に不向き」で不採用。本稿で構図から刷新する。

## デザイン主題

壁紙がアニメのキービジュアルであることを根拠に、**ロック画面全体を「ポスター」、時計を左下の「タイトルクレジット」として組む**。

```
║              (キャラ)                 ║
║           [ password ]               ║
║  ▒▓ 10:38 ᴾᴹ                        ║  Anton 極太 / hour=白 / minute=アクセント
║  ▒▓ WEDNESDAY, JULY 08               ║  Inter Bold・大文字・ワイドトラッキング
```

- シグネチャは **Anton 極太数字の 2 トーン**（時=白 / 分=matugen primary）の一点。他の装飾は置かない。縦棒 shape は廃止。
- 日付は大文字フルスペル 1 行 `WEDNESDAY, JULY 08`（`%A, %B %d`）。太さとトラッキングで「細い」問題を解決する。
- 入力欄・背景・アニメーションは現状維持。

## トークン

| 役割   | 値                                                                       |
| ------ | ------------------------------------------------------------------------ |
| 時     | Anton・`$lock_hour` = `on_surface` 100%                                  |
| コロン | Anton・`$lock_colon` = `primary` 80%                                     |
| 分     | Anton・`$lock_minute` = `primary` 100%                                   |
| AM/PM  | Anton 小・上寄せ・`$lock_ampm` = `on_surface` 60%                        |
| 日付   | Inter Bold・letter_spacing 広め・`$lock_date` = `on_surface` 90%         |
| 廃止   | `$lock_divider` `$lock_month` `$lock_day` `$lock_weekday`                |
| 維持   | `$lock_shadow` `$lock_input_*` `$lock_hint` `$lock_success` `$lock_fail` |

色はすべて matugen 由来を維持（壁紙変更に追従）。

## レイアウトと堅牢性

- ラベルは時刻・日付の **2 枚だけ**。両方 `halign = left, valign = bottom` の同一 x オフセットに置く。左揃えのため日付の文字数（最長 `WEDNESDAY, SEPTEMBER 23` 等）が変わっても**整列は原理的に崩れない**。座標調整は y 方向の行間と左下マージンのみ。
- scrim（コーナー減光）は既存の `gen-lock-scrim.sh` の焦点を左下角（`gradient:center=0,H`）へ変更して再生成し、image ウィジェットを `halign = left, valign = bottom` に張り替える。

## フォント導入

- `nixos/core/fonts/default.nix` の `fonts.packages` に `(google-fonts.override { fonts = [ "Anton" ]; })` を追加（フォントの集約点。CLAUDE.md のパッケージ規約に適合）。反映に `nix run .#switch` が 1 回必要。
- Anton は単一ウェイト・大文字主体のコンデンス体。時刻数字と AM/PM に使う。日付は既存 Inter。

## 変更ファイル

| ファイル                                                       | 変更                                                                                      |
| -------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| `nixos/core/fonts/default.nix`                                 | Anton 追加                                                                                |
| `home-manager/desktop/hyprland/lock-colors.template.conf`      | トークン再設計（date 統合・divider 系廃止）                                               |
| `home-manager/desktop/hyprland/lock-colors.conf`               | 再生成                                                                                    |
| `home-manager/desktop/hyprland/scripts/lock/lock-clock.sh`     | date モードを 1 行 `%A, %B %d` 大文字へ。time モードのスペーサ・AM/PM を Anton 向けに調整 |
| `home-manager/desktop/hyprland/scripts/lock/gen-lock-scrim.sh` | グラデーション焦点を左下角へ                                                              |
| `images/lock/lock-scrim.png`                                   | 再生成                                                                                    |
| `home-manager/desktop/hyprland/hyprlock.conf`                  | 左下 2 ラベル構成へ組み直し・shape 廃止・scrim アンカー変更                               |

## 受け入れ基準

- 左下に Anton の巨大 2 トーン時刻（時=白・分=アクセント）と、太い大文字フルスペル日付が左端揃えで表示される。縦棒が存在しない。
- `LOCK_CLOCK_AT=2026-09-23`（WEDNESDAY, SEPTEMBER 23 = 最長級）でも崩れない（左揃えなので原理的に安全だが目視確認する）。
- scrim が左下コーナーを減光し、文字が明瞭に読める。縁・バンディングなし。3 画面同一。
- 入力欄（中央）は無変更で動作。
- `nix run .#build` / `nix run .#fmt -- --fail-on-change` 緑。
