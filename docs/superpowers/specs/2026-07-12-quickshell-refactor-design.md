# quickshell 大規模リファクタリング設計

日付: 2026-07-12
状態: ユーザーレビュー待ち

## 背景と現状分析

quickshell 設定は `home-manager/desktop/quickshell/` 配下に 3 つの独立した設定（`shell/`, `audio/`, `bluetooth/`）として置かれ、QML 合計は約 23,000 行ある。
調査の結果、行数の大半が重複と死蔵で占められていることがわかった。

- **3 重コピー**：`audio/` と `bluetooth/` は `shell/` の services と config をほぼ丸ごと複製した別設定（各 23 ファイル、約 3,000 行）で、固有部分はポップアップウィンドウ 1 ファイルと起動用 QML の数行だけである。waybar のクリックごとに `qs -c audio -n` で別プロセスを起動し、閉じると終了する方式のため、この複製が必要になっていた。
- **死蔵コード**：`shell/shell.qml` が読み込むのは通知サーバとコントロールセンターだけであり、`modules/bar`（バー本体）, `sidebar`, `dashboard`, `osd` の約 7,900 行は読み込まれていない。バーの実体は waybar である。
- **トークン体系の形骸化**：`AppearanceConfig.qml` に寸法トークンが定義されているが、実際の参照は 2 箇所しかない。一方で modules 内には radius や spacing の生数値指定が 400 箇所以上ある。さらに `rounding`（small/medium/large）と `radius`（xs/s/m/l/xl）の二重体系、`font` と `typography` の二重体系が併存する。
- **命名の残骸**：色サービスは matugen の生成物（`~/.cache/quickshell/matugen-colors.json`）を読んでいるにもかかわらず `Pywal.qml` という名前で、shell.json のキーも `pywalColors` である。pywal 由来の `color0..15` と `glass*` 互換エイリアスも残る。wallust への参照は既に存在せず、matugen 連動はデータ面では完成している。残っているのは命名と残骸の一掃である。

## 決定事項

ユーザーとの合意事項を列挙する。

- `audio/` と `bluetooth/` は `shell/` へ完全統合して削除する。
- 休眠モジュール（バー本体, sidebar, dashboard, osd, BatteryMonitor と、そこからしか使われない services）は削除する。git 履歴から復元できる。
- 進め方は生存コードだけを新ツリーへ移植する方式（ビッグバン）とする。死蔵 60% の発見により移植対象は約 7,000 行まで縮み、一括移植のリスクが当初想定より小さいと判断した。
- ディレクトリ構造は caelestia-dots/shell の QML 層に倣う。同プロジェクトの C++ プラグイン化（設定層の Qt plugin 化）は、個人 dotfiles にはビルドチェーンの保守コストが見合わないため採用しない。
- 寸法と余白は全面トークン化する。体系は 1 本に統一する。
- 色サービスは `Colours.qml` に改名する（caelestia と同名。供給元 matugen に依存しない命名のため、将来供給元を変えても名前が腐らない）。
- スクリーンショットはシェルスクリプト（`hyprland/scripts/screenshot.sh`, `record.sh`）を正とし、quickshell 側の自前撮影ロジックを削除する。
- 空リスト時にポップアップの幅と高さが潰れる問題の修正を含める。
- ポップアップの config ボタンの空メニュー解消は対象外（別途仕様作成が必要なため）。

## 到達ソースツリー

