# rofi メニュー仕様

dotfiles を Walker から rofi へ全面移行する際の要求仕様。

## 0. 設計前提

- rofi はワンショット（表示 → 1 つ選択 → 終了）。状態は rofi 外に持つ
- 設定変更は **基本即時反映**。状態を消費する側が毎回読み直す pull 方式
- サブメニューからの戻り = `while true; … *Back*) break` + 親側 `exec "$0"` 再入
  - 参考実装: `hyprland-config-sample/anom-dotfiles/.config/hypr/scripts/screenrec.sh`

### 0.1 Walker からの移行

| 現状 (Walker) | 置換先 (rofi) | 備考 |
|---|---|---|
| `walker` default theme（Super+R） | `rofi -show drun` | 既存 keybind 流用 |
| `walker --theme matugen --provider menus:wallselect`（Super+W） | `rofi-wallpaper.sh` | サムネキャッシュは別途生成スクリプトで担保 |
| `elephant-clipboard-bin` | `rofi-clipboard.sh` (cliphist 連携) | 別途 cliphist 導入 |
| `elephant-calc-bin` | `rofi -show calc` (rofi-calc) or 不要 | 利用頻度次第で判断 |
| `walker/config.toml` + `themes/` | `rofi/config.rasi` + `themes/*.rasi` | |
| `elephant/menus/wallselect.lua` | `rofi-wallpaper.sh` + `wallpaper-thumb.sh` | キャッシュ寸法・配置は rofi のグリッドレイアウトに合わせて再決定（既存 416x234 / `~/.cache/wallpaper-thumbs/` に縛られない）|

**移行手順**:
1. rofi 版を全機能ぶん完成させる（並行運用）
2. キーバインドを rofi へ切替
3. 動作確認後、`walker` `elephant-*-bin` `pear-desktop-bin` を AUR から削除
4. `home/dot_config/walker/` `home/dot_config/elephant/` を削除

## 1. 共通基盤

### 1.1 状態ファイル

- **形式**: shell env（`KEY=value` 1 行）
- **置き場所**: `~/.local/state/hypr/state.env` (XDG_STATE_HOME)
- **採用理由**:
  - 値が単純（bool / int / 短い文字列）で構造化が要らない
  - シェルから `. state.env` で source できるのが最も低コスト
  - 人間が直接編集しても壊れにくい
  - JSON+jq は依存と書きづらさの割に旨味がない

初期値:

```sh
WALLPAPER_NOTIFY=true
WALLPAPER_ROTATION=true
WALLPAPER_INTERVAL_SEC=1800
MATUGEN_SOURCE_INDEX=0
MATUGEN_RANDOM_INDEX=false
```

### 1.2 状態アクセサ

`~/.config/hypr/scripts/hyprctl-state`（共通ヘルパ）:

- `hyprctl-state get KEY` — 値を stdout（state.env が無ければ組み込みデフォルト値）
- `hyprctl-state set KEY value` — atomic 書換（tmp ファイル + mv、ファイル無ければ作成）
- `hyprctl-state toggle KEY` — bool 反転（true ↔ false）
- `hyprctl-state cycle KEY V1 V2 [V3..]` — 値リストを循環（プリセット用）

**初期化**: 専用の init コマンドは持たない。`get` 時に state.env が存在しなければスクリプト内のデフォルト値テーブルを返し、`set` が初めて呼ばれた時にファイルを作成する遅延初期化。

### 1.3 即時反映の流儀

| 消費側 | 反映方法 |
|---|---|
| 壁紙ローテータ | sleep ループの先頭で `. state.env` を再 source |
| matugen ラッパ | 起動時に `. state.env` |
| 通知 ON/OFF | 通知発火スクリプト側で `WALLPAPER_NOTIFY` を参照 |

**シグナル送出は使わない**。すべて「読む時に最新を見る」で統一。長時間スリープしている所だけ、スリープを短く刻むか sleep を SIGHUP で割込み解除できる作りにする（必要になったら）。

### 1.4 戻り遷移パターン

> ⚠ **設計中 (Step 3 完了)**: 7 軸決定済。次は Step 4 (共通テンプレと呼び出しルールを書く)。

#### Step 3 — 決定 (sample 照合済)

