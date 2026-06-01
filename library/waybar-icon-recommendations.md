# Waybar Icon 採用候補一覧 (Nerd Font 3.4.0)

調査元: `/home/mkiin/dotfiles/wiki/nerd-fonts/glyphnames.json`
target: `/home/mkiin/dotfiles/home/dot_config/waybar/config.jsonc`

## 凡例

- **第一推奨は太字**
- codepoint は U+ 表記 (16進小文字)、glyph 名は `nf-prefix-name` 表記
- 「現状」: 今 `config.jsonc` にある icon、なければ —
- 「判定」: 現状維持 / 差し替え推奨 / 新規採用
- セット優先順位: `md` (Material Design Icons) > `fa` > その他。`md` は cell 中央配置と統一感が良く既存 config も `md` 中心
- `font: JetBrains Nerd Font 10` のため Nerd Font 3.4.0 全 set 利用可能

---

## 1. Archlinux ランチャー (`custom/archlinux`)

現状: `` (U+f303, `nf-linux-archlinux`)
推奨: **`󰣇` (U+f08c7, `nf-md-arch`)** — md 統一感、現に `custom/nix` で使用中
判定: **差し替え推奨** (md セットに揃える)

代替:
- `` U+e732 `nf-dev-archlinux` — Devicons 版。立体感あり
- `` U+f303 `nf-linux-archlinux` — 現状維持したい場合
- `󰵆` U+f0d46 `nf-md-apps_box` — 「ランチャー」記号として中立
- `󰀻` U+f003b `nf-md-apps` — apps grid (汎用)
- `󰕮` U+f056e `nf-md-view_dashboard` — ダッシュボード系

---

## 2. Pacman 更新 (`custom/pacman`)

現状: `󰮯` (U+f0baf, `nf-md-pac_man`)
推奨: **`󰮯` (U+f0baf, `nf-md-pac_man`)** — pacman そのもの。これ以外の選択肢無し
判定: **現状維持**

代替:
- `󰏖` U+f03d6 `nf-md-package_variant` — pkg 一般化したい場合
- `󰚰` U+f06b0 `nf-md-update` — 「更新」を強調

---

## 3. AUR 更新 (`custom/aur`)

現状: `` (U+f590, glyphnames 未収録 / FA-pro 系の可能性)
推奨: **`󰏗` (U+f03d7, `nf-md-package_variant_closed`)** — pacman と並べて pkg 系で揃える
判定: **差し替え推奨** (現状の glyph は 3.4.0 メタに無く、フォントによっては □ 表示)

代替:
- `󰏖` U+f03d6 `nf-md-package_variant` — 開いた箱
- `󰅢` U+f0162 `nf-md-cloud_download` — AUR=ビルド取得のニュアンス
- `󰘬` U+f062c `nf-md-source_branch` — git ベースという意味で
- `󰀼` U+f003c `nf-md-archive` — アーカイブ系

---

## 4. Mise 更新 (`custom/mise`)

現状: `󰖓` (U+f0593, `nf-md-weather_lightning`)
推奨: **`󰦬` (U+f09ac, `nf-md-toolbox`)** — 言語ツールチェーン管理に意味的に合致
判定: **差し替え推奨** (現状は天気の雷アイコンで意味不明)

代替:
- `󱁤` U+f1064 `nf-md-tools` — ツール群
- `󰆦` U+f01a6 `nf-md-cube` — runtime cube
- `󰚰` U+f06b0 `nf-md-update` — 「更新」直球
- `󱑠` U+f1460 `nf-md-cog_sync` — 同期

---

## 5. Weather (`custom/weather`)

現状: スクリプト出力依存 (`weather.sh` が icon を返す)
推奨: **`󰖕` (U+f0595, `nf-md-weather_partly_cloudy`)** — デフォルト/未取得時の汎用表示に
判定: **新規採用** (スクリプト fallback として)