```
quickshell/
├── default.nix               # shell のみ配線（audio, bluetooth を削除）
├── shell.json
└── shell/
    ├── shell.qml             # 通知サーバ + コントロールセンター + ポップアウト + IPC 配線
    ├── config/
    │   ├── Config.qml        # shell.json 読込。死蔵セクション削除
    │   ├── Appearance.qml    # 寸法トークン（単一体系）
    │   └── Theme.qml         # 意味色トークン（UI が色を参照する唯一の点）
    ├── utils/
    │   └── Logger.qml        # 純粋ヘルパーを services から分離
    ├── services/             # システム状態シングルトンのみ（21 個から約 13 個へ。最終リストは移植時の参照解析で確定）
    │   ├── Colours.qml       # 旧 Pywal。matugen JSON 読込
    │   ├── Audio.qml  AudioStreams.qml  Bluetooth.qml  Brightness.qml
    │   ├── Network.qml  Notifs.qml  Players.qml  PowerProfiles.qml
    │   ├── IdleInhibitor.qml  SystemUsage.qml  Time.qml
    │   └── Screenshot.qml    # スクリプト呼び出しへ縮小
    ├── components/           # 生存部品のみ、用途別サブ分類
    │   ├── controls/         # IconButton, PopupButton, StateLayer など
    │   ├── containers/       # Material3Popup, StyledFlickable, StyledListView など
    │   └── effects/          # RippleEffect, Elevation, Anim など
    └── modules/
        ├── notifications/    # 通知トースト（旧 bar/components/NotificationPopups）
        ├── controlcenter/
        │   ├── ControlCenterWindow.qml
        │   ├── sections/     # Media, Performance, Notifications, Settings
        │   └── components/   # QuickToggle, VolumeSlider など
        └── popouts/          # waybar から IPC で開閉（旧 audio, bluetooth 別設定）
            ├── AudioPopout.qml
            └── BluetoothPopout.qml
```

移植しないもの：`modules/{bar 本体, sidebar, dashboard, osd}`, `BatteryMonitor`, 死蔵 services（LauncherUsage, GamingMode, UIState など。生存モジュールから参照されないことを移植時に確認して確定する）, 未使用 components。

## デザイントークン体系

waybar の `style.nix` と同じ思想（セマンティックトークンが単一情報源）を QML で実現する。
トークンは 3 層に分け、参照方向を一方通行にする。

```
matugen JSON → services/Colours.qml → config/Theme.qml → modules / components
   (生成物)      (プリミティブ色)       (意味色トークン)     (色は Theme だけを見る)

config/Appearance.qml → modules / components
  (寸法, タイポ, アニメ)   (数値は Appearance だけを見る)
```

### 寸法トークン（config/Appearance.qml）

現 `AppearanceConfig.qml` を再編して一本化する。サイズ語彙は xs/s/m/l/xl/full に全面統一する。

- **radius**：xs 6 / s 10 / m 16 / l 22 / xl 32 / full 9999。現 `radius` 系を正とし、`rounding` は廃止する。
- **spacing**：xs 4 / s 8 / m 12 / l 16 / xl 24。現 tiny→xs, huge→xl に改名する。
- **padding, margin**：同様に xs から xl。
- **typography**：Material 3 スケール（display から label まで、現行維持）。`font`（small/medium/large）は typography と二重のため廃止し、フォントファミリは shell.json 由来（Config）に一本化する。
- **anim**：durations（fast/normal ほか）と M3 curves を維持する。`easing` 群は利用実態を実装時に確認し、未使用なら削除する。
- **alpha**：現 `transparency` を改名する。ポップアップに散在する生 alpha（hover 0.06, border 0.08 など）もここへ収容する。

### 参照規律

- modules と components が参照してよいのは Theme（色）と Appearance（寸法）だけとする。`Colours` の直参照、生数値、生 alpha は禁止する。
- 現行ポップアップがローカルに持つ色定数定義（`cSurface`, `cHover` など）は全廃し、Theme トークンに置換する。
- モジュール固有で 1 回しか使わない寸法（通知ポップアップ幅 340 など）は、そのファイル冒頭の named property にまとめる。トークンから導出できる値はトークン参照にする。

### 色レイヤ

- **services/Colours.qml**：matugen JSON の読込と Material 3 パレットの公開のみを担う。`color0..15`, `colors` マップ, `glass*` 互換エイリアスを削除する。`on*` 系の readonly 派生と、JSON 不在時のハードコード既定値へのフォールバック（warn ログ付き）は現行方針を維持する。matugen の atomic 書込で FileView 監視が外れるため post_hook からの明示リロードを維持する点も変えない。
- **config/Theme.qml**：意味色トークン層として存続する。全 UI はここだけを参照する。
- **shell.json**：`paths.pywalColors` キーを `paths.colours` に改名する。