参照した sample 実装:
- `BlackNode/Configs/.config/rofi/wifi/wifi.sh` (3 階層・再帰式・notify ベース)
- `BlackNode/Configs/.config/rofi/powermenu/powermenu.sh` (2 階層・単発式・確認ダイアログ)
- `noro-dotfiles/dotfiles/.config/rofi/applets/bin/powermenu.sh` (単発式の別実装、BlackNode と同型)
- `HyDE/Configs/.local/lib/hyde/globalcontrol.sh` (shared library パターンで本軸の参考にはならず)

| 軸 | 決定 | sample 照合 | 一行根拠 |
|---|---|---|---|
| A. Esc | **A1 全閉じ** | powermenu 系 = A1 / wifi.sh は A3 だが再帰の副作用 | rofi 慣習。明示 Back item を別途用意 |
| B. アクション後 | **B3 種別ごと** | wifi.sh=B2 と powermenu=B1 の合成 | §2 メニューの性格差 (terminal vs toggle) を素直に反映 |
| C. 選択行保持 | **C2 `-selected-row`** | sample 全部 C1 (sample より UX 一段上) | B3 の継続側で連打 UX を確保。実装コストは許容 |
| ~~D~~ | **廃止** | §1.5 で構造的に解決 | 設定メニュー系と独立 keybind 系を分けたため場合分け不要 |
| E. 深さ | **E2 任意深さ** | wifi.sh = 3 階層 (main→scan→password) で実証済 | WiFi/Bluetooth が自然に 3 階層になる |
| F. 継続実装 | **F1 再帰呼び出し** (仮決定 F2 から変更) | wifi.sh = F1、F2 採用例なし | E2+A1 と組合せた時、break 伝播が要らない F1 が自然 |
| G. フィードバック | **G1 `notify-send` のみ** | wifi.sh = G1 ✓ | §0「状態は rofi 外」と整合、swaync と統合 |

##### F の補足 (仮決定 F2 → 最終 F1)

仮決定では F2 (while+break) としたが Step 3 で F1 (再帰) に変更:
- A1 (Esc=全閉じ) と E2 (任意深さ) を組合せると、F2 では 3 階層深い位置から「全閉じ」する際に break を 3 階層伝播させる必要が出る (グローバルフラグまたは例外的 exit)
- F1 (再帰) なら各層の rofi が空文字を返した時点で関数 return → 呼び出し元に戻る → 設定メニューまで自動的に遡って終了。**A1 が制御構造で無料実現**
- 当初 user が「バカ案」と評したのは旧 §1.4 の `loop+break + exec "$0"` の **組合せ**。F2 単独はその一部だが、prior art (wifi.sh) も F1 を採っており F2 に積極理由なし

#### 設計軸 (確定)

prior art (`hyprland-config-sample/BlackNode/Configs/.config/rofi/wifi/wifi.sh` と `powermenu/powermenu.sh`) の観察で対照的な 2 流儀が出たので、軸はその差分も含めて以下:

| 軸 | 説明 | 観測された実装例 |
|---|---|---|
| A. **Esc キーの意味** | 全閉じ / 戻る (Back と同義) / 文脈依存 (子では戻る、トップでは閉じる) | wifi.sh = 文脈依存 / powermenu.sh = 全閉じ |
| B. **アクション実行後の挙動** | 即閉じ / メニュー継続 / 種別ごとに使い分け | wifi.sh = 継続 / powermenu.sh = 即閉じ |
| C. **再表示時の選択行保持** | 毎回トップ / 直前行を再選択 (`-selected-row`) / 状態セクション先頭 | 両 sample = 毎回トップ |
| ~~D~~ (廃止) | — | §1.5 で構造的に解決、場合分け不要 |
| E. **サブメニュー内の最大階層** | 1 層 (リスト単発) / 2 層 (リスト + 入力 or 動作) | wifi.sh = 2 層 (list+password) / powermenu.sh = 2 層 (list+confirm)。3 層以上は不要 |
| F. **「継続」の実装手段** | 再帰呼び出し / `while` ループ / `exec "$0"` | wifi.sh = 再帰、当初の §1.4 旧案 = while ループ |
| G. **アクション結果のフィードバック** | `notify-send` のみ / メニュー再表示時の上部ステータス行 (`-mesg`) / 両併用 | wifi.sh = notify のみ / powermenu.sh = なし (確認ダイアログで代替) |

#### Step 2 — 軸ごとの選択肢と tradeoff

「spec ヒント」列は本仕様書の他セクション (§0, §1.1〜1.3, §1.5 など) に既に書かれている前提から各選択肢への含意を要約したもの。Step 3 (決定) でこれを判断材料に使う。

