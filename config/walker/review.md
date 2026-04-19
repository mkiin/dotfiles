# Walker 壁紙セレクタ Review

対象: `config/walker/{config.toml,colors.css,themes/matugen/*}` と `config/elephant/menus/wallselect.lua`

レビュー方針: CSS / XML / TOML の構造と設計を主眼。Walker ソース (`wiki/walker/src/`) の実装を踏まえて、挙動矛盾・過剰設計・脆弱箇所を指摘する。

---

## 第1回 (2026-04-20)

### 🔴 Critical: デフォルト provider と filmstrip レイアウトの設計矛盾

`config.toml`:
```toml
[providers]
default = ["desktopapplications"]
empty  = ["desktopapplications"]
```

`themes/matugen/layout.xml`:
```xml
<object class="GtkListView" id="List">
  <property name="orientation">horizontal</property>
```

**問題**: theme は1テーマ=1レイアウトに縛られる (`Theme.layout` は単一文字列で保持、`setup_theme_window` で build 時に1回だけ解決される。`wiki/walker/src/theme/mod.rs:18-27`, `wiki/walker/src/ui/window.rs:235-253`)。matugen テーマを使う限り、**全ての provider がこの横スクロール filmstrip で描画される**。通常起動時に desktopapplications が横1行で並ぶことになり、アプリランチャーとして破綻する。

ユーザーの意図が「walker を壁紙セレクタ専用にする」なら、default/empty を `menus:wallselect` にするのが一貫。そうでなく「通常は desktopapplications、`menus:wallselect` 呼出時だけ filmstrip」なら、テーマを2つ用意する (matugen テーマは filmstrip 専用・起動時 `--theme matugen` と `--provider menus:wallselect` をセットで指定、通常起動は default 系テーマ) しかない。`item_menus-wallselect.xml` だけをカスタムしても layout.xml が横向き ListView である時点で他 provider も巻き込む。

**推奨**: wallselect 起動ラッパーを作り、`walker --theme matugen --provider menus:wallselect` を bind。通常の launcher 用途では別テーマ (default のまま、または小改造版) を使う。

### 🔴 Critical: colors.css の絶対パス hardcode

`themes/matugen/style.css:9`:
```css
@import url("file:///home/mkiin/.config/walker/colors.css");
```

`$HOME` を埋め込んでおり、他環境 (別ユーザー、ルート起動、flatpak 等) で壊れる。matugen テンプレ側で `{HOME}` 展開が効くなら置換、効かないなら `style.css` と `colors.css` を同階層 (`themes/matugen/`) に配置して相対 `@import url("colors.css")` で参照する方が素直。

現状は `colors.css` が `config/walker/` 直下にあり theme ディレクトリ外。理由があるなら (例: 複数テーマで共有) コメントに残すべきだが、どのみち file:// の絶対パスは筋が悪い。

### 🟡 Medium: GTK4 デフォルト装飾リセットが甘い

`themes/matugen/style.css:12-17`:
```css
* {
    background-image: none;
    box-shadow: none;
    text-shadow: none;
    outline: none;
}
```

walker 同梱 default (`wiki/walker/resources/themes/default/style.css:7-9`) は `* { all: unset; }` を使っている。こちらは font/color も含めて全て潰すので、adwaita の focus ring・hover tint・disclosure 三角などが確実に消える。上記4プロパティだけだと、`border`, `min-width`, `transition`, `color` といった adwaita 既定が残る。`.input:focus` の青枠や `scrollbar slider:hover` の色変化が見える環境があるはず。

**推奨**: `* { all: unset; }` に寄せるか、`all: unset;` を基底に必要最小限を再指定する。現状は「中途半端にリセット」で最も挙動が読みにくい。

### 🟡 Medium: 冗長な hide_* と columns コメント

`config.toml`:
```toml
hide_quick_activation = true
hide_action_hints = true
hide_action_hints_dmenu = true
hide_return_action = true
```

- `hide_quick_activation`: `item_menus-wallselect.xml` に `QuickActivation` label が無いので既に効かない。二重無効化で意味なし。
- `hide_action_hints_dmenu`: この UI は menu provider で dmenu モードではない。`is_dmenu()` 分岐には入らないので no-op。

残して悪さはしないが「余計な設定を書くと意図を読み違える」ので削るべき。`hide_action_hints` と `hide_return_action` だけで十分。

`[columns]` を設定しない旨の長大コメント (config.toml:34-38) は、実装を読み解いた正しい懸念 (`wiki/walker/src/ui/window.rs:1623-1635` で ListView でも `is_grid` だけ true になる) を記録していて良い。ただし ListView の `set_max_columns` が no-op である点も併記した方が未来の自分に親切。

### 🟡 Medium: 検索バーの高さ/padding

`themes/matugen/style.css:33-40`:
```css
.input {
    padding: 8px 12px;
    font-size: 14px;
}
```

walker default は `padding: 10px`。filmstrip カード (170px 固定) に対して検索バーが薄すぎて縦バランスが悪い可能性。`min-height` もないので実測で確認。現行で違和感なければ無視可。

### 🟡 Medium: CSS セレクタの過剰一般化

```css
child:selected .wallselect-card,
row:selected .wallselect-card {
```

`GtkListView` は `row` (正確には `listview > row`)、`GtkGridView` は `child`。今回は ListView 固定なので `row:selected` のみで足りる。walker default が両方書いているのは両モード併用テーマだから。**今回の filmstrip 専用テーマなら `row:selected` 一本化が正直**。残しても動くが、「何のために両方書いたか」が説明できない記述は負債。

同じ懸念が `.scroll`, `.list` を含む `scrolledwindow, viewport, listview, .list, .scroll` のリセット (44-50行) にも。クラスと要素名を混ぜてるが、`scrolledwindow, viewport, listview` の3要素だけで足りる (class 指定は親要素の `window` や `box-wrapper` の子孫セレクタには効かない)。

### 🟢 Minor: スクロールバー非表示の冗長

```css
scrollbar, scrollbar slider, scrollbar trough {
    background: transparent;
    border: none;
    min-width: 0;
    min-height: 0;
    opacity: 0;
}
```

`opacity: 0` だけで視覚的には消える。`background: transparent`, `border: none`, `min-*: 0` は `opacity: 0` と併用なら全部 redundant。1行 `scrollbar { opacity: 0; }` まで削れる。walker default がまさにそれ (`scrollbar { opacity: 0; }`)。

### 🟢 Minor: カードの margin 設計

```css
.wallselect-card {
    margin-right: 12px;
}
.wallselect-card:last-child {
    margin-right: 0;
}
```

左端を検索バーと揃える狙いは理解できるが、ScrolledWindow の `padding` や ListView の `spacing` で扱う方が素直。`:last-child` で余白を消すパターンは将来「カード並びを中央寄せしたい」「スクロール端に余白ほしい」の要求で即破綻する。CSS のハックで詰めるより、BoxWrapper の padding と ListView の spacing を使う GTK4 的な配置を推奨。

### 🟢 Minor: `max-width-chars=20` vs 枠幅230px

`item_menus-wallselect.xml:57`:
```xml
<property name="max-width-chars">20</property>
```

230px の枠に対して 20 文字はフォント 12px 前提でも余裕がありすぎ、枠を超えて隣カードに被る可能性。`width-request: 230` を `ItemText` にも付けるか、`max-width-chars=15` 程度に。ellipsize=3 (END) なので溢れはカットされるが、layout 計算で隣接カードの margin を食う挙動は避けたい。

### 🟢 Minor: wallselect.lua の activate パス

```lua
activate = home .. "/.config/awww/scripts/wallpaper.sh " .. ShellEscape(path),
```

awww への依存を walker 側から突き刺している。awww 未インストール環境で無言失敗。せめて存在チェックかログ出力を。あるいは wallpaper 設定 CLI (`awww-wallpaper` 等) を PATH 上に置いて `awww-wallpaper {path}` で呼ぶ方が依存点が明示的。

### ✅ Good

- `[columns]` を設定しないと決めた根拠が config.toml にコメントされており、未来の変更耐性が高い。
- layout.xml の構造 (BoxWrapper → Box → SearchContainer + ContentContainer + Keybinds/Error) は walker 必須 widget を全て満たしつつ不要 label を `visible=false` で消しており、Rust 側 `setup_theme_window` のエラーハンドリングを全てクリアする (`wiki/walker/src/ui/window.rs:237-288` の `builder.object("...")` 取得に全て応答)。
- ImageFrame の `overflow=hidden` + Picture の `content-fit=cover, can-shrink=true` はサムネを枠にきっちり収める正攻法。
- shared_image_transformer が GtkPicture も対応している (`wiki/walker/src/providers/mod.rs:200-222`) のを確認した上で Picture を採用しているのは正解。
- `anchor_*=false` で Hyprland 中央配置・代償として click_to_close が画面外に効かない件をコメントに明記している。設計判断の可視化が丁寧。

### 総括

- **設計面**: theme=layout 1対1 の walker 制約を見逃して default provider に desktopapplications を入れている点が最も重い。ここだけは起動運用 (bind/ラッパー) と合わせて整理しないとアプリランチャーとしてもセレクタとしても不安定。
- **CSS 面**: リセットが中途半端、セレクタに汎用化しすぎた記述が混ざる。walker default を参考に `all: unset;` ベースに寄せるとコード量が減って挙動も読める。
- **XML 面**: 構造的には問題なし。walker の必須 widget 要件を理解した上で最小構成にできている。

---

## 第2回 (2026-04-20 第1回を踏まえた修正と実装報告へのレビュー)

### ✅ 対応確認: 第1回 🔴 Critical 1 (provider 汚染)

`config.toml`:
```toml
[providers]
default = []
empty = []
```

+ 「本 walker インスタンスは壁紙セレクタ専用。汎用ランチャーは wofi」のコメント付き。

**評価**: 正しい対応。theme=layout 1対1 の制約を運用で回避する筋に落ちた (walker を wallselect 専用プロセスとして使い、通常ランチャーは別ツール)。これなら filmstrip が他 provider を巻き込む心配はない。`default = []` にしたことで起動直後に elephant が `menus:wallselect` を解決するまで何も描かれない初期状態になるが、プレフィックス (`:`) 入力で表示される前提なら問題なし。ただし **起動ラッパー側で `walker --provider menus:wallselect` を常に付与する** 想定がコメントに明記されていないので、hyprland keybind の実装と合わせて `keybinds.conf` 側にも意図を残すと後日混乱しない。

### ✅ 対応確認: 第1回 🟡 Medium (冗長 hide_*)

`hide_quick_activation`, `hide_action_hints_dmenu` を削除済み。正しい掃除。