代替 (スクリプト内マッピング向け):
- `󰖙` U+f0599 `nf-md-weather_sunny`
- `󰖐` U+f0590 `nf-md-weather_cloudy`
- `󰖔` U+f0594 `nf-md-weather_night`
- `󰖗` U+f0597 `nf-md-weather_rainy`
- `󰖖` U+f0596 `nf-md-weather_pouring`
- `󰖘` U+f0598 `nf-md-weather_snowy`
- `󰖓` U+f0593 `nf-md-weather_lightning`

---

## 6. Notification / swaync (`custom/swaync`)

現状:
- notification: `󱅫` (U+f116b, `nf-md-bell_badge`)
- none: `󰂜` (U+f009c, `nf-md-bell_outline`)
- dnd-notification: `󰂠` (U+f00a0, `nf-md-bell_sleep`)
- dnd-none: `󰪓` (U+f0a93, `nf-md-bell_sleep_outline`)
- inhibited-notification: `󰂛` (U+f009b, `nf-md-bell_off`)
- inhibited-none: `󰪑` (U+f0a91, `nf-md-bell_off_outline`)

推奨: **現状維持** — md-bell ファミリーで最も整理された組み合わせ。outline=none、塗り=active、_sleep=dnd、_off=inhibited が一貫
判定: **現状維持**

代替候補 (もし alert 系に振りたい場合):
- `󰵙` U+f0d59 `nf-md-bell_alert` — 通知強調
- `󰂞` U+f009e `nf-md-bell_ring` — リング
- `󰂚` U+f009a `nf-md-bell` — 塗りの通常 bell

---

## 7. Power メニュー (`custom/power`)

現状: `󰐥` (U+f0425, `nf-md-power`)
推奨: **`󰐥` (U+f0425, `nf-md-power`)** — 一般的な電源記号。現状最適
判定: **現状維持**

代替:
- `󰤆` U+f0906 `nf-md-power_standby` — スタンバイ寄り
- `󰤂` U+f0902 `nf-md-power_off` — off 強調
- `󰐦` U+f0426 `nf-md-power_settings` — 設定もまとまった画面なら
- `` U+f011 `nf-fa-power_off` — fa 版

---

## 8. Bluetooth (`bluetooth`)

現状:
- enabled: `` (U+f293, `nf-fa-bluetooth`)
- disabled: `` (U+f294, `nf-fa-bluetooth_b`)

推奨: **`󰂯` (U+f00af, `nf-md-bluetooth`) / `󰂲` (U+f00b2, `nf-md-bluetooth_off`)**
判定: **差し替え推奨** (md に揃えると waybar 全体の整合性が上がる。現状 fa のみ浮いている)

代替:
- `󰂱` U+f00b1 `nf-md-bluetooth_connect` — 接続中専用
- `󰂰` U+f00b0 `nf-md-bluetooth_audio` — オーディオ
- `` U+f293 `nf-fa-bluetooth` — 現状維持の場合

---

## 9. Network (`network`)

現状:
- wifi: `` (U+f1eb, `nf-fa-wifi`)
- ethernet: `󰌘` (U+f0318, `nf-md-lan_connect`)
- disconnected: `` (U+f0c1, `nf-fa-link`)

推奨:
- wifi: **`󰖩` (U+f05a9, `nf-md-wifi`)**
- ethernet: **`󰈀` (U+f0200, `nf-md-ethernet`)** または現状の `󰌘`
- disconnected: **`󰖪` (U+f05aa, `nf-md-wifi_off`)**

判定: **差し替え推奨** (wifi/disconnected が fa 混在。md に統一すると bluetooth と並んで cell 中央が揃う)

代替:
- `󰤨` U+f0928 `nf-md-wifi_strength_4` — 強度バー付き
- `󰤯` U+f092f `nf-md-wifi_strength_outline` — 弱
- `󰲛` U+f0c9b `nf-md-network_off` — 汎用切断
- `󰌙` U+f0319 `nf-md-lan_disconnect` — ethernet 切断
- `` U+f1eb `nf-fa-wifi` — 現状

---

## 10. Pulseaudio (`pulseaudio`)