##### A. Esc キーの意味

| 選択肢 | 利点 | 欠点 | spec ヒント |
|---|---|---|---|
| A1. 全閉じ | 一般的な GUI 慣習と整合 (Esc=キャンセル)、実装最小 (空文字 → exit) | 階層が深い時に「上に戻る」つもりでも全部抜ける | §0 「rofi はワンショット」と整合 |
| A2. 戻る (Back と同義) | 階層感が出る、上下移動の挙動が一貫 | 一発で抜けたい時に Esc 連打が要る | — |
| A3. 文脈依存 (子=戻る / トップ=閉じる) | 直感的、両方の良いとこ取り | 実装に階層状態が要る (rofi 単発呼出しなので環境変数で受渡し) | §1.5 「直接呼び出し」も第一級なので階層状態の表現が要る |

##### B. アクション実行後の挙動

| 選択肢 | 利点 | 欠点 | spec ヒント |
|---|---|---|---|
| B1. 即閉じ | 単純、Hyprland keybind から呼んで 1 操作で完結 | 複数操作したい時 (settings の 2 つトグルしたい等) に何度も呼び直し | §0 「rofi はワンショット」、各 Walker 機能の置換も基本 1 操作で完結する性格 |
| B2. メニュー継続 (再表示) | トグル系・SSID 試行で連打しやすい | 終端アクション (poweroff 等) と相性悪い | §2.1.4 setting メニューはトグル多数 → B2 が自然 |
| B3. 種別ごとに使い分け | 文脈最適 (settings は継続、wallpaper 選択は即閉じ、等) | メニュー種別ごとにルール分け、判断基準の明文化が要る | §2 メニュー一覧の性質を見ると種別差は実在 |

##### C. 再表示時の選択行保持

| 選択肢 | 利点 | 欠点 | spec ヒント |
|---|---|---|---|
| C1. 毎回トップ | 最小実装、行数増減に強い | トグル系で「同じ行を連打したい」時に毎回スクロール | — |
| C2. 直前行を再選択 (`-selected-row N`) | トグル UX が自然、連打しやすい | 行番号管理 (項目が動的なら追跡困難) | §1.3 pull 方式で項目が変動しうる場合に脆い |
| C3. 状態セクション先頭 | 機能ごとに最適化可 | メニュー種別ごとに実装、複雑 | — |
| ※ 軸 B で B1 (即閉じ) を採るなら C は無関係 | | | |

##### ~~D. 直接呼び vs ハブ経由~~ (廃止)

§1.5 で「設定メニュー系」と「独立 keybind 系」を分け、同じスクリプトが両方の文脈で呼ばれない構造にしたため、場合分けが発生しない。tradeoff 比較は不要となった。

##### E. メニュー深さ

| 選択肢 | 利点 | 欠点 | spec ヒント |
|---|---|---|---|
| E1. 1 層のみ (サブメニュー単発リスト) | 設計シンプル | パスワード入力や動作選択ができない | Audio・Wallpaper サブはこれで十分 |
| E2. 2 層まで (リスト + 入力 or 動作) | 必要十分、深さに上限がある分簡素 | — | Network (SSID + password) / Bluetooth (機器 + 動作) はこれで足りる、3 層は不要 |

##### F. 「継続」の実装手段

| 選択肢 | 利点 | 欠点 | spec ヒント |
|---|---|---|---|
| F1. 再帰呼び出し (関数自身を再実行) | 直感的、関数間遷移が自然、wifi.sh の流儀 | 長時間運用でスタック消費 (実用上は問題ない) | — |
| F2. `while` ループ + break | スタック消費なし、線形 | break 制御が階層深いと読みにくい、設定メニューへの戻りが別途必要 | 検討したが採用せず |
| F3. `exec "$0"` (自プロセス置換) | 完全リセット、`. state.env` の再読込が暗黙に走る | 設定メニュー→子の文脈継承不可 (環境変数が消える)、起動コスト | §1.3 pull 方式と概念は親和、ただし F1 でも毎呼び出しで `. state.env` できるので必須ではない |

##### G. アクション結果のフィードバック