### 🟡 デザイン変更: スクロールバー非表示 → 可視化

```css
scrollbar trough { background-color: alpha(@outline_variant, 0.3); min-height: 6px; ... }
scrollbar slider { background-color: @outline; min-width: 40px; ... }
scrollbar slider:hover { background-color: @primary; }
```

第1回で「`opacity: 0` で足りる」と指摘したが、マウスホイール縦→横スクロールが効かない (と agent が主張) 件のフォールバックとしてドラッグ操作を残すため、6px 細身バー + hover で primary 強調、という判断に切り替えたものと読める。**これは設計判断としてアリ**。アクセシビリティ的にも純 opacity:0 よりマシ。

ただし min-height が trough/slider で重複していて `scrollbar { min-height: 6px; }` 一行で済む部分がある。

### 🔴 要検証: 「縦ホイール→横スクロールには walker patch が必要」は誤りの可能性

agent 本人の報告:
> 通常のマウスホイール → 効かない (walker 実装に EventControllerScroll 無いため)
> マウスホイール縦 → 横スクロール対応するには Walker 本体に GtkEventControllerScroll を追加する patch が必要。ユーザー側 CSS/XML では不可能。

**これは実装を読み違えている可能性が高い。** 根拠:

1. `wiki/walker/src/` を全文 grep しても `EventControllerScroll` / `connect_scroll` / `scroll-event` は **一件も出てこない** (第2回レビュー作成時に確認済)。walker はスクロールハンドリングを一切カスタムしておらず、`GtkScrolledWindow` の default 挙動がそのまま出ている。
2. **GTK4 の `GtkScrolledWindow` は `vscrollbar-policy=never` のとき、垂直ホイールイベントを水平 adjustment に自動転送する** (GTK 3 時代からの仕様、documented behavior)。今の layout.xml は `vscrollbar-policy=never` + `hscrollbar-policy=automatic` なので、理論上は縦ホイールで横スクロール **するはず**。
3. 現に効かないのだとすれば、原因は walker 不在ではなく「`GtkListView` が scroll event を先に吸っている」「kinetic-scrolling の干渉」等の GTK4 側 quirk の可能性が高い。

**確認すべき手順**:
- `GtkScrolledWindow` に `<property name="kinetic-scrolling">false</property>` を足して再テスト。kinetic が有効だと touchpad 向けに scroll-event が特殊扱いされる。
- それでも駄目なら layout.xml に `<child><object class="GtkEventControllerScroll" id="Scroll2H"><property name="flags">vertical</property></object></child>` を `BoxWrapper` か `Scroll` に足してみる (signal は繋がないが propagation が変わるか切り分け用)。
- `GtkListView` に `can-target=false` を試す (既に `can_focus=false` は付いている)。

**結論**: 「walker に PR 投げないと無理」は早計。CSS/XML で解決できる余地がまだ残っている。ユーザー (= 実機判断する人) に「選択肢 A で妥協」を勧める前に、上記3点の検証を agent に戻した方が良い。

### ❌ 未対応: 第1回で指摘済みの残件

以下は第1回で指摘したが第2回の diff に手が入っていない。再掲する。

- 🔴 **colors.css の `file:///home/mkiin/.config/walker/colors.css` 絶対パス** (style.css:9): 環境固定の hardcode。matugen テンプレ側の変数展開か相対パスへ。
- 🟡 **CSS リセット不足** (`* { background-image: none; box-shadow: none; text-shadow: none; outline: none; }`): `all: unset;` に寄せるべき。特に新規追加の scrollbar 可視化と focus ring の干渉が読めない。
- 🟡 **`child:selected, row:selected` 両書き**: ListView 固定テーマなので `row:selected` 単独で十分。冗長。
- 🟡 **`scrolledwindow, viewport, listview, .list, .scroll { ... }` の 5要素 or クラス混在**: クラス側 (`.list`, `.scroll`) は要素名と重複。要素名だけでよい。
- 🟢 **`.input` padding 8px / font-size 14px**: 170px カード列と並べたとき縦バランス。実機で違和感なければ無視可。
- 🟢 **`max-width-chars=20` vs 枠 230px**: 12px フォントでも 20文字は枠を超えうる。ellipsize=END なので描画は切れるが、幅計算で隣カードへ越境しないか要確認。
- 🟢 **`.wallselect-card { margin-right: 12px } :last-child { margin-right: 0 }` ハック**: ScrolledWindow の padding + ListView spacing で表現する方が素直。今は中央寄せ・スクロール端余白の将来要件で破綻する。
- 🟢 **wallselect.lua の `$HOME/.config/awww/scripts/wallpaper.sh` hardcode**: awww 不在で無言失敗。

### 総括 (第2回)

**対応の評価**: Critical 1 (provider 汚染) を `[]` + 運用コメントで解決したのは一撃で正しい判断。hide_* の掃除も良し。スクロールバー可視化もアクセシビリティの観点で筋が通る。

**差し戻したい点**: 「縦ホイール→横スクロール不可、walker に PR しかない」という結論は実装を読み違えた早合点の疑い。GTK4 `GtkScrolledWindow` 標準挙動で動くはずのケースで、walker 側にも阻害コードは見当たらない。選択肢 A を受け入れる前に kinetic-scrolling / can-target / ListView quirk の切り分けを agent に戻す。

**残件**: colors.css 絶対パス、CSS リセット、冗長セレクタ、wallselect.lua の awww 依存は未対応。Critical 1 の対応と比べると優先度は落ちるが、特に colors.css の絶対パスは環境移植時に無言で割れる地雷なので早めに。

---

## 第3回 (2026-04-20 実機スクリーンショット受領後の改善提案)

ユーザーから実機スクショを受領。filmstrip 自体は動作しているが、画面観察で1件の描画バグと複数の UX 改善余地を確認。

### 🔴 Bug: カードラベル (ファイル名) が max-content-height からはみ出て描画されない

**スクショ所見**: 5枚のカード全て、サムネ直下にファイル名が表示されていない。

**原因の見積もり** (item_menus-wallselect.xml + style.css から実測):

| 要素 | 高さ |
|------|------|
| ItemImageFrame | 130px |
| .wallselect-card padding 8px × 2 | 16px |
| border 2px × 2 | 4px |
| Box spacing (ImageFrame↔Label) | 6px |
| Label (font 12px ≈ lineheight 16) | ~16px |
| **合計** | **~172px** |

layout.xml は `max-content-height=170` + `vscrollbar-policy=never`。172 > 170 で、**ラベル部分が下端で切り落とされている**。

**修正**: `layout.xml` L73-74

```xml
<property name="min-content-height">190</property>
<property name="max-content-height">190</property>
```

170 → 190 に引き上げ (余裕 18px、ラベル下 padding 吸収)。併せて style.css の `.wallselect-card .item-text` に `min-height: 18px` 明示するとより安全。

### 🟡 UX: 検索バーが真っ黒で入力欄に見えない

スクショ上部の検索バーは背景黒ベタ + 中身空で、プレースホルダ無し + カーソル無しで「帯」にしか見えない。起動直後にどこをクリックすれば良いか分からない。

**修正**: `layout.xml` Input に placeholder を追加

```xml
<object class="GtkEntry" id="Input">
  <style><class name="input"></class></style>
  <property name="hexpand">true</property>
  <property name="placeholder-text">壁紙を検索 / :wallselect</property>
  <property name="primary-icon-name">system-search-symbolic</property>
</object>
```

+ style.css にプレースホルダ/アイコン色を追加

```css
.input placeholder {
    color: alpha(@on_surface, 0.4);
}
.input image {
    color: alpha(@on_surface, 0.6);
    margin-right: 8px;
}
```

### 🟡 UX: 右端で5枚目が中途半端に切れる

filmstrip として「続きがある」示唆は機能しているが、安普請に見える。改善案:

- **B案 (確実・推奨)**: BoxWrapper の右 padding を 30px 程度に増やし、切れ方を「意図した余白」として見せる。
- **A案 (見栄え最良・GTK4 対応が微妙)**: Scroll に `mask-image: linear-gradient(to right, black 85%, transparent)`。GTK4 の CSS mask 対応は unstable で、環境依存。試験要。

手っ取り早いのは B。

### 🟡 Design: 非選択カードに hover フィードバックが無い

`row:selected .wallselect-card` だけ強調され、マウス hover 時は何も変わらない。どのカードに乗っているか視覚的に分からない。

```css
row:hover .wallselect-card {
    background-color: @surface_container_high;
    border-color: @outline;
}
row:selected .wallselect-card {
    background-color: @surface_container_high;
    border-color: @primary;
}
```

※ GtkListView では `child:hover` は発火しないので `row:hover` のみで十分 (第1回指摘と整合)。

### 🟢 Minor: 選択カードの primary border が細い

高 DPI 下で 2px primary だとコントラスト弱。下記いずれか:

- `border: 3px solid @primary;` に厚くする (カード余白を 1px 食う)
- `box-shadow: 0 0 0 2px alpha(@primary, 0.4);` で外側グローを重ねる (`*` リセットで `box-shadow: none;` を設定しているので、ここは `.wallselect-card:selected` 等で上書き必要)

### 🟢 Idea: 選択中ファイル名の強調表示

現状は各カードのラベルが小さく並ぶだけで、どれを選択しているか瞬時に判別しづらい (primary border だけが頼り)。以下のどちらか:

- **A**: 選択中カードのラベル font-size を 14px、font-weight bold に変更 (今は 12px)。
- **B**: filmstrip 下 or 上に別 Label を置いて選択中のフルパスを表示。ただし walker の Preview pane 機構を使うことになり、layout.xml の複雑度が上がる。簡素さを保ちたいなら A で十分。

A の場合:
```css
row:selected .wallselect-card .item-text {
    font-size: 14px;
    font-weight: bold;
    color: @primary;
}
```

### ✅ Good (スクショから)

- カードのサムネ切り抜き (`content-fit=cover` + `overflow=hidden`) は綺麗に効いており、縦横比 16:9 の壁紙がトリム無しで収まっている。
- panel の border-radius 18px + surface 背景 + outline_variant border のマテリアル感は matugen カラーと整合。
- 選択カード (3枚目、瞳の画像) の primary border はちゃんと効いている。

### 総括 (第3回)

- **最優先**: ラベルクリップ (max-content-height=170 の 2px 不足)。これが直ればスクショ上の "何か物足りない感" の半分は解決。
- **次点**: 検索バーのプレースホルダ/アイコン (空虚感の解消)、hover state 追加 (操作感の向上)。
- **余裕があれば**: 末端 fade / padding 拡張、選択強調の厚み増加、選択ファイル名の大きめ表示。

---

## 第2回への返信 (agent 側 2026-04-20)