現状:
- default low: `` (U+f027, `nf-fa-volume_low`)
- default high: `` (U+f028, `nf-fa-volume_up`)
- muted: `` (U+f026, `nf-fa-volume_off`)
- headphone: `` (U+f025, `nf-fa-headphones`)
- headset: `` (U+ed17, `nf-fa-phone_slash`) ← 不適切
- phone: `` (U+f095, `nf-fa-phone`)
- phone-muted: `` (U+ed17, `nf-fa-phone_slash`) ← 重複
- car: `` (U+f1b9, `nf-fa-car`)
- hands-free: `` (U+f0e7, `nf-fa-flash`) ← 意味不明
- portable: `` (U+f1b2, `nf-fa-cube`)
- alsa muted: `` (U+eee8, `nf-fa-volume_xmark`)

推奨: **md セットに全面差し替え**
- default low: **`󰕿` (U+f057f, `nf-md-volume_low`)**
- default high: **`󰕾` (U+f057e, `nf-md-volume_high`)**
- muted: **`󰝟` (U+f075f, `nf-md-volume_mute`)**
- headphone: **`󰋋` (U+f02cb, `nf-md-headphones`)**
- headset: **`󰋎` (U+f02ce, `nf-md-headset`)** (現状の phone_slash は誤用)
- hands-free: **`󰜟` (U+f071f, `nf-md-speaker_wireless`)** (現状の flash は誤用)
- phone: **`󰏲` (U+f03f2, `nf-md-phone`)**
- phone-muted: **`󰷯` (U+f0def, `nf-md-phone_off`)** (現状は headset と重複)
- car: **`󰄋` (U+f010b, `nf-md-car`)**
- portable: **`󰄜` (U+f011c, `nf-md-cellphone`)**

判定: **差し替え推奨** (特に headset / hands-free / phone-muted は意味不一致)

代替:
- `󰖀` U+f0580 `nf-md-volume_medium`
- `󰋌` U+f02cc `nf-md-headphones_box`
- `󰓃` U+f04c3 `nf-md-speaker`

---

## 11. CPU (`cpu`)

現状: `` (U+f4bc, `nf-oct-cpu`)
推奨: **`󰻠` (U+f0ee0, `nf-md-cpu_64_bit`)** — md 統一
判定: **差し替え推奨** (oct 混在を解消)

代替:
- `󰘚` U+f061a `nf-md-chip`
- `󰚗` U+f0697 `nf-md-developer_board`
- `` U+f4bc `nf-oct-cpu` — 現状維持の場合
- `󰻟` U+f0edf `nf-md-cpu_32_bit`

---

## 12. Memory (`memory`)

現状: `` (U+f538, glyphnames 未収録)
推奨: **`󰍛` (U+f035b, `nf-md-memory`)** — md 統一・確実な収録
判定: **差し替え推奨** (現状の f538 は 3.4.0 メタに無く欠けるリスク)

代替:
- `󰆼` U+f01bc `nf-md-database`
- `󰘚` U+f061a `nf-md-chip`
- `󱘲` U+f1632 `nf-md-database_outline`

---

## 13. Temperature (`temperature`)

現状: `󰔏` (U+f050f, `nf-md-thermometer`) (通常時 / critical 時とも)
推奨: **`󰔏` (U+f050f, `nf-md-thermometer`)** — シンプルで md 統一
判定: **現状維持**

代替 (critical 表示用に分けたい場合):
- `󰸁` U+f0e01 `nf-md-thermometer_alert` — 警告
- `󱃂` U+f10c2 `nf-md-thermometer_high` — 高温
- `󰔐` U+f0510 `nf-md-thermometer_lines` — 目盛入り
- `` U+f06d `nf-fa-fire` — 危険炎

---

## 14. Idle Inhibitor (`idle_inhibitor`)

現状:
- activated: `` (U+f06e, `nf-fa-eye`)
- deactivated: `` (U+f070, `nf-fa-eye_slash`)

推奨: **`󰈈` (U+f0208, `nf-md-eye`) / `󰈉` (U+f0209, `nf-md-eye_off`)**
判定: **差し替え推奨** (md に統一。意味は同じ)