| 選択肢 | 利点 | 欠点 | spec ヒント |
|---|---|---|---|
| G1. `notify-send` のみ | swaync と統合、メニュー再表示時にきれい、wifi.sh の流儀 | 通知が消えると振り返り不可 | §0 「状態は rofi 外」と整合 |
| G2. メニュー上部ステータス行 (`-mesg`) | rofi 内で完結、振り返り可能 | rofi 閉じたら消える、長文表示しにくい | §0 「rofi はワンショット」とは少しズレ (rofi に状態保持させる) |
| G3. 両併用 (短文は -mesg、長文/エラーは notify) | 文脈に応じて使い分け | ルール明文化が要る | — |

#### Step 4 — 共通テンプレと呼び出しルール (完了)

##### 残課題への回答

| # | 課題 | 回答 |
|---|---|---|
| 1 | F1 と C2 の両立 | items 配列に保持した選択肢に対し、選ばれた choice の index を逆引きして再帰時に引数として渡す |
| 2 | B3 の判定基準 | アクション単位 (case の枝ごとに「再帰する=継続」「再帰しない=終端」を選択)。サブメニュー単位ではない |
| 3 | (廃止) | — |
| 4 | ← Back の挙動 | `exit 0` (スクリプト正常終了) |
| 5 | rofi exit code | 厳密には見ない。`choice` が空文字かどうかで判定 (空 = キャンセル相当) |

##### exit code 規約 (子サブメニュー → 設定メニュー間の通信)

| 子の終了状況 | exit code | 設定メニュー側の解釈 |
|---|---|---|
| ← Back 選択 | 0 | 1 段戻る → 設定メニュー再表示 |
| 終端アクション完了 | 0 | 1 段戻る → 設定メニュー再表示 |
| Esc / 空文字 | 1 | 全閉じ → 設定メニューも終了 |

A1 (Esc 全閉じ) は exit code の伝播で自然に実現される。Back と Esc が exit code で区別されるのが要点。

##### 構造の言葉での記述 (実装は別フェーズ)

7 軸の決定をまとめると、実装すべきものは以下:

- **サブメニュー側**: 1 関数 (`show_menu`) を再帰呼出しで継続表示。引数で「直前選択行 index」を受取り `-selected-row` に渡す。choice が空なら `exit 1` (全閉じ)、`← Back` なら `exit 0` (1 段戻る)、終端アクションは関数を抜ける、継続アクションは index を逆引きして再帰呼出し。
- **2 層目 (パスワード入力など)**: サブ関数として実装し、Esc 時は `return` のみで全閉じを伝播させない (中断 = 接続キャンセルだけ、メニュー全体は閉じない)。
- **設定メニュー側**: 子スクリプトを起動して exit code を見る。`0` なら自身を再帰再表示、`非0` なら自身も `exit 0` (全閉じ伝播の終点)。

実装作業は Step 4 完了後、§4 実装順序に従って進める。spec の役目はここまで。

旧案の参考実装 (採用しない):

```sh
submenu_settings() {
  while true; do
    choice=$(
      printf '%s\n' \
        "[$(hyprctl-state get WALLPAPER_NOTIFY)]  壁紙切替通知" \
        "[$(hyprctl-state get WALLPAPER_ROTATION)] ローテーション" \
        "← Back" \
      | rofi -dmenu -p "Settings" -theme dmenu.rasi
    )
    case "$choice" in
      *壁紙切替通知*)   hyprctl-state toggle WALLPAPER_NOTIFY ;;
      *ローテーション*) hyprctl-state toggle WALLPAPER_ROTATION ;;
      *Back*|"")       break ;;
    esac
  done
}
```

### 1.5 エントリポイント

メニューは 2 系統に分けて運用する。両者は交わらない (同じスクリプトが両方の文脈で呼ばれることはない)。

#### A. 設定メニュー系 (キーバインド 1 つで索引を開く)

`rofi-settings.sh` をキーバインド 1 つで起動 → 4 サブメニューに分岐:

- WiFi & Ethernet → `rofi-network.sh` (§2.1.2)
- Audio Select   → `rofi-audio.sh` (§2.1.3)
- BT Settings    → `rofi-bluetooth.sh` (§2.1.1)
- Wallpaper      → `rofi-wallpaper-settings.sh` (§2.1.4)

**配下の 4 サブメニューは設定メニュー経由でしか開かない**。それぞれに専用 keybind は割り当てない。

#### B. 独立 keybind 系 (高頻度メニューに専用キー)

設定メニューには含めず、それぞれ専用 keybind を持つ:

- 壁紙ピッカー       → `rofi-wallpaper.sh` (§2.2.1)
- アプリランチャー   → `rofi-launcher.sh` (§2.2.2)
- クリップボード     → `rofi-clipboard.sh` (§2.2.3)
- 絵文字ピッカー     → `rofi-emoji.sh` (§2.3.1)
- 顔文字ピッカー     → `rofi-kaomoji.sh` (§2.3.2)
- キーバインド早見表 → `rofi-keybinds.sh` (§2.3.3)
- スクショメニュー   → `rofi-screenshot.sh` (§2.3.4)

## 2. メニュー一覧

優先度: **P0** = 移行時に必須 / **P1** = 移行直後に追加 / **P2** = 余裕があれば

### 2.1 システム制御 (= 設定メニュー配下)

§1.5 の通り、本節の 4 サブメニューは **設定メニュー (`rofi-settings.sh`) からのみ開く**。各サブメニューに専用キーバインドは割り当てない。

> **バックエンド方針**: 既に動いているスタックの canonical CLI を直接叩く。GUI/TUI フロントエンドや代替スタックは介さない (§2.1.2 の nmcli 選定と同じロジック)。

#### 2.1.1 Bluetooth (`rofi-bluetooth.sh`) — P1
- 状態源: `bluetoothctl` (BlueZ 純正、追加依存なし、`echo … | bluetoothctl` で非対話実行可)
- アクション: power on/off / scan / pair / connect / disconnect / trust / forget
- 完了挙動: 個別操作後はメニュー継続、`Back` で閉じる

#### 2.1.2 ネットワーク (`rofi-network.sh`) — P1

GNOME `nm-applet` / KDE `plasma-nm` 流の統合メニュー。Wired / Wi-Fi / VPN を 1 メニュー内にセクション分けで並べる。WiFi 専用ではないため名前は **Network**。

- 状態源: `nmcli` (NetworkManager。`iwd` / `systemd-networkd` は使わない。NM と排他のため)
- 構成 (上から):
  1. **Wired** セクション: 接続中の interface を 1 行で表示 (`enp10s0  接続済み (192.168.x.x)` など)。ケーブル未接続なら `Wired: 未接続` と灰色相当の文言。アクション: 切断 / 再接続
  2. **Wi-Fi** セクション:
     - 1 行目: ラジオ on/off トグル (`[Wi-Fi: ON]` / `[Wi-Fi: OFF]`)
     - 以下スキャン結果の SSID 一覧 (signal 強度 / セキュリティ種別 / 接続済みマーク)
     - SSID 選択 → 既知接続ならそのまま up、未知なら `rofi -dmenu -password` でパスワード入力
  3. **VPN** セクション (任意): NM 登録済み VPN 接続の on/off
- アクション: scan refresh / connect / disconnect / forget / radio on/off / VPN toggle
- 完了挙動: 接続成功で閉じる。それ以外は §1.4 の戻り遷移パターン（再検討中）に従う
- 利点: 有線/無線の両方が nmcli で統一されているため、実装上の重複が出ない

#### 2.1.3 オーディオ機器切替 (`rofi-audio.sh`) — P1
- 状態源: `wpctl` (WirePlumber 純正、PipeWire ネイティブ。`pactl` は pulse 互換レイヤ経由で 1 段間接になるため不採用)
- アクション:
  - 出力デバイス（default sink）切替
  - 入力デバイス（default source）切替
- 完了挙動: 選択 → 切替 → 閉じる

#### 2.1.4 Wallpaper (`rofi-wallpaper-settings.sh`) — P0

設定メニュー配下の壁紙ローテーション + matugen テーマ生成のトグル。matugen は壁紙変更チェーンの一部なのでここに同居。

| 表示項目 | 状態キー | 型 | 編集 UI |
|---|---|---|---|
| 壁紙切替時の通知 | `WALLPAPER_NOTIFY` | bool | toggle |
| 壁紙ローテーション | `WALLPAPER_ROTATION` | bool | toggle |
| ローテーション間隔 | `WALLPAPER_INTERVAL_SEC` | int (秒) | プリセット循環: `300 / 900 / 1800 / 3600 / 10800` (5m/15m/30m/1h/3h) |
| matugen ソース color index | `MATUGEN_SOURCE_INDEX` | int (0 or 1) | toggle 0↔1 |
| matugen index ランダム | `MATUGEN_RANDOM_INDEX` | bool | toggle |

