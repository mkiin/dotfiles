# waybar リファクタ設計

日付: 2026-07-05（島構造の全面見直しで同日改訂）
対象: `home-manager/desktop/waybar/`（一部 `home-manager/desktop/hyprland/` に波及）

## 背景と目的

現状の waybar には三つの問題がある。

- 見た目: 色のベタ塗り感が強く、カプセルの境界が壁紙に溶けて見えない。todo.md には「リキッドグラス風にしたい」「壁紙から浮いている感を出したい」とある。
- 構造: 島（グループ）の粒度が場当たり的で、CSS も「group には `.cluster` クラス、単独モジュールには ID 列挙」という二重機構になっている。
- コード: `config.json` 1 ファイルに約 260 行の全モジュール定義が入っている。`styles/` に 7 種のスタイル CSS が並ぶが、常用は 1 種で、直したバグが他スタイルに波及しない状態になっている。

このリファクタで、見た目を一新し、島の粒度を主要 OS の UI に倣って組み直し、スタイル切替の仕組みを廃止して単一構成へ収束させる。

## 決定事項の要約

ブラウザ上のモックアップ比較と対話で以下を決定した。

- バーの形: 島型（アイランド）レイアウトを維持する。
- 質感: **ダークグラス**（濃いめの暗色ティント + すりガラス）。候補だったライトグラス、シャドウグラス、リムグラスは、明るい壁紙で境界か文字が破綻するため不採用。
- アクセント色: matugen による壁紙由来の動的アクセントを継続する。
- 島の粒度: 主要 OS（GNOME, Windows 11, macOS）のステータスバー構造に倣う。通信、音量、電源などのインジケータは 1 つの塊にまとめ、細かいペア分割（bluetooth + network だけの島など）はしない。
- クリック: 個別ポップアップを持つモジュール（bluetooth, 音量）はそれを開き、全部入りの操作はコントロールセンターに寄せる。コントロールセンターの入口は「idle_inhibitor + 通知ベル + 電源」の専用島とし、島のどこをクリックしても開く。wlogout への導線はバーから消える（電源操作はコントロールセンター側にあるため）。
- 命名: swaync は使っていない（通知の実体は quickshell）ため、モジュール名を `custom/swaync` から `custom/control-center` に改める。
- コード構造: `config.json` を廃止し、settings を Nix で記述して分割する。

## 島構造の設計原則

主要 OS のステータスバーを調べた結果に基づく。

- GNOME はトップバーを「左 = Activities、中央 = 時計 + 通知、右 = システムステータス 1 ピル（network, bluetooth, 音量, 電源が 1 塊）」の 3 ゾーンで構成する。
- Windows 11 はタスクバー右端で「tray アイコン群」「network + 音量の結合ボタン」「時計 + 通知ベル」に分ける。
- どちらも、電波の種類ごと（wifi と bluetooth など）に塊を分けることはしない。

これに倣い、次の原則を置く。

- **バーに直接載る要素は原則 group とし、group 名はすべて `group/<名前>#island` 形式にする**。`#island` サフィックスが CSS の `.island` クラスになり、島の質感を 1 セレクタで描ける。
- 「島全体が 1 つのボタン」の島（launcher, control-center）を作れる。group の on-click は waybar に無いが、島内の全モジュールに同一の on-click を与えれば、島のどこをクリックしても同じ動作になる。
- 例外は `hyprland/window` のみ。group で包むとタイトルが空のときに空のガラス枠が残るため、裸モジュールのまま `#window` に島と同じ質感を当てる（waybar の `.empty` クラスで丸ごと消せるのはモジュール自身が背景を持つ場合だけ）。

## バー構成

| 位置 | 島                 | 中身                                                       | OS の類型                               |
| ---- | ------------------ | ---------------------------------------------------------- | --------------------------------------- |
| 左   | launcher 島        | nix（ランチャー）                                          | Start ボタン, Activities                |
| 左   | window（裸・例外） | ウィンドウタイトル                                         | macOS のアプリメニュー位置              |
| 中央 | workspaces 島      | ワークスペース                                             | GNOME の中央志向                        |
| 中央 | datetime 島        | 時刻 + 日付 + 天気                                         | 時計まわりの定番                        |
| 右   | sysstats 島        | cpu + 温度 + メモリ（drawer 維持）                         | OS には無い rice 要素。監視系として独立 |
| 右   | status 島          | network + bluetooth + 音量 + privacy + tray                | GNOME のシステムステータス 1 ピル       |
| 右   | control-center 島  | idle_inhibitor + 通知ベル + 電源（島全体が CC を開く入口） | Win11 のクイック設定ボタン              |

現行からの変更点は次のとおり。

- `custom/mise`（更新チェッカー）をモジュールごと削除する。`scripts/pkg-update/` も使用者がいなくなるため削除する。
- weather を nav 島（ワークスペースとセット）から datetime 島へ移す。
- connectivity 島（bluetooth + network のペア）は解体し、両者は status 島へ入れる。
- **privacy** モジュール（マイクと画面共有の使用中インジケータ）を status 島に追加する。waybar 組み込みで、使用中のみアイコンが現れる。
- 通知ベルを `custom/swaync` から `custom/control-center` に改名し、idle_inhibitor と電源を合わせた control-center 島として status 島の右隣に置く。3 モジュールに同一の on-click を与え、島全体がコントロールセンターを開くボタンになる。
- `custom/idle_inhibitor` は表示を残して control-center 島へ移す。単体クリックでのトグルは廃止し（トグルはコントロールセンター側にある）、クリックは島共通の CC 開閉に変える。
- `custom/separator` を削除する。島の分割が視覚的な区切りを兼ねる。
- mpris, cava, wlr/taskbar は検討のうえ見送り。