代替 (コーヒー系で「眠らない」を表現):
- `󰅶` U+f0176 `nf-md-coffee` (active) / `󰾪` U+f0faa `nf-md-coffee_off` (inactive)
- `󰛨` U+f06e8 `nf-md-lightbulb_on` / `󰹏` U+f0e4f `nf-md-lightbulb_off`
- `󰒲` U+f04b2 `nf-md-sleep` / `󰒳` U+f04b3 `nf-md-sleep_off`
- `` U+f185 `nf-fa-sun_o` / `` U+f186 `nf-fa-moon_o`

---

## 15. Clock (`clock`)

現状:
- format: `` (U+f017, `nf-fa-clock_o`)
- format-alt: `󰸗` (U+f0e17, `nf-md-calendar_month`)

推奨:
- format: **`󰥔` (U+f0954, `nf-md-clock`)**
- format-alt: **`󰸗` (U+f0e17, `nf-md-calendar_month`)** (現状維持)

判定: **差し替え推奨** (clock 側を md に。calendar 側は現状維持で合う)

代替:
- `󰅐` U+f0150 `nf-md-clock_outline` — 線画
- `󰖉` U+f0589 `nf-md-watch` — 腕時計
- `󰃭` U+f00ed `nf-md-calendar` — シンプル calendar
- `` U+f017 `nf-fa-clock_o` — 現状維持の場合

---

## 16. Workspaces (`hyprland/workspaces`)

現状:
- default: `` (U+f111, fa-circle 系 / glyphnames には無い codepoint)
- urgent: `` (U+f192, fa-dot-circle-o 系)

推奨: **`󰧞` (U+f09de, `nf-md-circle_medium`) / `󰻂` (U+f0ec2, `nf-md-record_circle`)**
判定: **差し替え推奨** (md 統一・3.4.0 で確実に存在)

代替:
- `󰄯` U+f012f `nf-md-checkbox_blank_circle` (active)
- `󰄰` U+f0130 `nf-md-checkbox_blank_circle_outline` (default)
- `󱓻` U+f14fb `nf-md-square_rounded` — 角丸正方形
- `󱓼` U+f14fc `nf-md-square_rounded_outline` — outline 版
- `󰧟` U+f09df `nf-md-circle_small` — より小

---

## 17. Tray (`tray`)

現状: 未指定 (system tray は app icon を直接表示)
推奨: **— (icon 設定不要)** — tray 自身は icon を持たず blueman/Telegram 等の app icon を表示
判定: **新規採用不要**

参考 (もし label 用に必要なら):
- `󱊔` U+f1294 `nf-md-tray`
- `󱊖` U+f1296 `nf-md-tray_full`
- `󰚇` U+f0687 `nf-md-inbox`

---

## 優先順 まとめ表