`MATUGEN_RANDOM_INDEX=true` の時は matugen ラッパ側で起動毎に 0 or 1 をランダム選択し、`MATUGEN_SOURCE_INDEX` を上書き保存（`set`）するか or 揮発で扱う。**未確定**: 永続させるかどうか。

表示例:
```
[ON]   壁紙切替時の通知
[OFF]  壁紙ローテーション
30m    ローテーション間隔
#0     matugen ソース color index
[OFF]  matugen index ランダム
← Back
```

### 2.2 コンテンツピッカー

#### 2.2.1 壁紙セレクタ（サムネ付） (`rofi-wallpaper.sh`) — P0
- 状態源: `~/pictures/wallpaper/`（直下、再帰なし。`fd --max-depth 1 -e jpg -e jpeg -e png -e webp`）
- 表示: rofi `-show-icons` + null-separator (`\0icon\x1f<path>`) でサムネ
- サムネ戦略:
  - **1 段階目**: 元画像を直渡し（rofi スケール任せ）
  - **2 段階目（必要なら）**: 事前生成キャッシュを導入。寸法・出力形式・キャッシュパスは **`wallpaper.rasi` の `element` / `element-icon` サイズが決まってから逆算** して決める（既存 wallselect.lua の 416x234 / `~/.cache/wallpaper-thumbs/` は出発点ではなく参考値として扱う）
  - 例: グリッド 4 列・要素幅 280px なら 320x180、5 列・220px なら 256x144、等。rasi 確定 → サムネ寸法決定 → 生成スクリプト実装、の順で進める
- レイアウト: grid（columns 4–5）
- 完了挙動: 選択 → `~/.config/hypr/scripts/wallpaper/apply.sh <path>` 実行 → matugen 連鎖は apply.sh 内で既に走る → 閉じる
- **wallselect.lua の置換先**

#### 2.2.2 アプリランチャ (`rofi-launcher.sh`) — P0
- mode: `drun`
- 仕事は `.rasi` テーマ整備に尽きる
- 既存 Super+R を流用

#### 2.2.3 クリップボード (`rofi-clipboard.sh`) — P1
- 状態源: `cliphist list`
- アクション: 選択でペースト（`cliphist decode | wl-copy`）、Shift+Enter（custom keybind）で削除、wipe オプション
- **新規依存**: `cliphist` を AUR から導入（`elephant-clipboard-bin` 撤去と同時）

### 2.3 追加候補メニュー

sample-dotfiles と現環境を見て、rofi 化の旨味があるもののみ列挙。

#### 2.3.1 絵文字ピッカー (`rofi-emoji.sh`) — P1
- 状態源: emoji データ（`rofimoji` パッケージか自前 JSON）
- アクション: 選択 → `wl-copy` → 通知（任意）
- 用途: 入力に IME を介さず絵文字を貼りたい場面
- **推奨度: 高**（sample-dotfiles の半数以上が実装、shell サンプルだとタブ統合）

#### 2.3.2 顔文字ピッカー (`rofi-kaomoji.sh`) — P2
- 状態源: kaomoji.json（自前用意）
- 動作は emoji と同じ
- **推奨度: 中**（日本語入力環境で稀に使う）

#### 2.3.3 キーバインド早見表 (`rofi-keybinds.sh`) — P1
- 状態源: `~/.config/hypr/keybinds.conf` をパース
- アクション: 選択しても何もしない（一覧閲覧のみ） or 選択でその dispatcher 実行
- 用途: 自分のキーバインドをすぐ思い出せる。Hyprland-Dots / dots-hyprland の cheatsheet 機能の rofi 版
- **推奨度: 高**（keybinds.conf は十分に大きい）

#### 2.3.4 スクリーンショットメニュー (`rofi-screenshot.sh`) — P2
- 現状: `Super+P` / `Super+Shift+P` / `Super+Ctrl+P` で hyprshot 直接バインド済み
- 追加価値: **遅延（3s/5s）** や **編集ツール（swappy/satty）への連携** を選びたい場合のみ
- **推奨度: 低**（直接バインドで足りているなら作らない）

### 2.4 作らないもの（明示）

| 機能 | 理由 |
|---|---|
| 電源メニュー | `wlogout` (Super+Q) で完結 |
| ロック画面 | hyprlock を別途使うので不要 |
| テーマ切替 | matugen + wallust が壁紙連動で全自動なので手動切替が要らない |
| 通知 DND トグル | swaync (Super+N) のパネル内に既にある |
| モニターモード切替 | `~/.config/hypr/scripts/mode.sh` を Super+Shift+D/B で直接呼んでる |