## クリックアクション

| モジュール                                                   | アクション                                                                   |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| custom/nix                                                   | ランチャー起動（quickshell）                                                 |
| hyprland/workspaces                                          | クリックで移動                                                               |
| bluetooth                                                    | bluetooth ポップアップ（quickshell）                                         |
| pulseaudio                                                   | オーディオセレクタ（quickshell）                                             |
| custom/idle_inhibitor + custom/control-center + custom/power | コントロールセンター開閉（3 つとも同一 on-click で、島のどこを押しても開く） |

上記以外のポインタ操作は持たない。
wlogout への導線はバーから消える（電源操作はコントロールセンターにある）。
音量スクロール、ミュートクリック、通知ベル右クリックの DND、idle_inhibitor 単体のトグル、mise のクリックアップグレードは廃止する。

## 見た目の仕様

島の質感は次で統一する。

- ティント: `rgba(10, 12, 18, 0.58)` 相当の暗色半透明。
- 縁取り: 1px の `rgba(255, 255, 255, 0.08)`。
- 影: 控えめなドロップシャドウ。
- ブラー: **Hyprland 側の layerrule**（`layerrule = blur, waybar` と `ignorealpha`）で実現する。waybar の GTK CSS 単体では背面ブラーを表現できないため、`home-manager/desktop/hyprland/` に設定が入る。

色は matugen 生成の Material Design 3 トークン（`@primary`, `@error` など）を使う。
アクティブなワークスペース、アイコンの効き色、警告状態に `@primary` 系を割り当てる。
ワークスペースの形状（非アクティブは小ドット、アクティブは横長ピル）は現行 capsule-nobg のものを踏襲する。
tooltip も同系のトークンで揃えるが、blur が乗らない別サーフェスのためティントは濃くする。

wallust（`colors-waybar.css`, `@color0..15`）への依存は削除する。
`@color` 系変数を使っていたのは削除対象の 2 スタイルだけで、残す構成では参照がない。

## CSS の構造

セレクタの機構は次の 3 層だけとする。

1. `.island` … 島の質感（ティント, 縁取り, 影, 角丸）。全 group + 例外の `#window` に当てる。
2. `.island > *` … 島内モジュールの背景リセット。個別 ID の列挙はしない。
3. 状態セレクタ（`#workspaces button.active`, `#pulseaudio.muted` など） … 効き色と状態だけを ID で指定。

寸法と質感の値はセマンティックトークンで一元管理する。
GTK CSS には寸法用の変数機構が無いため、Nix をプリプロセッサにする: `style/tokens.nix`（トークン定義）+ `style/mk-style.nix`（CSS テンプレート）から `style/render.sh` が `style.css` を生成し、生成物をコミットする。
生成物は従来どおり `lnk` で実機に届くため、再生成すれば waybar の `reload_style_on_change` で即反映される。
`style.css` の手編集と、個別ルールへの場当たりな寸法調整は禁止（プロジェクト CLAUDE.md に明記）。

## コード構造

```
home-manager/desktop/waybar/
├── default.nix          # programs.waybar 配線 + xdg リンクのみ
├── settings/
│   ├── bar.nix          # レイアウト, 島（group）定義, margin
│   └── modules.nix      # 各モジュール定義
├── style/
│   ├── tokens.nix       # 寸法・質感のセマンティックトークン（単一情報源）
│   ├── mk-style.nix     # tokens → CSS 文字列のテンプレート
│   └── render.sh        # style.css を再生成
├── style.css            # 生成物（手編集禁止）
└── scripts/             # weather のみ（pkg-update は削除）
```

- `config.json`, `styles/`（7 ファイル）, `FAVORITES.md`, `scripts/pkg-update/` を削除する。スタイル探索の記録は git 履歴に残る。
- username は Nix の引数として直接埋め込む。現行 `default.nix` の「JSON 読み込み後に format へ username を連結するハック」は消える。
- `style.css` は次のセクション構造で書く: 色トークン, リセット, 島の基礎, workspaces, 状態色, tooltip。

## 初回起動フォールバック

todo.md に「初回起動時に `colors.css` が存在せず waybar が起動できない」とあるが、フォールバック生成は `home-manager/desktop/matugen/default.nix` の activation に実装済みだった（todo.md が古い）。
本リファクタでは実装は行わず、activation の存在確認だけを検証手順に含める。
wallust 依存の削除により、waybar が起動時に必要とする色ファイルは matugen 系の `colors.css` 1 つに減る。

## スコープ外

- quickshell 側の変更（コントロールセンターの機能追加など）。バーから操作を寄せる先はすべて既存機能とする。
- 壁紙関連スクリプトや matugen の生成フロー自体の変更。
- `hyprland/scripts/waybar/reload-css.sh` は壁紙切替の `post.sh` から呼ばれているため削除しない。

## 検証

1. `nix run .#build` と `nix run .#fmt -- --fail-on-change` を通す。
2. 実機で `nix run .#switch` 後、明るい壁紙と暗い壁紙の両方で境界の見え方とブラーの効きを目視確認する。
3. クリックの動作を確認する: ランチャー, ワークスペース移動, bluetooth ポップアップ, オーディオセレクタ、そして control-center 島は idle_inhibitor・ベル・電源のどこを押してもコントロールセンターが開くこと。
4. 確認が済んでから push する（main 直 push は CI フルビルドが走るため、ローカル検証を先に行う運用に従う）。