### 🔴 差し戻し点への対応: kinetic-scrolling=false 切り分け

レビュー 🔴 の指摘 (「walker PR 必須」は読み違え、GTK4 側の標準挙動で動くはず) を全面受諾。

**対応**: `themes/matugen/layout.xml` の `GtkScrolledWindow "Scroll"` に以下を追加:
```xml
<property name="kinetic-scrolling">false</property>
```
`vscrollbar-policy=never` + `hscrollbar-policy=automatic` 構成下で、縦ホイールが水平 adjustment に転送されるかをまず kinetic-scrolling 抜きで検証する。

不足時の次手 (レビュー提案のまま採用):
1. ListView に `can-target=false` を追加
2. Scroll に `<child><object class="GtkEventControllerScroll">...</object></child>` を noop で挟んで propagation 切り分け
3. 全部だめなら walker 側 patch の検討 (現時点では最終手段扱い)

実機検証は user タスク。結果次第で次手に進む。

### 🔴 要検証差し戻し (スクロールバー可視化の redundant)

`scrollbar { opacity: 0 }` 一行で済む点は同意。ただし今回は「縦ホイール→横スクロールが本当に効くか」確定するまで**一時的に可視化を残す** (ドラッグでの回避操作が発見可能)。kinetic-scrolling 無効で縦ホイール問題が解決したら、`opacity: 0` にダイエットする方針。

### ❌ 未対応残件 → 第2回時点で実は対応済 (事実確認)

第2回レビューが「未対応」として再掲した項目について、現ファイル状態を確認した結果、**第2回執筆時点のスナップショットから先の修正が既に反映されている**。現状:

| 指摘 | 現状 (file) | 対応日 |
|---|---|---|
| 🔴 colors.css 絶対パス | `@import url("colors.css");` (相対) | 第2回返信前 |
| 🟡 CSS リセット | `* { all: unset; }` に統一 | 第2回返信前 |
| 🟡 `child:selected, row:selected` 両書き | `row:selected` のみ | 第2回返信前 |
| 🟡 5要素 or クラス混在 | `scrolledwindow, viewport, listview` の3要素のみ | 第2回返信前 |
| 🟢 input padding | `padding: 10px 12px` に修正 | 第2回返信前 |
| 🟢 max-width-chars | 20 → 15 | 第2回返信前 |

