# waybar リファクタ設計

日付: 2026-07-05
対象: `home-manager/desktop/waybar/`（一部 `home-manager/desktop/hyprland/` に波及）

## 背景と目的

現状の waybar には三つの問題がある。

- 見た目: 色のベタ塗り感が強く、カプセルの境界が壁紙に溶けて見えない。todo.md には「リキッドグラス風にしたい」「壁紙から浮いている感を出したい」とある。
- 操作: モジュールごとにクリックアクションを割り当てすぎており、quickshell のコントロールセンターと役割が重複している。
- コード: `config.json` 1 ファイルに約 260 行の全モジュール定義が入っている。`styles/` に 7 種のスタイル CSS が並ぶが、常用は 1 種で、直したバグが他スタイルに波及しない状態になっている。

このリファクタで、見た目を一新し、クリックを 4 箇所に集約し、スタイル切替の仕組みを廃止して単一構成へ収束させる。

## 決定事項の要約

ブラウザ上のモックアップ比較で以下を決定した。

- バーの形: 島型（アイランド）レイアウトを維持する。
- 質感: **ダークグラス**（濃いめの暗色ティント + すりガラス）。候補だったライトグラス、シャドウグラス、リムグラスは、明るい壁紙で境界か文字が破綻するため不採用。
- アクセント色: matugen による壁紙由来の動的アクセントを継続する。
- クリック方針: **入口集約型**。バーは表示が主で、詳細操作は quickshell のコントロールセンターに寄せる。
- コード構造: `config.json` を廃止し、settings を Nix で記述して分割する。

## バー構成

| 位置 | 島 | 中身 |
| --- | --- | --- |
| 左 | nix, mise, connectivity 島, window 島 | ランチャー起動, mise 更新チェッカー, bluetooth + network, ウィンドウタイトル |
| 中央 | ws 島, datetime 島 | ワークスペースのみ, 時刻 + 日付 + 天気 |
| 右 | sysstats 島, systray 島, power | cpu + 温度 + メモリ（drawer 維持）, 音量 + privacy + 通知 + tray, 電源 |

現行からの変更点は次のとおり。

- weather を nav 島（ワークスペースとセット）から datetime 島へ移す。ワークスペースは単独島になる。参照した他リポジトリ（BlackNode, HyDE）では天気は時計の近くに置くのが定番で、ワークスペースとセットにする例はなかった。
- 右サイドを「モニタリング（sysstats）」と「インジケータ（systray）」の 2 島に分ける。旧 control 島は性質の違うものが 1 島に同居していた。
- **privacy** モジュール（マイクと画面共有の使用中インジケータ）を systray 島に追加する。waybar 組み込みで、使用中のみアイコンが現れる。
- `custom/idle_inhibitor` を削除する。表示のためだけに 2 秒間隔で `qs` をポーリングしており、トグル操作はコントロールセンター側で足りる。
- `custom/separator` を削除する。島の分割が視覚的な区切りを兼ねる。
- mpris, cava, wlr/taskbar は検討のうえ見送り。

## クリックアクション

残すのは次の 4 つだけとする。

| モジュール | アクション |
| --- | --- |
| custom/nix | ランチャー起動（quickshell） |
| hyprland/workspaces | クリックで移動 |
| custom/swaync | コントロールセンター開閉 |
| custom/power | wlogout |

上記以外のポインタ操作（mise のクリックアップグレード, bluetooth と pulseaudio の quickshell ポップアップ, 音量スクロール, ミュートクリック, swaync 右クリックの DND）はすべて廃止する。
詳細操作の入口をコントロールセンターに一本化するためである。

## 見た目の仕様

島の質感は次で統一する。

- ティント: `rgba(10, 12, 18, 0.58)` 相当の暗色半透明。
- 縁取り: 1px の `rgba(255, 255, 255, 0.08)`。
- 影: 控えめなドロップシャドウ。
- ブラー: **Hyprland 側の layerrule**（`layerrule = blur, waybar` と `ignorealpha`）で実現する。waybar の GTK CSS 単体では背面ブラーを表現できないため、`home-manager/desktop/hyprland/` に設定が 1 行入る。

色は matugen 生成の Material Design 3 トークン（`@primary`, `@error` など）を使う。
アクティブなワークスペース、アイコンの効き色、警告状態に `@primary` 系を割り当てる。
ワークスペースの形状（非アクティブは小ドット、アクティブは横長ピル）は現行 capsule-nobg のものを踏襲する。
tooltip も同じガラストークンで揃える。

wallust（`colors-waybar.css`, `@color0..15`）への依存は削除する。
`@color` 系変数を使っていたのは削除対象の 2 スタイルだけで、残す構成では参照がない。

## コード構造

```
home-manager/desktop/waybar/
├── default.nix          # programs.waybar 配線 + xdg リンクのみ
├── settings/
│   ├── bar.nix          # レイアウト, 島（group）定義, margin
│   └── modules.nix      # 各モジュール定義
├── style.css            # 決定版 1 本
└── scripts/             # weather, pkg-update（現状のまま同居）
```

- `config.json`, `styles/`（7 ファイル）, `FAVORITES.md` を削除する。スタイル探索の記録は git 履歴に残る。
- username は Nix の引数として直接埋め込む。現行 `default.nix` の「JSON 読み込み後に format へ username を連結するハック」は消える。
- `style.css` は次のセクション構造で書く: 色トークン, リセット, 島の基礎, モジュール, 状態, tooltip。スタイルを 1 本に収束させたため、ファイル分割はしない。

## 初回起動フォールバック

todo.md にある「初回起動時に `colors.css` が存在せず waybar が起動できない」問題をスコープに含める。
home-manager activation で、`colors.css` が存在しない場合のみ、matugen 生成物と同じ `@define-color` 名を持つ固定色ファイルを生成する。
wallust 依存の削除とあわせて、色ファイル不在で waybar が落ちる要因はなくなる。

## スコープ外

- quickshell 側の変更（コントロールセンターの機能追加など）。バーから操作を寄せる先はすべて既存機能とする。
- 壁紙関連スクリプトや matugen の生成フロー自体の変更。
- `hyprland/scripts/waybar/reload-css.sh` の扱いは実装計画時に確認する（matugen の壁紙切替から呼ばれている可能性があるため、削除はこの確認後に判断する）。

## 検証

1. `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。
2. 実機で `nix run .#switch` 後、明るい壁紙と暗い壁紙の両方で境界の見え方とブラーの効きを目視確認する。
3. クリック 4 箇所（ランチャー, ワークスペース移動, コントロールセンター, wlogout）の動作を確認する。
4. 確認が済んでから push する（main 直 push は CI フルビルドが走るため、ローカル検証を先に行う運用に従う）。