| モジュール | 現状 glyph | 現状名 | 推奨 glyph | 推奨名 | 判定 |
|---|---|---|---|---|---|
| custom/archlinux | `` | nf-linux-archlinux (U+f303) | `󰣇` | nf-md-arch (U+f08c7) | 差し替え推奨 |
| custom/pacman | `󰮯` | nf-md-pac_man (U+f0baf) | `󰮯` | nf-md-pac_man (U+f0baf) | 現状維持 |
| custom/aur | `` | (3.4.0 未収録 U+f590) | `󰏗` | nf-md-package_variant_closed (U+f03d7) | 差し替え推奨 |
| custom/mise | `󰖓` | nf-md-weather_lightning (U+f0593) | `󰦬` | nf-md-toolbox (U+f09ac) | 差し替え推奨 |
| custom/weather | (script) | — | `󰖕` | nf-md-weather_partly_cloudy (U+f0595) | 新規採用 |
| custom/swaync | `󱅫`/`󰂜`/`󰂠`/`󰪓`/`󰂛`/`󰪑` | nf-md-bell_* family | (同左) | (同左) | 現状維持 |
| custom/power | `󰐥` | nf-md-power (U+f0425) | `󰐥` | nf-md-power (U+f0425) | 現状維持 |
| bluetooth (on/off) | ``/`` | nf-fa-bluetooth / nf-fa-bluetooth_b | `󰂯`/`󰂲` | nf-md-bluetooth / nf-md-bluetooth_off | 差し替え推奨 |
| network wifi | `` | nf-fa-wifi (U+f1eb) | `󰖩` | nf-md-wifi (U+f05a9) | 差し替え推奨 |
| network ethernet | `󰌘` | nf-md-lan_connect (U+f0318) | `󰈀` | nf-md-ethernet (U+f0200) | 差し替え推奨 |
| network disconnected | `` | nf-fa-link (U+f0c1) | `󰖪` | nf-md-wifi_off (U+f05aa) | 差し替え推奨 |
| pulseaudio low/high | ``/`` | nf-fa-volume_low / nf-fa-volume_up | `󰕿`/`󰕾` | nf-md-volume_low / nf-md-volume_high | 差し替え推奨 |
| pulseaudio muted | `` | nf-fa-volume_off (U+f026) | `󰝟` | nf-md-volume_mute (U+f075f) | 差し替え推奨 |
| pulseaudio headphone | `` | nf-fa-headphones (U+f025) | `󰋋` | nf-md-headphones (U+f02cb) | 差し替え推奨 |
| pulseaudio headset | `` | nf-fa-phone_slash (U+ed17) ← 誤用 | `󰋎` | nf-md-headset (U+f02ce) | 差し替え推奨 |
| pulseaudio hands-free | `` | nf-fa-flash (U+f0e7) ← 誤用 | `󰜟` | nf-md-speaker_wireless (U+f071f) | 差し替え推奨 |
| pulseaudio phone | `` | nf-fa-phone (U+f095) | `󰏲` | nf-md-phone (U+f03f2) | 差し替え推奨 |
| pulseaudio phone-muted | `` | nf-fa-phone_slash (U+ed17) ← 重複 | `󰷯` | nf-md-phone_off (U+f0def) | 差し替え推奨 |
| pulseaudio car | `` | nf-fa-car (U+f1b9) | `󰄋` | nf-md-car (U+f010b) | 差し替え推奨 |
| pulseaudio portable | `` | nf-fa-cube (U+f1b2) | `󰄜` | nf-md-cellphone (U+f011c) | 差し替え推奨 |
| cpu | `` | nf-oct-cpu (U+f4bc) | `󰻠` | nf-md-cpu_64_bit (U+f0ee0) | 差し替え推奨 |
| memory | `` | (3.4.0 未収録 U+f538) | `󰍛` | nf-md-memory (U+f035b) | 差し替え推奨 |
| temperature | `󰔏` | nf-md-thermometer (U+f050f) | `󰔏` | nf-md-thermometer (U+f050f) | 現状維持 |
| idle activated | `` | nf-fa-eye (U+f06e) | `󰈈` | nf-md-eye (U+f0208) | 差し替え推奨 |
| idle deactivated | `` | nf-fa-eye_slash (U+f070) | `󰈉` | nf-md-eye_off (U+f0209) | 差し替え推奨 |
| clock format | `` | nf-fa-clock_o (U+f017) | `󰥔` | nf-md-clock (U+f0954) | 差し替え推奨 |
| clock format-alt | `󰸗` | nf-md-calendar_month (U+f0e17) | `󰸗` | nf-md-calendar_month (U+f0e17) | 現状維持 |
| workspaces default | `` | (fa-circle 系 U+f111) | `󰧞` | nf-md-circle_medium (U+f09de) | 差し替え推奨 |
| workspaces urgent | `` | (fa-dot-circle 系 U+f192) | `󰻂` | nf-md-record_circle (U+f0ec2) | 差し替え推奨 |
| tray | — | — | — | (icon 不要) | — |

### 全体方針メモ

- 現状は `md` / `fa` / `oct` / `linux` が混在しており、cell 高さと太さの揺れが visual noise になっている
- `custom/swaync` の bell ファミリーは既に `md` で完結しており、これを基準に他モジュールを `md` に揃えると統一感が出る
- `custom/pacman` (`󰮯`) と `temperature` (`󰔏`) と `custom/power` (`󰐥`) は md 由来かつ意味が完全一致のため現状維持
- 特に意味的に誤用が見られるのは pulseaudio の `headset` / `hands-free` / `phone-muted` (phone_slash や flash で代用されている)。優先度高め