## 3. ファイル配置（chezmoi source）

`rofi-*.sh` 系スクリプトは `home/dot_config/rofi/scripts/` 配下に置く（rofi 関連を 1 ディレクトリにまとめる方針）。`hyprctl-state` (state.env アクセサ) は Hyprland 関連スクリプトとして `home/dot_config/hypr/scripts/` 配下に同居。

```
home/dot_config/rofi/
  config.rasi          # 共通設定 + 既定読込テーマ
  themes/
    common.rasi        # 色・フォント変数
    launcher.rasi      # アプリランチャ（grid）
    dmenu.rasi         # 縦リスト系サブメニュー共通
    wallpaper.rasi     # 壁紙picker (icon grid)
  scripts/
    executable_rofi-settings.sh             # 設定メニュー本体 (索引、キーバインド 1 つで起動)
    executable_rofi-network.sh              # 設定メニュー > WiFi & Ethernet サブ
    executable_rofi-audio.sh                # 設定メニュー > Audio Select サブ
    executable_rofi-bluetooth.sh            # 設定メニュー > BT Settings サブ
    executable_rofi-wallpaper-settings.sh   # 設定メニュー > Wallpaper サブ (壁紙/matugen トグル)
    executable_rofi-wallpaper.sh        # 独立 keybind 系
    executable_rofi-launcher.sh         # 〃
    executable_rofi-clipboard.sh        # 〃
    executable_rofi-emoji.sh            # 〃
    executable_rofi-keybinds.sh         # 〃
home/dot_config/hypr/scripts/
  executable_hyprctl-state              # state.env アクセサ (rofi/壁紙ローテータ等から呼ぶ)
home/dot_config/hypr/scripts/wallpaper/
  executable_thumb.sh                   # サムネ生成 (P0/P1 で必要なら)
```

**配置上の留意点**:
- `~/.config/rofi/scripts/` も `~/.config/hypr/scripts/` もデフォルトでは `$PATH` に居ない
  - Hyprland keybind から呼ぶときは絶対パス (`~/.config/rofi/scripts/rofi-launcher.sh`) になる
  - rofi スクリプトから `hyprctl-state` を呼ぶときも絶対パス (`~/.config/hypr/scripts/hyprctl-state get KEY`) になる
- 短縮したい場合は (a) シェル環境で PATH に加える、(b) shell 関数として alias、等の追加策が要る

## 4. 実装順序

1. **共通基盤** — `state.env` 仕様 + `hyprctl-state` 実装 + `dmenu.rasi`
2. **アプリランチャ** (`rofi-launcher.sh` + `launcher.rasi`) — Walker 置換の最重要
3. **Wallpaper サブ** (`rofi-wallpaper-settings.sh`) — state.env を駆動する初の機能
4. **壁紙セレクタ** (`rofi-wallpaper.sh` + `wallpaper.rasi` + サムネ生成) — wallselect.lua 置換
5. **オーディオ切替** (`rofi-audio.sh`)
6. **クリップボード** (`rofi-clipboard.sh`) — cliphist 導入と同時
7. **Network** (`rofi-network.sh`) — nmcli ベース統合メニュー (Wired+Wi-Fi+VPN)
8. **Bluetooth** (`rofi-bluetooth.sh`) — bluetoothctl ベース
9. **絵文字 / キーバインド早見表** — P1 系
10. **設定メニュー本体** (`rofi-settings.sh`) — 4 サブメニューが揃った後に索引を書く
11. **Walker 撤去** — keybind 切替 → AUR パッケージ削除 → 設定ディレクトリ削除

## 5. 解決済み / 未確定