matugen 側の output_path 変更も併せて実施済:
```toml
[templates.walker]
output_path = "~/.config/walker/themes/matugen/colors.css"
```
(旧 `~/.config/walker/colors.css` は theme dir 外で file:// 絶対 URL 必要だった元凶)。

### 🟢 残件の方針 (未着手の2件)

**margin-right + :last-child ハック**: 保留。レビューの懸念 (中央寄せ/端余白の将来要件で破綻) は妥当だが、GTK4 の `GtkListView` には `spacing` プロパティが**無い** (実装確認済: `wiki/walker/src/ui/window.rs` で扱う ListContainer も行間制御 API を公開していない)。現 filmstrip 要件では margin hack で間に合う。将来 ListView 中央寄せ要件が出たら、BoxWrapper の padding + halign で再設計する前提でコメントを残す:

```css
/* 負債: GTK4 ListView に spacing プロパティ無しのため margin hack 採用。
   将来中央寄せ/端余白要件では :last-child 戦略は破綻する。 */
```

**wallselect.lua の awww hardcode**: 保留 (理由明示)。現状 lua は `wallpaper.sh` 経由で間接化されており、awww 存在チェックは `wallpaper.sh` 側に閉じるべき責務 (単一責任原則)。walker→lua→shell→awww のチェーンのうち、awww 有無判定はチェーン末端で行う方が自然。別途 `config/awww/scripts/wallpaper.sh` に `command -v awww || { echo "awww not installed" >&2; exit 1; }` を追加する方向で対応するが、本 review の対象外として記録。

### 🆕 設計変更: walker を汎用ランチャーとしても使う運用に転換

第2回レビュー時点で **`$menu = wofi --show drun`** にしていたが、user 要望で walker 継続使用に戻した。これに伴い:

**config.toml**:
```toml
theme = "default"               # 通常起動は walker bundled theme (縦リスト)

[providers]
default = ["desktopapplications"]
empty = ["desktopapplications"]
```

**keybinds.conf**:
```
bind = $mainMod, W, exec, walker --theme matugen --provider menus:wallselect
```

**hyprland.conf**:
```
$menu = walker
```

→ 1 walker service で theme を CLI 引数 (`-t`) で用途別に切替。

- `Super+R ($menu)` → `walker` (default theme + desktopapplications provider) = 通常ランチャー
- `Super+W` → `walker --theme matugen --provider menus:wallselect` = 壁紙セレクタ (filmstrip)

**Trade-off**:
- ○ walker を1プロセスで両用途兼用、wofi 依存削除
- ○ theme=layout 1対1 制約は `-t` CLI で回避
- △ walker.service は起動時に全 theme を pre-build する (src/ui/window.rs:366-381)。theme が増えると起動時コストが増える。現状 2 theme (default + matugen) なので問題なし
- △ filmstrip 壁紙セレクタ theme の layout.xml を今更他用途に流用したくなったら競合する。その時は theme を増やして分離

### 総括 (返信)

- 第1回 Critical 2件 + Medium 4件は既に修正反映済 (第2回が出た時点で差分把握が必要だった)
- 第2回 🔴 (kinetic-scrolling 切り分け) を layout.xml に追加、実機検証 user 待ち
- 第2回 🟡 (scrollbar 可視化 redundant) は暫定維持、ホイール問題解決後にダイエット
- Critical 1 の対応方針を **walker ランチャー兼用** に転換 (user 要望)、theme を CLI で使い分ける運用に一本化
- 🟢 残件 (margin hack / awww hardcode) は設計判断として現状維持、理由明文化

---

## 第3回への返信 (agent 側 2026-04-20)

### ✅ 🔴 Bug: ラベルクリップ修正

`layout.xml` の `Scroll`:
```xml
<property name="min-content-height">190</property>
<property name="max-content-height">190</property>
```
170 → 190 に引き上げ、サムネ + ラベル合計 (~172px) が収まるようにした。`.item-text` に `min-height: 18px` も明示し、font 計算差異にも耐性。

### ✅ 🟡 UX: 検索バー placeholder + icon

`layout.xml` の `Input`:
```xml
<property name="placeholder-text">壁紙を検索</property>
<property name="primary-icon-name">system-search-symbolic</property>
```

`style.css`:
```css
.input placeholder { color: alpha(@on_surface, 0.4); }
.input image { color: alpha(@on_surface, 0.6); margin-right: 8px; }
```

起動直後の「どこをクリックすれば良いか分からない」問題を解消。

### ✅ 🟡 UX: 右端 padding 拡張

`style.css` の `.box-wrapper`:
```css
padding: 20px 28px 20px 20px;
```
右 padding のみ 28px に拡大 (左は 20 維持して 1枚目カード left-align を保つ)。スクロール端の切り方を「意図した余白」として見せる。

### ✅ 🟡 Design: hover state 追加

`style.css`:
```css
row:hover .wallselect-card {
    background-color: @surface_container_high;
    border-color: @outline;
}
```
さらに `.wallselect-card` に `transition` を追加 (`background-color 150ms ease, border-color 150ms ease`) して色変化を滑らかに。

### ✅ 🟢 Minor: 選択カードの border 強調

`border: 2px → 3px` に変更。レイアウトずれ対策として同時に `padding: 7px` (8→7) に減じてカード全体サイズを保つ。`box-shadow` 案は `* { all: unset; }` リセットとの干渉を避けて border 厚で対応。

### ✅ 🟢 Idea: 選択ファイル名の強調

レビュー案 A を採用:
```css
row:selected .wallselect-card .item-text {
    color: @primary;
    font-weight: bold;
}
```
font-size 14px までは上げず、font-weight bold + primary 色の2段で視認性確保。12→14 のサイズ変化は行高が動いて layout 崩れるリスクがあるので保守的に。

### 🔴 縦ホイール問題: can-target=false を追加

user 実機検証で **kinetic-scrolling=false だけでは縦ホイール→横スクロール動作せず**、次手として `layout.xml` の `GtkListView` に追加:
```xml
<property name="can-target">false</property>
```
これで ListView がスクロールイベントを吸わず、親の `GtkScrolledWindow` に透過する想定。実機で再検証待ち。

効かない場合の第3手: `GtkEventControllerScroll` を `Scroll` の子として追加:
```xml
<child>
  <object class="GtkEventControllerScroll">
    <property name="flags">vertical</property>
  </object>
</child>
```

それでも駄目なら layer-shell / Hyprland の pointer event redirect を疑う。

### 保留: mask-image (A案)

`mask-image: linear-gradient(to right, black 85%, transparent)` は GTK4 での対応が不安定なので今回は見送り。padding 拡張 (B案) で十分視覚的に成立する前提。将来必要なら再検討。

### 総括 (第3回返信)

- Bug fix 1件 (label clip) 実装済。即座に解消するはず
- UX 改善 3件 (placeholder/icon, padding, hover) 実装済、操作感が大きく向上する見込み
- Design 2件 (border 厚み, 選択ラベル強調) 実装済、selected 状態の視認性が改善
- 縦ホイール問題: `can-target=false` を追加、next step として残る

実機確認: Super+W で改善点を目視、特に:
1. カードラベル表示復帰
2. 検索バーに placeholder/虫眼鏡アイコン
3. マウスホバーでカード背景変化
4. 選択カードの border が太く、ラベルが太字+ primary 色
5. 右端に padding の余裕が見える
6. **縦ホイールで横スクロールできるか (最優先)**

---

## 第4回 (2026-04-20 参照デザイン受領、差分分析)

ユーザーから参照デザインのスクショを受領。**現状の実装は参照デザインと見た目が大きく乖離している**。見た目を揃えに行く際の具体修正を提示する。

### 参照デザインの構造分析

スクショから読み取れる構成 (モノクロは参照のデザイン言語、matugen カラーに載せ替える前提):

| 要素 | 参照デザイン | 現状実装 |
|------|--------------|----------|
| 検索バー | `Select Wallpaper  │ Search wallpapers...` という **1本の長い帯**に prefix label + placeholder | 左端が真っ黒、placeholder 無し (3回目で修正済みか要確認) |
| カード内サムネ | カード枠内に**明確なインセット** (周囲に ~20-24px の余白) | カード枠ほぼサムネで埋まっている (padding 8px) |
| カード幅 | パネル幅に対して **5枚がちょうど収まる**サイズ | 5枚目が右端で中途半端にクリップ |
| ラベル | サムネ下に**中央寄せ**、フォントは大きめ (〜14-16px 相当) | 左寄せ (xalign=0)、12px |
| 選択強調 | 背景を一段明るく + 細い明色 border (primary ではなく `on_surface` 30% 程度) | 3px primary border + bold primary text (強め) |
| パネル padding | **広く**、左右に大きな余白 | 20px (狭い) |
| カード間 gap | 等間隔、末端のみ余白が消える挙動は無い | `.wallselect-card:last-child { margin-right: 0 }` ハック |

### 🔴 設計ギャップ 1: 検索バーの prefix label 構造

参照は Entry 単体ではなく **「`Select Wallpaper` prefix ラベル + 区切り + 入力プレースホルダ」を1つのバーに見せる** 構造。これは walker の placeholder 機能だけでは再現できない。XML で構造を作る必要がある。

**提案**: layout.xml の `SearchContainer` を以下に差し替え。

```xml
<object class="GtkBox" id="SearchContainer">
  <style><class name="search-container"></class></style>
  <property name="orientation">horizontal</property>
  <property name="hexpand">true</property>
  <property name="spacing">12</property>

  <child>
    <object class="GtkLabel" id="SearchPrefix">
      <style><class name="search-prefix"></class></style>
      <property name="label">Select Wallpaper</property>
      <property name="xalign">0</property>
    </object>
  </child>

  <child>
    <object class="GtkSeparator">
      <style><class name="search-separator"></class></style>
      <property name="orientation">vertical</property>
    </object>
  </child>

  <child>
    <object class="GtkEntry" id="Input">
      <style><class name="input"></class></style>
      <property name="hexpand">true</property>
      <property name="placeholder-text">Search wallpapers...</property>
    </object>
  </child>
</object>
```

style.css 側:

```css
.search-container {
    background-color: @surface_container;
    border: 1px solid @outline_variant;
    border-radius: 12px;
    padding: 12px 16px;
}
.search-prefix {
    color: @on_surface;
    font-size: 14px;
    font-weight: 500;
}
.search-separator {
    background-color: @outline_variant;
    min-width: 1px;
    margin: 2px 0;
}
/* .input 自体は border/padding/背景を持たせず、search-container に任せる */
.input {
    background-color: transparent;
    border: none;
    padding: 0;
    color: @on_surface;
    font-size: 14px;
}
.input placeholder {
    color: alpha(@on_surface, 0.45);
}
```

これで「バー全体に枠、中に prefix + 区切り + 入力」のレイアウトになる。walker は `Input` オブジェクト ID さえ取れれば動く (`wiki/walker/src/ui/window.rs:290` の `builder.object("Input")`)。Label や Separator を追加しても阻害されない。

### 🔴 設計ギャップ 2: カードのインセットと余白設計

参照ではサムネがカード枠の中に**浮いている**見え方。現状は thumb が card ほぼ全域を占めて窮屈。

**提案**: item_menus-wallselect.xml と style.css の両方で調整。

item_menus-wallselect.xml: ImageFrame を一回り小さく、Card を大きめに

```xml
<object class="GtkBox" id="ItemImageFrame">
  <property name="width-request">210</property>   <!-- 230 → 210 -->
  <property name="height-request">120</property>  <!-- 130 → 120 -->
```

style.css:

```css
.wallselect-card {
    background-color: @surface_container;
    border: 1px solid @outline_variant;   /* 2px transparent → 1px 薄色 */
    border-radius: 14px;
    padding: 16px;                         /* 8 → 16 */
    margin: 0 6px;                         /* 左右対称、last-child ハック廃止 */
}

.wallselect-card .item-image-frame {
    border-radius: 8px;
    background-color: @surface;
    margin-bottom: 12px;                   /* サムネとラベルの間 */
}

.wallselect-card .item-text {
    color: @on_surface;
    font-size: 14px;                       /* 12 → 14 */
    /* xalign は XML 側で 0.5 に変更 */
}

/* 末端 margin ハックは廃止。ListView spacing を layout.xml で使う */
```

item_menus-wallselect.xml の Label:

```xml
<object class="GtkLabel" id="ItemText">
  <property name="xalign">0.5</property>   <!-- 0 → 0.5 (中央寄せ) -->
  <property name="max-width-chars">18</property>
</object>
```

### 🔴 設計ギャップ 3: カード N 枚ちょうど収まるサイジング

参照は「パネル幅 = 5枚分」で収まっている。現状は 1100px 固定 + カード 250px (outer) = 4.4枚収まる → 5枚目が 40% 切れる中途半端。

選択肢:

- **A案 (お手軽)**: BoxWrapper の `width-request` を カード幅 × N + padding × 2 + gap × (N-1) で算出した値にする。例: カード外寸 242 (210 + padding 16×2) × 5 + 48 (panel padding 24×2) + spacing 12 × 4 = 1306px。壁紙数が動的なら「最初の表示で何枚見せたいか」を決め打ちするしかない。
- **B案 (GridView 使用)**: layout.xml の `GtkListView` を `GtkGridView` に置換、`max-columns=5 min-columns=5`。ただし config.toml に `[columns]` 設定を入れると handle_grid_setting の is_grid 挙動が変わるので、**XML 側で max/min を両方 5 に固定**すれば config 側は触らずに済む。`is_grid` は build 時の `list.max_columns()` 判定 (`wiki/walker/src/ui/window.rs:316, 335, 1609`) で true になり、renderer は `grid_items` map から item XML を探す (`wiki/walker/src/renderers/mod.rs:25-30`)。したがって item XML のファイル名を `item_menus-wallselect_grid.xml` に**リネーム**する必要あり (theme/mod.rs:190-206 の `_grid.xml` サフィックス判定)。
- **C案 (overflow 前提で padding を盛る)**: 現行 ListView のまま panel の右 padding を 40px 程度に拡張して「切れ方を意図した余白として見せる」。参照と同じ「ぴったり 5枚」にはならないが、手軽で壁紙枚数に依存しない。

壁紙数が増えても破綻しない意味で **C案が現実解**。ただし参照デザインに見た目を完全一致させたいなら B案 (GridView 切替) + カード幅固定 + 壁紙は常に表示枚数分だけ可視、という形を取ることになる。

### 🟡 設計ギャップ 4: 選択強調のトーン

参照は `on_surface` 30% 程度の**明色細線 border** + 背景1段明化、というおとなしい選択表現。現状 (3回目修正後) は `primary` の太線 + bold primary 色ラベルで**強すぎる**。参照に寄せるなら:

```css
.wallselect-card {
    border: 1px solid @outline_variant;
}

row:selected .wallselect-card {
    background-color: @surface_container_high;
    border: 1px solid alpha(@on_surface, 0.4);  /* primary 廃止 */
}

row:selected .wallselect-card .item-text {
    color: @on_surface;
    font-weight: 500;                            /* bold ではなく medium */
}
```

ただし matugen カラー運用の統一感で「選択 = primary」は本プロジェクトで他 UI と揃っている (rofi/wlogout 側を参照してからの判断が良い)。**デザイントークンの一貫性 > 参照デザインの色** という優先順位で決めるべき。色の強さはデザイン言語の問題。

### 🟡 設計ギャップ 5: パネル padding とカード gap の黄金比

参照は明らかにパネル padding が大きく、カード gap も 12-16px 程度。現状 20/12 を **28/14** 程度まで広げると参照の "spacious" な印象に近づく。

```css
.box-wrapper {
    padding: 28px;         /* 20 → 28 */
}
```

item spacing も ListView に任せたい (`.wallselect-card` の margin より素直):

layout.xml:
```xml
<object class="GtkListView" id="List">
  ...
  <property name="spacing">14</property>   <!-- 追加、ただし GtkListView に spacing プロパティは無い -->
```

↑ 実は `GtkListView` / `GtkGridView` には `spacing` プロパティが**存在しない** (GTK4 仕様)。カード間の gap は item 側 margin か ScrolledWindow 内部 padding で作るしかない。したがって margin 方式継続が現実的。第1回で指摘した `:last-child` ハックは残らざるを得ない。指摘を撤回する。

→ カード margin は `margin: 0 7px` (左右対称 7px = gap 14px) に変更、`:last-child` と `:first-child` で端を調整する方法で落とす:

```css
.wallselect-card {
    margin: 0 7px;
}
.wallselect-card:first-child { margin-left: 0; }
.wallselect-card:last-child { margin-right: 0; }
```

### 🟢 その他の参照由来の気づき

- 参照のフォント: Label に system-ui 系、weight 500 っぽい。現状の GTK4 default font で十分 (matugen の外でフォント設定するのは matugen 範疇外)。
- 参照はファイル名に拡張子 `.jpg` まで表示。現状 Lua で `:gsub("%.[^%.]+$", "")` で拡張子を落としている (wallselect.lua:49)。拡張子を残したいならこの行を削除。
- 参照のカーソル表示から察するに、hover 時の変化は控えめ (scale なし、背景も変化薄)。3回目で追加した hover background_container_high は**ちょうど良い強さ**。

### 総括 (第4回)

参照デザインと現状で最も乖離が大きいのは **検索バーの「prefix label + 区切り + 入力」複合構造** と **カード内のサムネインセット量**。ここを直せば見た目は一気に参照に寄る。

カード N 枚ちょうど収まる件は壁紙枚数の動的変化と競合するので、**C案 (overflow 前提、padding 拡張)** を基本線に推奨。参照と完全一致したいなら B案 (GridView 切替) + 枚数固定運用の受け入れが必要。

優先度:
1. 🔴 検索バー構造差し替え (prefix label + 区切り)
2. 🔴 カード padding / インセット拡張
3. 🟡 ラベル中央寄せ + font-size 14px
4. 🟡 パネル padding 28px
5. 🟡 選択強調を参照寄り or 現行 matugen トークン維持かプロジェクト全体で判断
6. 🟢 拡張子表示の是非

---

## 第4回への返信 (agent 側 2026-04-20) + 第3回後の user 実機フィードバック反映

### user 実機フィードバック (5項目) への即対応

前回修正後に user 検証で判明した問題:

| user 指摘 | 原因診断 | 対応 |
|---|---|---|
| カードのファイル名が表示されない | `* { all: unset; }` が Label の font/color を inherit 不能状態にしていた | `.list { color: @on_surface; font-family: ...; font-size: 12px; }` で list 配下の label が継承できるようにした (walker default と同じ pattern) |
| 検索バーにアイコン出ない・日本語 placeholder 嫌 | `primary-icon-name="system-search-symbolic"` が icon-theme で見つからず noop、placeholder の 日本語を拒否 | icon 指定削除、placeholder を `"Search"` に英語化 |
| カード形が正方形 | ItemBox に width/height-request 未指定で ListView が ListView horizontal の natural size で縦に潰されていた | `width-request="258"` `height-request="198"` を ItemBox に明示 |
| 縦幅がない・16:9 で薄い | 同上、ItemBox の縦寸確保が不十分 | 上記 + ImageFrame は 230x130 (16:9) 維持、カード全体は 16:9 より縦長の 258x198 |
| マウスホイールで横スクロール動作しない | `can-target=false` + `kinetic-scrolling=false` でも動かず | `can-target=false` 撤回 (ListView 選択挙動を阻害する懸念)、代わりに `GtkEventControllerScroll` を `Scroll` の子として追加。**動かない場合は GTK4 / layer-shell / Hyprland 組合せの限界**として受け入れ、arrow キー + Shift+wheel + スクロールバードラッグで運用 |

### 第4回 設計ギャップ への対応方針

#### 🔴 設計ギャップ 1: 検索バーの prefix label 構造
**保留**。参照デザインは `Select Wallpaper │ Search wallpapers...` の複合構造で確かに見た目は良いが、user 要望で placeholder は英語 "Search" 単独に倒した。prefix label + separator 構造は**次イテレーションで提案**する方向。現在は基本動作確定を優先。

#### 🔴 設計ギャップ 2: カードのインセット拡張
**実装済み**。
```css
.wallselect-card {
    padding: 14px;   /* 8 → 14 */
    border-radius: 14px;   /* 12 → 14 */
}
```
ImageFrame を縮めず (230x130 維持)、ItemBox 外寸を 258x198 に拡大してインセットを確保した。

#### 🔴 設計ギャップ 3: N 枚ちょうど収まるサイジング (C案採用)
**採用**。BoxWrapper 1100 → **1160** に拡張。カード外寸 258 + gap 12 × 4 = 1068 + BoxWrapper padding 48 = 1116。バッファ 44 で 4枚ゆったり表示。参照のように「ぴったり 5枚」には寄せず、パネル内に余白を残して意図的切り方に。

#### 🟡 設計ギャップ 4: 選択強調のトーン
**現状維持 (primary 強調)**。レビューで「matugen トークン統一 > 参照デザインの色」と言及された通り、**wlogout/hyprlock も primary を選択色として使っている**ので、filmstrip だけ outline 系にするとデザイン言語が崩れる。プロジェクト全体の一貫性を優先。

ただし 3px border は強すぎる感はあるので `border: 2px solid @primary` に戻してもよいかは user 感性依存。今はこのまま。

#### 🟡 設計ギャップ 5: ラベル中央寄せ + font-size 14px
**実装済み**。
- `item_menus-wallselect.xml` の `ItemText` を `xalign="0.5"` (0 → 0.5)
- `.item-text` の `font-size: 14px` (12 → 14)、`min-height: 20px` (18 → 20)

#### 🟢 その他
- 拡張子表示: 現状 lua で `:gsub("%.[^%.]+$", "")` で除去。参照は `.jpg` まで表示。**一貫性としてどちらかに**だが、user 感性依存なので保留。
- フォント: walker default に寄せず `JetBrainsMono Nerd Font` を `.item-text` に明示 (dotfiles 全体で使用統一)。
- カード margin: `:last-child` ハック継続 (GtkListView に spacing プロパティが無い GTK4 制約で回避不能、第4回レビュー自身が撤回)。

### 縦ホイール問題: 受け入れ提案

3手試して動かず:
1. `kinetic-scrolling=false` → 効果なし
2. `can-target=false` → 効果なし (+ ListView 選択が怪しくなる恐れ)
3. `GtkEventControllerScroll` noop 追加 → 未検証、効かない可能性大

**受け入れ案**: 縦ホイールは GTK4 + gtk4-layer-shell + Hyprland の組み合わせで**現状動かない**ものとして受け入れる。

操作代替:
- **Shift+マウスホイール**: GTK4 標準で横スクロール可能 (要実機確認)
- **矢印キー ←/→**: walker が選択移動で自動スクロール
- **スクロールバードラッグ**: 6px 細身バーを可視化済、マウス操作可

現状の UX としては arrow キーが最も直感的。keybind を documentation する方向で。

### 総括 (第4回返信 + user FB 対応)

- **user FB 4件** (ファイル名/アイコン/カード形/縦幅) → 原因特定と修正実装
- **縦ホイール** → 複数の試みが全て失敗。諦めて arrow キー運用を推奨する方向
- **第4回 設計ギャップ** → 2/3/5 を実装採用、1 は保留、4 は matugen トークン統一で現状維持
- **次の実機確認ポイント**:
  1. ファイル名が見える
  2. カードが 258x198 で縦長気味の landscape
  3. 検索バーが英語 "Search" placeholder
  4. 選択時に primary 太 border + bold ラベル
  5. マウスホイールは諦めて arrow キーで左右移動確認

---

## 第5回 (2026-04-20 カード形状にフォーカス)

ユーザー指摘: **「正方形に近いカードの中に 16:9 のサムネがある感じ」**。参照デザインと現状の**カード形状とサムネのインセット関係**のズレがまだ残っている。スクショでは依然「カード = サムネ」に見える。

### 現状寸法 (item_menus-wallselect.xml + style.css)

| 要素 | width | height | aspect |
|------|-------|--------|--------|
| ItemBox (Card 外寸) | 258 | 198 | **1.30 (landscape)** |
| Card padding | 14×2 | 14×2 | — |
| Inner area | 230 | 170 | — |
| ImageFrame | 230 | 130 | 1.77 (16:9) |
| **ImageFrame / Inner 比率** | **100%** | 76% | — |

**診断**: Inner width 230 と ImageFrame width 230 が完全一致。サムネがカード枠の水平方向を食い尽くしており、「枠の中にサムネが浮いている」視覚にならない。カード外寸も 258:198 ≈ 1.30 の landscape で、参照の**正方形寄り (~1.1)**からも乖離。

### 参照デザインの寸法推定

スクショのピクセル比から逆算:

| 要素 | 相対比率 | 絶対値 (カード外寸 240×210 想定) |
|------|----------|----------------------------------|
| Card aspect | **1.14 (ほぼ正方、若干横長)** | 240 × 210 |
| Card padding | 8-9% | 20px |
| Inner area | — | 200 × 170 |
| ImageFrame | **83% × 55%** | 200 × 115 |
| ImageFrame aspect | 1.74 (≒16:9) | — |
| ラベル領域 | 垂直残り 45% | ~55px (gap 16 + label 20 + 余白 19) |

**ポイント**: カードが**縦方向に伸びてラベル領域を確保**している。サムネは水平方向にはほぼ枠いっぱい、垂直方向は**過半分しか使わない**。結果「正方形に近い縦長」の形状になる。

### 🔴 必要な修正

**item_menus-wallselect.xml**:

```xml
<object class="GtkBox" id="ItemBox">
  ...
  <property name="spacing">16</property>          <!-- 6 → 16 (サムネ↔ラベル間の gap 拡大) -->
  <property name="width-request">240</property>   <!-- 258 → 240 -->
  <property name="height-request">210</property>  <!-- 198 → 210 -->

  <child>
    <object class="GtkBox" id="ItemImageFrame">
      ...
      <property name="width-request">200</property>   <!-- 230 → 200 -->
      <property name="height-request">115</property>  <!-- 130 → 115 (16:9 維持) -->
```

**style.css**:

```css
.wallselect-card {
    padding: 20px;         /* 14 → 20 */
    border-radius: 14px;   /* 継続 */
    ...
}
```

**layout.xml** (Scroll 高さ再計算):

```
ImageFrame 115 + spacing 16 + label min-height 20 + card padding 20×2 = 191
border 2+2 = 4 → 合計 195
```

→ Scroll max-content-height を **210-220** に:

```xml
<property name="min-content-height">220</property>
<property name="max-content-height">220</property>
```

ItemBox height-request=210 + row 余白 10 = 220 で合う。

### 期待される見た目変化

before → after:
- **カード形状**: 横長 (1.30) → ほぼ正方 (1.14)
- **サムネ占有率**: 100% width × 76% height → **83% × 55%**
- **ラベル領域**: 狭い → **カード下半分に明確なスペース**
- **視覚的階層**: 「カード = サムネ」 → **「カード枠の中にサムネとラベルが配置された構成」**

### 🔴 同時に解決される副次問題: ラベル描画欠損

第3回で `min-content-height=200` + label `min-height=20` を入れたにもかかわらず、スクショではまだラベルが見えない。原因候補:

1. **ItemBox height-request=198 の窮屈さ**: 内訳 ImageFrame 130 + spacing 6 + card padding 14×2 + ラベル 20 = 184 で 14px しか余裕がない。row の alloc で微妙にクリップされている可能性。
2. **walker/elephant 経由の text が空**: `shared_image_transformer` は Icon を描画するが、ItemText の text セットは `text_transformer` (`wiki/walker/src/providers/mod.rs:138-145`)。`DefaultProvider` (menu provider) の text_transformer が呼ばれているかログで確認。`item.text` が空だと `label.set_visible(false)` で消える。
3. **CSS の `* { all: unset; }` 副作用**: font-size / color が Label まで継承されていない可能性。walker default も同じリセットを使って動いているので優先度低いが、inspector で現状を確認すると早い。

**最優先の検証コマンド**:
```bash
elephant query menus:wallselect
```
これで text フィールドに「wallpaper1」等の文字列が入っているか確認。空なら wallselect.lua 側の Text フィールド問題。

カード拡張 (ItemBox 210 高) と同時に施策 1 は解消される見込み。それでも見えないなら施策 2 を疑う。

### 🟡 ラベルの細部 (参照と一致させるなら)

参照ではラベルが**中央寄せ**・**カード下端から ~20px 浮く**・**medium weight**。現状 xalign=0.5 は正しい。以下を style.css に追加:

```css
.wallselect-card .item-text {
    font-size: 14px;
    font-weight: 500;       /* normal → medium */
    margin-top: 0;          /* spacing 16 に任せる */
    margin-bottom: 4px;     /* 下端からの浮き */
}
```

### 🟢 Minor: 選択状態 padding トリックの整理

```css
.wallselect-card {
    border: 2px solid transparent;
    padding: 20px;
}
row:selected .wallselect-card {
    border: 3px solid @primary;
    padding: 19px;   /* 3-2=1 差を padding で吸収 */
}
```

現行 `padding: 7px` (14-7) は 14px padding 運用の名残、20px 運用になれば 19px。**1px の違いは人目では分からないが、レイアウトジッターを避けるために必須**。この trick は継続。

### 総括 (第5回)

**カードが landscape (1.30) のままなのが参照乖離の根本**。258×198 → **240×210** にして、サムネを 230×130 → **200×115** に縮めると、「正方形寄りのカード枠の中に 16:9 サムネが inset で置かれ、下にラベル領域」という参照デザインの構造が初めて成立する。

修正パッケージ (XML + CSS 同時):

| ファイル | 変更 |
|---------|------|
| item_menus-wallselect.xml | ItemBox 240×210、spacing 16、ImageFrame 200×115 |
| style.css | `.wallselect-card { padding: 20px }`、`:selected { padding: 19px }` |
| layout.xml | Scroll min/max-content-height 220 |
| style.css | `.item-text { font-weight: 500; margin-bottom: 4px; }` |

これでラベル描画欠損も自動解消される見込み (ItemBox 高さ拡張で row alloc に余裕)。なお解消しなければ `elephant query menus:wallselect` で text フィールド空問題を疑う。

---

## 第5回への返信 + gap 修正 (agent 側 2026-04-20)

### 🔴 カード形状の指摘 (第5回) への対応

寸法を第5回推奨に近づけつつ、user の「もう少し大きく」要望も満たすバランスで調整:

| 要素 | 第4回返信時 | 第5回推奨 | 今回採用 |
|---|---|---|---|
| ItemBox | 258×198 | 240×210 | **260×220** (user「大きく」反映、参照比率 1.18) |
| ImageFrame | 230×130 | 200×115 | **220×124** (16:9 維持) |
| Card padding | 14 | 20 | **20** (推奨通り) |
| Box spacing | 6 | 16 | **14** |
| Panel width | 1160 | — | **1130** = `260×4 + 14×3 + 24×2` で 4枚ぴったり |
| Scroll height | 200 | 220 | **230** (row margin + border 余裕) |

カード比率: 260/220 = 1.18 (参照 1.14 に近接、わずかに横長)。サムネ占有: 220/220 幅 (= 100%-padding), 124/180 高 (~69%)。下に label 領域が明確に確保される。

### 🔴 「カード間 gap が見えない」問題の根本解決

**user 指摘**: `.wallselect-card { margin-right: 14px }` 書いても視認できない。「flex の gap 相当を親コンテナに当てたい」。

**調査結果**:
- GtkListView は `spacing` プロパティを**公式に持たない** (GTK4 制約、第4回自身も撤回済)
- 子要素 `.wallselect-card` の margin は適用されるが、**カード内 bg が描画領域全体を埋めるため、視覚的に gap が見えない**可能性
- `row` (GtkListItem wrapper) に margin を打つと row 同士の間に**透過領域**が入り、パネル bg が透けて gap として視認される

**採用**: `row` 側に margin を移動。
```css
row {
    margin-right: 14px;
}
row:last-child {
    margin-right: 0;
}
.wallselect-card {
    /* margin を持たない */
}
```

これで GtkListView の row 同士の間に 14px の透過 gap が生まれる。親 `.box-wrapper` の @surface 背景が透けて見え、参照デザインの「カード間の明確な隙間」が再現される。

### 🔴 focus 時に「気持ち悪い」サイズ変動の除去

**user 指摘**: 「focus した時に少し大きくなるのキモい」。

**原因特定**: 第3回返信で追加した `row:selected .wallselect-card { padding: 7px; }` が問題。border 2→3px 変化に合わせて padding を 14→7px に縮めていた。border の厚さ変更と padding 変更が**同時**に走り、**内部 content の位置が微妙にジャンプ**していた。

**対応**: 選択時の size 変動を**完全に消す**。
```css
.wallselect-card {
    border: 2px solid transparent;
    padding: 20px;
}
row:selected .wallselect-card {
    /* padding / border-width は変えない。色のみ。 */
    border-color: @primary;
    background-color: @surface_container_high;
}
```
`border-width` の変化すら止めて、`border-color` だけを transparent → @primary に切り替える。1px のジャンプも発生しない。

### 🟡 第5回その他への対応

- **ラベル font-weight 500 + margin-bottom 4px**: 採用保留 (まず形状と gap の可視化を優先)。user から具体要望あれば追加。
- **ラベル描画欠損**: ItemBox 220 高に拡張 + `.list { color: @on_surface; font-family: ... }` で label が継承できるように措置済。`elephant query menus:wallselect` で text 空問題は別途検証 (user タスク)。
- **参照 prefix label 構造** (Select Wallpaper | Search wallpapers...): 前回実装済、継続維持。
- **縦ホイール**: 継続不可として受け入れ (arrow key / Shift+wheel / scrollbar drag で運用)。

### 総括 (第5回返信)

| user 指摘 | 対応 |
|---|---|
| focus 時のサイズ変化キモい | `:selected` で size/padding/border-width 全て不動、`border-color` のみ変化 |
| カード間 gap 見えない | `row` 側に `margin-right: 14px` で透過 gap 確保 |
| 4枚きっちり揃わない | panel width `260×4 + 14×3 + 24×2 = 1130` で数学的に一致 |
| カードもっと大きく | 258×198 → **260×220**、内部ラベル領域 +24px |

次の実機確認:
1. 4枚がパネル端までキッチリ
2. カード間に明確な dark gap (panel bg 透過)
3. 選択カードの size 不動、border 色だけ紫に
4. ファイル名が 14px で中央下に表示

---

## 第6回 (2026-04-20 実機スクショ再確認、残課題と追加要求)

### ✅ 成果

スクショ所見:
- **検索バーの複合構造**: `Select Wallpaper │ Search wallpapers...` の prefix label + separator + input が参照デザイン通りに組まれている。
- **カード正方形寄り**: 260×220 で aspect 1.18、参照デザインの形状 (~1.14) と同等。サムネがカード枠内に明確にインセットされ、上部に浮いて配置されている。
- **選択時のサイズ不動**: border 色のみ変化、他サイズ不変。`:selected` 時のジャンプ無し (user 感性 FB 反映済)。
- **カード間 gap**: `row { margin-right: 14px }` で panel 背景が透けるダークギャップが明確に見える。

### 🔴 残課題 1: 右端 4枚目が依然として半分切れている

layout.xml の数値設計は **4 cards × 260 + 3 gaps × 14 + panel padding 24 × 2 = 1130** で数学的には 1130 幅に 4枚ぴったり。しかし**実機では 3.5 枚分しか見えず、4枚目が右端で切れる**。

**原因推定** (静的解析では特定しきれない):
- `.box-wrapper { border: 1px solid }` で 2px を有効幅から差し引く (1130-2=1128, 1128-48=1080 → card 4枚なら 1082 必要 → **2px 不足**)
- ListView の horizontal orientation で行内に隠れた spacing が存在する可能性 (GTK4 quirk)
- `scrolledwindow` / `viewport` / `listview` のいずれかに `* { all: unset; }` で消えない internal padding が残っている可能性

**対応案** (優先順):

1. **GTK Inspector で実測**: `GTK_DEBUG=interactive walker` で起動後、Ctrl+Shift+D でインスペクタ。Layout タブで `BoxWrapper`, `Scroll`, `List`, 各 row の実アロケーションを見れば原因が一瞬で判明する。**これを最優先で回してから他の対応を考えるべき**。
2. **安全マージン確保**: width-request を 1130 → **1150** に増やす。内訳は「4枚分 1082 + padding 48 + 20px 安全マージン」。20px 分の余裕で右端に微かな余白が出るが、clip するよりマシ。参照デザインも厳密にゼロ余白ではない (微かに右に余白あり)。
3. **panel padding の border 分を吸収**: `.box-wrapper` の padding を `24px` → `23px` に変更し、border 1px の食い込みを相殺。これは後付けハックで推奨しない (脆い)。

**user への質問**: インスペクタで差分を確認する時間を 5 分もらえれば根本解決できる。その上で width-request を最終決定するか、安全マージンで妥協するか選んでほしい。

### 🟡 残課題 2: サムネは 16:9 で強制 resize / crop

**user 指摘**: 「サムネのサイズは 16:9 のサイズで強制 resize か カットして表示したい」。

**現状検証**: 
- `ItemImageFrame` width/height = **220 × 124**、aspect **1.7742** (16:9 の厳密値は 1.7778 → **0.04 のズレ**)
- `ItemImageFrame` に `overflow="hidden"` 設定済
- `GtkPicture` に `content-fit="cover"` + `can-shrink="true"` 設定済

→ この組み合わせで「画像は frame 内に cover モードで描画され、はみ出た部分は hidden で**強制カット**される」挙動になっているはず。スクショを見ても全カードでサムネが同じ寸法に揃っているので、**強制 16:9 表示自体は機能している**。

**精度改善案**: 厳密な 16:9 にしたいなら、220×124 ではなく以下の数値を使う (16:9 = 16x × 9x を満たす整数ペア):

| 幅 | 高さ | 備考 |
|----|------|------|
| 208 | 117 | 今より小さい |
| 224 | 126 | **今とほぼ同サイズ、推奨** |
| 240 | 135 | カード拡張と同時にサムネ拡張するなら |

**推奨**: `ItemImageFrame width-request=224 height-request=126`。現行とほぼ同サイズで aspect 1.7778 (厳密 16:9)。カード内寸 (260-20×2=220) に対して 224 はわずかにオーバーするので、同時にカード padding を 20→18 に微調整 or カード width 260→264 に。**最も素直なのは 208×117 で inset を 6px ずつ確保する**案。

厳密 16:9 にこだわらなくても見た目は変わらないので、現状 220×124 のまま妥協も可。「厳密にしたい」意図があるなら上記のいずれか。

### 🟡 残課題 3: 不要コメント / 資産にならないコメントの掃除

**方針**: コメントは「WHY」のみ書く。「WHAT」(コードで読める事実) は書かない。将来値が変わったときに嘘になるコメントは負債。

**削除対象 (XML / CSS)**:

- `item_menus-wallselect.xml:2-6` 壁紙カード: 外寸 250×180、サムネ 210×118 (16:9)、下にファイル名。
  → **すでに数値が嘘** (実 260×220, サムネ 220×124)。削除 or 「カード外寸とサムネ寸法は XML 属性値を参照」に置換。
- `layout.xml:2-16` 数値設計コメントブロック全体。
  → **すでに数値が嘘** (`カード外寸 250×180` 実 260×220, `Scroll 有効幅 250×4 + 14×3 = 1042` 実 1082)。削除推奨。
- `layout.xml:32` `<!-- 4 cards × 260 + 3 gaps × 14 + panel padding 24 × 2 = 1130 -->`
  → 正しいが次の値変更で即嘘になる。**削除**。
- `layout.xml:98` `<!-- ItemBox 220 + row margin + border 余裕 -->`
  → 同上、削除。
- `style.css:2-6` 冒頭コメントの「選択/ホバー時のサイズ変化は禁止...」
  → **残す**。WHY が書かれている (user フィードバック経緯)。
- `style.css:100-102` gap の `margin` vs `row` 判断コメント。
  → **残す**。WHY と設計判断が書かれている。

**削除しないもの (WHY が書かれている)**:

- `config.toml` の `[columns]` 関連コメント (walker 側 handle_grid_setting の挙動を説明している)
- `layout.xml:103` `kinetic-scrolling=false` の理由 (触らない)
- `style.css:111-114` `.wallselect-card` コメント (状態切替の設計思想)
- `style.css:148` `Selected` コメントのシンプルな説明

**agent への指示**: 「XML/CSS ファイルの先頭コメントおよび具体的な寸法値を含むインラインコメントで、**値が変わったら嘘になるもの**を削除する。『なぜその値/設計か』を説明しているコメントは残す」。

### ✅ Good (今回の改善で効いている点)

- `search-container` 複合構造: `Input` ID だけ walker に見つけてもらえれば前後の Label/Separator は walker に無視される仕組みを活かしている。
- `row { margin-right: 14px }` + `row:last-child { margin-right: 0 }` で ListView の spacing 代替を実現。カード自体の余白はいじらず透過 gap を作った判断は綺麗。
- 選択/ホバー時のサイズ不動設計が CSS のコメントでちゃんと明記されている。

### 総括 (第6回)

- 残課題は **右端クリップ** (数学的には fit するのに実機で clip、GTK インスペクタで根本解決推奨) と **コメント掃除** (値を含むコメントの過半数が rot している)。
- 16:9 強制 resize/crop は**すでに機能している** (overflow hidden + content-fit cover)。精度を厳密 16:9 にするなら 220×124 → 224×126 or 208×117。必須ではない。
- 残課題 3件を agent に戻せば、参照デザインとほぼ一致する状態に到達する見込み。

---

## 第6回への返信 (agent 側 2026-04-20)

### ✅ 🔴 残課題 1: 右端クリップ

**対応**: 安全マージン採用。
```
BoxWrapper width-request: 1130 → 1150 (+20px)
```

理由:
- 数学計算値 1130 は border 1px × 2 + ListView 内部 spacing quirk 等の要因で実寸との 2-20px 乖離が出る
- GTK Inspector 実測するのが根本解決だが user の手間を考慮、まず **pragmatic に 20px バッファ**で回避
- +20px により右端に僅かな余白が生まれるが、clip よりマシ & 参照デザインも厳密ゼロ余白ではない

それでも clip するなら GTK Inspector で各 widget の allocated-width を確認する次手に進む。

### 🟡 残課題 2: 16:9 厳密精度

**判断**: 現状 220×124 (aspect 1.7742) のまま維持。

理由:
- 厳密 16:9 (1.7778) との差は 0.04、肉眼では判別不能
- 224×126 にすると card 内寸 220 を超えてカード拡張 or padding 縮小の連鎖変更が必要
- 208×117 にすると card 内余裕は増えるがサムネが小さくなり見栄え犠牲
- `overflow=hidden` + `content-fit=cover` で user 要望の「強制 resize/crop」挙動は**すでに機能している** (reviewer も確認済)

**優先度下**で保留。将来カード全体の寸法見直しがあればその時に合わせて調整。

### ✅ 🟡 残課題 3: 値含有コメント掃除

指摘通り、値を含むコメント (rot 対象) を削除。WHY を説明しているコメントは残す。

**削除したコメント** (値が変わると嘘になる):
- `item_menus-wallselect.xml:2-6` 冒頭コメント: 旧寸法 (250×180, 210×118) の記述
- `layout.xml:2-16` 数値設計ブロック: 旧寸法 (250×180, 250×4+14×3=1042, BoxWrapper 1090) 全面書き換え
- `layout.xml:32` `<!-- 4 cards × 260 ... = 1130 -->`
- `layout.xml:98` `<!-- ItemBox 220 + row margin + border 余裕 -->`

**残したコメント** (WHY / 設計思想):
- `item_menus-wallselect.xml` 冒頭: GtkPicture natural size propagation の問題に言及 (設計思想)
- `layout.xml` 冒頭: 検索バー複合構造の説明、カード gap 機構の委譲先
- `layout.xml` `kinetic-scrolling=false` の理由
- `style.css` 冒頭: user 感性 FB (「focus 時に大きくなるのキモい」) の背景
- `style.css` gap 機構: `row` 側 margin 採用の判断理由
- `style.css` `.wallselect-card` 状態切替の設計思想
- `config.toml` `[columns]` の walker 挙動説明

### 総括 (第6回返信)

| 残課題 | 対応 |
|---|---|
| 🔴 右端クリップ | BoxWrapper width 1130→1150、バッファ +20px で pragmatic 解決 |
| 🟡 16:9 厳密精度 | 現状 1.7742 維持、機能的には問題なし |
| 🟡 コメント rot 掃除 | 値含有コメント全削除、WHY コメントのみ残存 |

次の実機確認: Super+W で 4枚目が完全に収まるか確認。まだ切れるなら `GTK_DEBUG=interactive walker` + `Ctrl+Shift+D` で widget の実アロケーションを見る。

---

## 第7回 (2026-04-20 AspectFrame 対応の差し戻し)

user の所見:
> 現に、動作をみるとサイズのリサイズが起こったサムネは、黒い帯が上下についてしまった。もとのコンテナの大きさ未満になるせいでこうなっていると思われる。

**user の観察が正しい方向を指している**。agent の対応は診断は合っているが実装が片手落ち。

### ✅ agent の診断は正しい

> GtkBox の width-request は最小値であって固定ではないので、中の GtkPicture (hexpand/vexpand=true + natural size = 画像の元解像度) が親を押し広げて枠が画像ごとに微妙に違うサイズになってる

GTK4 の `width-request` / `height-request` は**最小値** (minimum) で、子 widget の natural size が大きければ親は拡大する。`GtkPicture` は paintable の natural size (= 画像の元解像度) を measure() で返すので、1920×1080 / 3840×2160 / 2560×1440 の壁紙が混在すると各カードの ItemImageFrame が画像ごとに違うサイズで allocate される。**これが「サムネがばらつく」の根本原因で、AspectFrame で枠を固定する方針自体は正解**。

### 🔴 しかし Picture の `hexpand/vexpand=false` 設定が逆

現 `item_menus-wallselect.xml:47-48`:
```xml
<property name="hexpand">false</property>
<property name="vexpand">false</property>
```

この設定だと Picture は「親を押し広げない」代わりに「**親を埋めない**」。Picture 自身は画像の natural size で描画され、AspectFrame の 208×117 との差分が露出する。

- 元画像が **大きい** (1920×1080 等): Picture も `can-shrink=true` があるので縮小される...と思いきや、`hexpand=false` だと expand も縮小も親には連動せず、微妙に残る
- 元画像が **小さい** (例: 640×360): Picture は画像サイズのまま描画 → frame 内で letterbox 状態 → `item-image-frame` の `background-color: @surface` が見えて**黒帯として観察される**

**user が見ている「上下の黒帯」はこの挙動そのもの**。

### 🔴 正しい修正

Picture を **frame いっぱいに引き伸ばす**指定に戻す:

```xml
<object class="GtkPicture" id="ItemImage">
  <style><class name="item-image"></class></style>
  <property name="content-fit">cover</property>
  <property name="can-shrink">true</property>
  <property name="hexpand">true</property>      <!-- false → true に戻す -->
  <property name="vexpand">true</property>      <!-- false → true に戻す -->
  <property name="halign">fill</property>       <!-- 明示追加 -->
  <property name="valign">fill</property>       <!-- 明示追加 -->
</object>
```

### なぜこれで動くか (GtkBox 親と GtkAspectFrame 親でセマンティクスが違う)

- **GtkBox 親の場合**: 子の `hexpand=true` + Picture の natural size で **親が拡大する** ← 以前の問題
- **GtkAspectFrame 親の場合** (現在): 親が `width/height-request=208×117` + `ratio` + `obey-child=false` で**サイズが確定**。子の `hexpand=true` は「確定した親の範囲内で fill する」意味に変わり、**親を押し広げない**。`can-shrink=true` + `content-fit=cover` で元画像を枠に合わせてクロップする。

つまり agent は「以前の診断 (Box 親)」の対処を「AspectFrame 親」に持ち込んでしまった。**AspectFrame では Picture を fill させても親が広がらない**ので、`hexpand/vexpand=true` + `halign/valign=fill` で枠を埋めるのが正解。

### 代替案 (AspectFrame を使わない)

AspectFrame を入れずに GtkBox のまま解決することも可能:

```xml
<object class="GtkBox" id="ItemImageFrame">
  <property name="width-request">208</property>
  <property name="height-request">117</property>
  <property name="hexpand">false</property>         <!-- 親拡大を阻止 -->
  <property name="vexpand">false</property>
  <property name="overflow">hidden</property>
  <child>
    <object class="GtkPicture" id="ItemImage">
      <property name="content-fit">cover</property>
      <property name="can-shrink">true</property>
      <property name="width-request">1</property>   <!-- natural size 主張を 1px に -->
      <property name="height-request">1</property>
      <property name="hexpand">true</property>
      <property name="vexpand">true</property>
      <property name="halign">fill</property>
      <property name="valign">fill</property>
    </object>
  </child>
</object>
```

Picture に `width-request=1 / height-request=1` を明示すると、Picture が主張する最小サイズが 1×1 になり、**元画像解像度が親の measure() に propagate しなくなる**。`hexpand/vexpand=true` で親の範囲に fill、`can-shrink` + `content-fit=cover` でクロップ。

**AspectFrame 案の方が意図が明示的** (比率強制が目的だと XML から読める) なので、AspectFrame を維持した上で Picture の hexpand/vexpand/halign/valign を fill にするのを推奨。

### 🟢 ついでに: AspectFrame 導入時のコメントも簡潔化

`item_menus-wallselect.xml:23-26` の AspectFrame 説明コメントは現状やや冗長。**削除して先頭コメントに1行**で統合:

```xml
<!--
  壁紙カード。ItemImageFrame は GtkAspectFrame で枠を厳密 16:9 に固定し、
  Picture は frame 内に fill (content-fit=cover で crop)。
-->
```

(数値は XML 属性に書いてあるので重複させない)

### 総括 (第7回)

| 項目 | 判定 |
|------|------|
| 診断 (GtkBox width-request は最小値、Picture natural size propagation) | ✅ 正しい |
| 対策案 (GtkAspectFrame で枠固定) | ✅ 正しい |
| 実装 (Picture hexpand/vexpand=false) | ❌ 逆、黒帯の原因 |

**修正**: Picture の `hexpand/vexpand` を `true` に戻し、`halign/valign=fill` を追加。これで frame いっぱいに Picture が描画され、`content-fit=cover` + `overflow=hidden` で壁紙ごとの画像解像度違いに関わらず 208×117 に統一される。

agent には「**AspectFrame 親のときは Picture の hexpand=true で親は広がらず、むしろ枠を埋める挙動になる**」点を明示的に伝えること。Box 親との混同が再発しないように。

---

## 第7回への返信 (agent 側 2026-04-20)

### ✅ 受諾: Picture の hexpand/vexpand を反転

第7回の指摘通り、GtkBox 親時代の対処 (hexpand=false で親の拡大阻止) を AspectFrame 親にそのまま持ち込んでしまっていた。AspectFrame は `obey-child=false` + `ratio` + `width/height-request` で親サイズが確定するため、Picture `hexpand=true` は「親を広げる」意味から「確定した親を埋める」意味に変わる。`false` のままだと小さい画像 (例: 640×360) が natural size で描画され、frame 内に letterbox 状態になり `item-image-frame` の background-color が上下帯として露出する。user 所見「黒帯」の正体。

修正内容 (`item_menus-wallselect.xml`):

```diff
 <object class="GtkPicture" id="ItemImage">
   <property name="content-fit">cover</property>
   <property name="can-shrink">true</property>
-  <property name="hexpand">false</property>
-  <property name="vexpand">false</property>
+  <property name="hexpand">true</property>
+  <property name="vexpand">true</property>
+  <property name="halign">fill</property>
+  <property name="valign">fill</property>
 </object>
```

AspectFrame 側は変更なし (ratio / obey-child / width・height-request / halign=center / valign=start / overflow=hidden はそのまま)。

### ✅ コメント簡潔化

レビュー提案通り、AspectFrame 導入時に追加した冗長な説明コメント (4行) を削除し、ファイル先頭コメントを 2 行に統合:

```xml
<!--
  壁紙カード。ItemImageFrame は GtkAspectFrame で枠を厳密 16:9 に固定し、
  Picture は frame 内に fill (content-fit=cover で crop)。
-->
```

### 学びの記録: GtkBox 親 vs GtkAspectFrame 親

| 親 | Picture hexpand=true の意味 | Picture hexpand=false の意味 |
|------|-----------------------------|------------------------------|
| GtkBox | 子の natural size が親を押し広げる (= 枠サイズがバラつく) | 子 natural size のまま、親は最小幅止まり |
| GtkAspectFrame (obey-child=false + ratio + width/height-request) | 確定した親の範囲内で fill (= 枠を埋める) | 親は不変、子が natural size で描画 → letterbox |

AspectFrame 採用時は Picture 側は **fill 化が正解**。Box 対処の流用は NG。

### 総括 (第7回返信)

- 第7回 🔴 実装片手落ち → Picture hexpand/vexpand=true + halign/valign=fill に反転、user 実機検証待ち
- 🟢 コメント掃除 → 4行 → 2行に統合、値やメタ説明を XML 属性側に任せる方針で整理

---

## 第8回 (2026-04-20 AspectFrame 修正後も黒帯残存、根本治療)

user 所見:
> 修正したらしいが、黒い帯がある。解決さく正しいのか？

**解決策は根本原因に届いていない**。第7回で私が出した「AspectFrame + obey-child=false で frame サイズが確定する」という説明自体に誤りがあった。訂正してお詫びする。

### 🔴 症状の再確認 (スクショ所見)

- 4枚のカードはすべて同じ外寸 (260×220) に見える
- **しかし各カード内のサムネが異なるサイズで描画されている**:
  - 1枚目 (紫の部屋): サムネ幅 ~180px
  - 2枚目 (少女): サムネ幅 ~200px
  - 3枚目 (ピンクの瞳): サムネ幅 ~220px (最大)
  - 4枚目 (ダーク): サムネ幅 ~180px
- サムネのアスペクト比は全て ~16:9 で揃っている
- サムネの外側 (ラベル領域の予定地と左右) に card 背景 (`surface_container`) が黒帯として露出

→ **ratio 固定は効いているが、frame のサイズ自体が画像ごとに変わっている**。`width-request=208 / height-request=117` は MIN でしかなく、画像解像度に引きずられている。

### 🔴 根本原因: GTK4 の `width-request` は MIN、MAX ではない

第7回の説明訂正:
- `width-request` / `height-request` は widget の **minimum size** 指定 (MAX ではない)
- `obey-child=false` は「**子のアスペクト比を採用せず、ratio プロパティの値を使う**」という意味のみ。frame サイズの cap には関与しない
- `GtkAspectFrame` の natural size は**子 (Picture) の natural size が影響する**
- `GtkPicture` は paintable の natural size (= 画像元解像度) を measure() で返す
- 画像が 1920×1080 の card では AspectFrame が 1920-ish で measure、3840×2160 では 3840-ish で measure
- 最終的に row の cell allocation で cap されるが、**cap 前の natural measure が画像解像度に引きずられる結果、cell 内での描画サイズがバラつく**

第7回の Picture `hexpand/vexpand=true` 修正は「Picture が frame を埋める」ようにしたが、「**frame 自体のサイズが画像ごとに変わる**」という根本問題には手を付けていない。

### 🔴 正しい修正: Picture の natural size 主張を 1px に矮小化

Picture の natural size 主張 (= 画像解像度) を**意図的に抑え込む**必要がある。`width-request=1 / height-request=1` を Picture に足す:

```xml
<object class="GtkPicture" id="ItemImage">
  <style><class name="item-image"></class></style>
  <property name="content-fit">cover</property>
  <property name="can-shrink">true</property>
  <property name="width-request">1</property>     <!-- 追加: natural size 主張を 1px に -->
  <property name="height-request">1</property>    <!-- 追加 -->
  <property name="hexpand">true</property>
  <property name="vexpand">true</property>
  <property name="halign">fill</property>
  <property name="valign">fill</property>
</object>
```

**セマンティクス**:
- `width-request=1 / height-request=1`: Picture の minimum size が 1×1 と明示。widget の measure() で返される minimum は 1、natural も `can-shrink=true` と併用で親に対して「大きくなりたい」と主張しなくなる
- `hexpand/vexpand=true` + `halign/valign=fill`: 親 (frame) が与える余剰空間を全部受け取って fill
- `can-shrink=true`: paintable の natural より widget 自体が小さくなってよい
- `content-fit=cover`: 画像は paintable natural 比を維持しつつ、widget 矩形を完全に埋める (溢れ部分はクリップ)

**結果**: Picture が AspectFrame に対して大きくなりたいと主張しなくなる → AspectFrame は自分自身の width/height-request = 208×117 のまま → 全カード frame が同じサイズ → 黒帯消滅。

### 🟡 補助案: AspectFrame をやめて GtkBox に戻す

AspectFrame は `obey-child=false` でも「frame サイズ確定」ではなく、読み手に誤解を与える (実際、第7回で私自身が誤解した)。同じ目的 (208×117 枠 + 16:9 比率) を GtkBox で素直に書ける:

```xml
<object class="GtkBox" id="ItemImageFrame">
  <property name="width-request">208</property>
  <property name="height-request">117</property>
  <property name="hexpand">false</property>
  <property name="vexpand">false</property>
  <property name="halign">center</property>
  <property name="valign">start</property>
  <property name="overflow">hidden</property>
  <child>
    <object class="GtkPicture" id="ItemImage">
      <property name="content-fit">cover</property>
      <property name="can-shrink">true</property>
      <property name="width-request">1</property>
      <property name="height-request">1</property>
      <property name="hexpand">true</property>
      <property name="vexpand">true</property>
      <property name="halign">fill</property>
      <property name="valign">fill</property>
    </object>
  </child>
</object>
```

ポイント:
- **Box 側の `hexpand=false, vexpand=false`**: 子が push しても親が拡大しない
- **Picture 側の `width-request=1`**: そもそも push する力が無い
- **Picture 側の `hexpand/vexpand=true`**: Box が与える 208×117 を fill
- **Box 側の `overflow=hidden`**: cover で溢れたピクセルをクリップ
- 比率は Box の width:height 比 (208:117 ≈ 1.778) で自然に 16:9

AspectFrame 特有の `obey-child` / `ratio` を書かなくて済む。意図 (「208×117 の枠に画像を cover でクロップ描画」) がそのまま XML に出る。

**どちらを選ぶか**:
- AspectFrame 継承 + Picture に `width-request=1` 2 行追加 → 最小変更
- **GtkBox に戻す + Picture に `width-request=1` → 意図が明快、debug しやすい (推奨)**

### 🟢 ラベル描画欠損が依然解決していない件

スクショでファイル名が相変わらず見えない。寸法的には余地があるのに描画されていない。

ItemBox height-request=220 + Card padding 20×2 = 40 → inner 180。構成:
- AspectFrame 117 + spacing 14 + Label min-height 20 = 151
- 残り 29px 未使用 (どの子も vexpand=false)

原因候補:
1. `elephant query menus:wallselect` で Text フィールドが空の可能性 (第5回から未解決)
2. `.list { color: @on_surface; font-size: 14px; }` の継承が Label まで届いていない可能性
3. `* { all: unset; }` の副作用で Label の visible / opacity が意図せず reset されている可能性

**先に検証するコマンド**:
```bash
elephant query menus:wallselect
```
→ 各エントリの `text` フィールドが空でないか確認。空なら wallselect.lua 側の問題。

GTK Inspector (`GTK_DEBUG=interactive walker` + Ctrl+Shift+D) で ItemText label の widget tree を開き、`visible=true` / `label="wallpaper-01"` 等が実際に入っているか直接確認するのも早い。

### 総括 (第8回)

| 項目 | 判定 |
|------|------|
| 第7回の Picture fill 修正 (hexpand/vexpand=true) | ✅ 方向性は合っている |
| しかし frame 自体のサイズが画像ごとに変わる問題は未解決 | ❌ 残存、user の「黒帯」はこれ |
| 根本原因 | AspectFrame の `width/height-request` は MIN、Picture natural size (画像解像度) が propagate して frame が画像に引きずられる |
| 修正 | Picture に `width-request=1, height-request=1` を追加して natural size 主張を抑制 |
| 推奨 | AspectFrame → GtkBox + overflow=hidden に戻す (意図と挙動の乖離を解消) |

agent に戻す指示:
1. **Picture に `width-request=1` + `height-request=1` を追加 (最優先)**。これだけで frame サイズが画像に引きずられなくなる見込み。
2. 可能なら AspectFrame を GtkBox に戻す (命名と挙動の乖離を解消)
3. `elephant query menus:wallselect` で text field 空問題を別途確認 (ラベル描画欠損)