### Config（shell.json）の役割整理

shell.json は環境依存のランタイム設定だけを持つ：paths, notifications の挙動, フォントファミリ。
寸法と色はコード（Appearance, Theme）側に置き、ブランド数値をユーザー設定にしない。
Config.qml から死蔵セクション（launcher, sidebar, dashboard, osd）を削除する。
`paths.screenshotsDir` は撮影ロジックのスクリプト移管に伴い削除する（保存先の真実はスクリプト側）。

## ポップアウト統合

`modules/popouts/` に `AudioPopout.qml` と `BluetoothPopout.qml` を置く。
UI は現行の PanelWindow 実装を移植しつつ、ローカル色定数を Theme に、生数値を Appearance に置換して作り直す。

- **常駐化**：現行はクリックごとに別プロセスを起動し閉じると終了する方式（起動ラグあり、トグル不可）だった。統合後は常駐 shell プロセス内のモジュールとなり、即時表示と再クリックでのトグル閉じになる。
- **IPC**：`qs -c shell ipc call audio toggle` と `qs -c shell ipc call bluetooth toggle` を新設する。
- **排他制御**：一度に開けるパネルは 1 つとする。audio を開くと bluetooth とコントロールセンターは閉じる。現行は別プロセスのため同時表示できてしまい、重なりが起きていた。
- **空リスト時の幅崩れ修正**：現行はリスト内容から implicit に幅と高さを導出しているため 0 件で潰れる。ポップアウト幅はトークン由来の固定値にし、リストが空のときは「デバイスが見つかりません」の empty-state 行（最小高さ付き）を表示する。Bluetooth はスキャン中インジケータも空状態に含める。

## Screenshot サービスの縮小

grim, slurp, wf-recorder を自前実行する現行の 232 行を捨て、`~/.config/hypr/scripts/screenshot.sh <mode>` と `record.sh` を `Process` で呼ぶだけの薄いサービスにする。
保存先ディレクトリ作成、ウィンドウクラス別フォルダ、通知はスクリプト側の既存実装に一本化される。
これによりキーバインド、rofi メニュー、quickshell の 3 経路が同一実装を通る。
コントロールセンターの撮影と録画ボタンの見た目と操作は変えない。

## 外部配線の変更

quickshell 外で変更するのは 3 ファイルである。

| ファイル                    | 変更                                                                                              |
| --------------------------- | ------------------------------------------------------------------------------------------------- |
| `waybar/modules.nix`        | `on-click = "qs -c bluetooth -n"` を `"qs -c shell ipc call bluetooth toggle"` に（audio も同様） |
| `matugen/config.toml`       | post_hook の `for c in shell audio bluetooth` ループを `qs -c shell ipc call theme reload` 単発に |
| `hyprland/lua/keybinds.lua` | 変更なし（既に `qs -c shell` 経由）                                                               |

`default.nix` は `xdg.configFile` から audio と bluetooth の配線を削除する。systemd ユニット（`qs -c shell` 常駐）は変更しない。

## エラー処理

- matugen JSON が無い、または壊れている場合：Colours.qml のハードコード既定値で起動し、warn ログを出す（現行と同じ方針）。
- スクリプト不在の環境：quickshell 自体が desktop レイヤに属し、WSL など desktop を import しない環境では動かないため考慮しない。

## 検証

各実装ステップで次を行う。

1. `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。
2. `nix run .#switch` 後に `systemctl --user restart quickshell` を実行し、`journalctl --user -u quickshell` で QML warning がないことを確認する。
3. 実機目視：通知トースト、Super+N のコントロールセンター、waybar からの audio と bluetooth ポップアウト（0 件状態を含む）、壁紙変更での色追従、コントロールセンターからのスクリーンショット。

## スコープ外

- ポップアウトの config ボタンのクリックメニュー実装（別途仕様作成）。
- BlackNode 風のスクリーンショット範囲選択 UI（todo.md の別項目。スクリプトを正とする今回の統合はこの将来機能と矛盾しない。UI 側で範囲を選び、確定した geometry をスクリプトに渡す形で拡張できる）。
- quickshell 製バーへの waybar 置換。