### 解決済み
- ✅ 状態形式: shell env
- ✅ 反映方式: pull (毎回 source)
- ✅ ローテーション間隔: プリセット循環（300/900/1800/3600/10800）
- ✅ matugen color index: 0 or 1（toggle）
- ✅ 壁紙ディレクトリ: `~/pictures/wallpaper`
- ✅ 電源系: wlogout 任せ
- ✅ state.env 初期化: 遅延（`get` で fallback、`set` で作成）
- ✅ ファイル配置: rofi-*.sh は `home/dot_config/rofi/scripts/` 配下
- ✅ ネットワーク: GNOME 流統合 (`rofi-network.sh`、nmcli ベース、Wired+Wi-Fi+VPN を 1 メニュー)
- ✅ Bluetooth バックエンド: `bluetoothctl` 直叩き
- ✅ Audio バックエンド: `wpctl` 直叩き
- ✅ システム制御の選定方針: スタックの canonical CLI を直接叩く (フロントエンド層を入れない)
- ✅ メニュー構造: 「設定メニュー系 (4 サブメニュー、索引から分岐)」と「独立 keybind 系 (高頻度メニュー)」の 2 系統に分離。同一スクリプトが両文脈で呼ばれることはない
- ✅ 設定メニュー本体スクリプト名: `rofi-settings.sh` (索引)。配下の Wallpaper サブは `rofi-wallpaper-settings.sh` (matugen も含む)
- ✅ `hyprctl-state` 配置: `~/.config/hypr/scripts/hyprctl-state` (Hyprland 関連スクリプト群と同居)
- ✅ 戻り遷移パターン (§1.4): 7 軸決定済 (A1/B3/C2/E2/F1/G1、D 廃止)、共通テンプレと exit code 規約まで合成完了

### 未確定
- [ ] `MATUGEN_RANDOM_INDEX=true` 時、選んだ index を永続化するか揮発で扱うか
- [ ] cliphist 導入を本作業に含めるか別タスクに切るか
- [ ] サムネ生成は P0 でいきなりやるか、まず元画像直渡しで様子見するか

## 6. 拡張ガイド

新しい設定項目・新しいサブメニュー・新しい独立メニューを後から足したくなった時の手順。本仕様の構造はこれら 3 ケースで触る場所を最小化するように設計されている。

### 6.1 既存サブメニューに新トグル/項目を追加 (例: `Wallpaper` に新項目)

触る場所: **2 箇所** (該当サブメニューのスクリプトと state.env デフォルト)

1. `rofi-<sub>-settings.sh` 内の items 配列に 1 行追加 + 対応する case ブランチ追加 + 状態キーの参照
2. (新キーを使うなら) `hyprctl-state` のデフォルト値テーブルに 1 行追加 — ファイル `state.env` 自体は遅延初期化なので明示更新は不要 (§1.2)

新キーを参照する側 (壁紙ローテータ等) は §1.3 の通り pull 方式 (`. state.env` 都度 source) なのでコード変更が要らないケースが多い。

### 6.2 設定メニューに新カテゴリのサブメニューを追加 (例: `Display` を追加)

触る場所: **3 箇所**

1. `home/dot_config/rofi/scripts/executable_rofi-display.sh` を新規作成 (定型関数テンプレを呼ぶだけ。中身は既存 `rofi-network.sh` 等を雛形にする)
2. `rofi-settings.sh` (索引) の items 配列に 1 行追加:
   ```sh
   items=(
     "WiFi & Ethernet|rofi-network.sh"
     "Audio Select|rofi-audio.sh"
     "BT Settings|rofi-bluetooth.sh"
     "Wallpaper|rofi-wallpaper-settings.sh"
     "Display|rofi-display.sh"            # ← 追加
   )
   ```
3. (state を使うなら) §6.1 と同様に状態キーのデフォルト追加

### 6.3 独立 keybind メニューを追加 (例: `Power` を独立呼出しで)

触る場所: **2 箇所**

1. `home/dot_config/rofi/scripts/executable_rofi-power.sh` を新規作成
2. `home/dot_config/hypr/keybinds.conf` に keybind を追加 (例: `bind = $mainMod, X, exec, ~/.config/rofi/scripts/rofi-power.sh`)

設定メニュー側には触らない (§1.5 の通り 2 系統が交わらない)。

### 6.4 拡張容易性を支える既存設計の鍵

| 鍵 | 由来 | 効果 |
|---|---|---|
| 各サブメニューが独立スクリプト | §3 ファイル配置 | 1 サブメニュー = 1 ファイル、改変の影響が局所化 |
| 索引は薄い dispatcher (items 配列) | §1.5 + §6.2 | カテゴリ追加 = 1 行追記 |
| state は shell env、`get` 遅延 fallback | §1.1〜1.2 | スキーマ拡張がほぼ自由 (型 / キー名 / デフォルトの追加が低コスト) |
| consumer 側は pull 方式 | §1.3 | 新キー追加で消費側のシグナル/再起動連鎖が要らない |
| 戻り遷移は共通テンプレ関数 | §1.4 Step 4 (予定) | サブメニュー追加時のボイラープレート最小化 |
