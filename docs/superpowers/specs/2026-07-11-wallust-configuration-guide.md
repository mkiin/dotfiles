# wallust 設定ガイド（この環境向け・v3.5.2 前提）

壁紙から 16 色パレットを生成する **wallust** の設定方法を、この dotfiles の実態に即してまとめる。
インストール済みバイナリは nixpkgs 由来の **v3.5.2** で、`~/.config/wallust/wallust.toml` も v3 記法で書かれている。
ghq に置いた v4-alpha ソース（`explosion-mental/wallust`）はスキーマが別物なので、本ガイドは v3.5.2 のみを対象とする。

## この環境でのアーキテクチャ

色生成は **matugen** と **wallust** の二本立てで、両者は独立している。
matugen は Material Design 3 の意味色（primary、surface など）を担い、waybar・wlogout・hyprland・quickshell へ配る。
wallust は pywal 互換の 16 色 ANSI パレット（color0 から color15、background、foreground、cursor）を担い、wezterm・ghostty・pywal cache・waybar の一部へ配る。
両者が同じ壁紙を別の観点で読み、別のダウンストリームへ流す。

発火は pyprland の壁紙変更から始まる。
`home-manager/desktop/hyprland/scripts/wallpaper/post.sh` の `run_color_pipeline` が matugen と `wallust run "$img" --quiet` を並列に走らせ、その後 `notify_downstream` が waybar reload、全 ghostty への SIGUSR2、`hyprctl reload` を順に叩く。

```sh
spawn matugen matugen_with_fallback "$img" "$source_idx"
# wallust: matugen が出さない @color0..15 (Pywal 系) を waybar style 用に追加生成
spawn wallust wallust run "$img" --quiet
wait_all
```

wezterm だけはこのダウンストリーム通知に含まれない。
`wezterm.lua` が生成先の `colors/wallust.toml` を `add_to_config_reload_watch_list` で自前監視し、ファイル更新を検知して自動リロードするからである。
したがって wezterm 向けに post.sh 側で何かを送る必要はない。

生成先は `wallust.toml` の `[templates]` で決まっている。

```toml
[templates]
waybar = { template = "waybar.css", target = "~/.config/waybar/colors-waybar.css" }
ghostty = { template = "ghostty.conf", target = "~/.config/ghostty/themes/wallust" }
wezterm = { template = "wezterm.toml", target = "~/.config/wezterm/colors/wallust.toml" }
pywal = { template = "pywal-colors.json", target = "~/.cache/wal/colors.json" }
```

## wallust.toml のカスタム

現行の設定はトップレベルに次の 4 項目を持つ。

```toml
backend = "wal"
color_space = "lab"
check_contrast = true
saturation = 0
```

### backend

画像からピクセルをどう読むかを決める。
精度と速度のトレードオフで、v3.5.2 では次の値を取る。

- **full**：全ピクセルを読む。最も正確で最も遅い。
- **resized**：アスペクト比を保って縮小してから読む。
- **wal**：ImageMagick の `convert` を使う。pywal と同じ挙動で、現在この環境が選んでいる値。
- **thumb**：512×512 固定でクロップする。比率を無視して最速。
- **fastresize**：SIMD を使う高速な縮小。ただし一部の画像で `resized` が通るのに失敗することがある。
- **kmeans**：画像全体からクラスタで拾い、多様な色になりやすい。

現在の `wal` は ImageMagick に依存するぶん外部プロセスを一つ増やす。
依存を減らして速度を上げたいなら `fastresize`、色の多様さを優先するなら `kmeans` が候補になる。

### colorspace

抽出したピクセルをどの色空間で並べ替え、16 色に落とすかを決める。
設定キー名は `color_space` でも `colorspace` でも v3 は受けるが、CLI フラグは `-c/--colorspace` である。

- **lab**：CIE L\*a\*b\*。現在の設定値。
- **labmixed**：`lab` の派生で、集めた色を混ぜる。小さい画像では色数が足りず lab へ落ちるので推奨されない。
- **lch**：CIE Lch。lab に chroma と hue を足したもので、並べ替えの効きがよい。
- **lchmixed**：`lch` の混合版。
- **salience**：背景からどれだけ色が際立つか（salience）で区別する。Lch ベース。
- **lchansi**：黒・赤・緑・黄・青・マゼンタ・シアン・灰の 8 色を保つ Lch 派生。色の並び順が固定されるので `darkansi` パレットと相性がよい。

ターミナルで赤や緑の並びを安定させたいなら `lchansi`、壁紙の主役色を強く出したいなら `salience` が向く。

### check_contrast

前景色と背景色のコントラストを検査し、読めない組み合わせを避ける。
現在は `true`。
暗い壁紙で前景が沈んで読めないことが頻発しない限り、無効でも困らない項目である。

### saturation

パレット生成後に彩度を足し引きする。
現在は `0` で、実質的に無調整に近い。
色がくすむ壁紙で全体を鮮やかにしたいなら 40 から 60 あたりへ上げ、逆に落ち着かせたいなら小さめの値にする。
CLI では `wallust run <img> --check-contrast` のように多くのオプションが config を上書きできるので、値の当たりをつけるときはコマンドラインで試すとよい。

### 壁紙以外から色を作る

`wallust run` は画像を起点にするが、v3.5.2 には別経路のサブコマンドがある。

- **`wallust cs <file>`**：既存のカラースキームファイルを適用する。
- **`wallust theme <name>`**：組み込みテーマを適用する。`wallust theme --help` で一覧が出る。
- **`wallust pywal`**：pywal の drop-in 代替として振る舞う。

壁紙由来の色をやめて固定テーマに切り替えたい日は、post.sh を経由せず手元で `wallust theme` を叩けば、同じテンプレート群がそのテーマ色で再生成される。

## テンプレート生成の便利オプション

テンプレートは Jinja2 で書く。
変数をそのまま差し込むだけでなく、フィルタで色を派生させられるので、壁紙から一色だけ取り出して自分で明度や彩度を動かす調整ができる。

### 変数

`{{color0}}` から `{{color15}}`、`{{background}}`、`{{foreground}}`、`{{cursor}}` が基本の色変数で、既定では `#0A0B0C` 形式の HEX で出る。
このほか `{{wallpaper}}`（現在の壁紙パス）、`{{backend}}`、`{{alpha}}`（既定 100）、`{{alpha_dec}}`（0.00 から 1.00 表記）が使える。

### フィルタ

色変数やリテラル色に適用し、加工した色を返す。
複数を連ねて段階的に加工できる。

- **明度**：`{{ color0 | lighten(0.2) }}` / `{{ color0 | darken(0.2) }}`。引数は 0.1 から 1.0。
- **彩度**：`{{ color4 | saturate(0.3) }}`。
- **色相**：`{{ color4 | adjust_hue(30) }}`。度数で回す。360 で一周。
- **混色**：`{{ color2 | blend(color0) }}`。別の色を混ぜる。
- **補色**：`{{ color5 | complementary }}`。
- **書式変換**：`{{ color5 | hexa }}`（`#RRGGBBAA`）、`{{ color5 | rgb }}`（`10,11,12`）、`{{ color5 | strip }}`（先頭の `#` を落とす）、`{{ color5 | xrgb }}`（`0A/0B/0C`）。
- **成分取り出し**：`red` / `green` / `blue` と、その float 版 `redf` / `greenf` / `bluef`、float 版の rgb `rgbf`。
- **アルファ**：`{{ 100 | alpha_hexa }}` で `FF` を得る。`alpha` 変数と組み合わせて透過値を差し込める。

たとえば背景を少しだけ持ち上げた色をボーダーに使いたいなら、テンプレート内で `{{ background | lighten(0.15) }}` と書けば、wallust 側で色を増やさずに派生色を作れる。

## wezterm 側のカラー調整

wezterm は生成物 `~/.config/wezterm/colors/wallust.toml` を読み込んで配色に反映する。
テンプレートは 16 色に加え foreground、background、cursor を出している。

```toml
[colors]
foreground = "{{foreground}}"
background = "{{background}}"
cursor_bg = "{{cursor}}"
cursor_fg = "{{background}}"
ansi = [ "{{color0}}", ..., "{{color7}}" ]
brights = [ "{{color8}}", ..., "{{color15}}" ]
```

`wezterm.lua` 側の読み込みは次の形で、ファイルが無い初回や Windows では上の `color_scheme`（`Snazzy (base16)`）へフォールバックする。

```lua
local wallust_scheme = wezterm.config_dir .. "/colors/wallust.toml"
local wf = io.open(wallust_scheme, "r")
if wf then
  wf:close()
  local ok, palette = pcall(wezterm.color.load_scheme, wallust_scheme)
  if ok and palette then
    palette.tab_bar = config.colors.tab_bar
    config.colors = palette
    wezterm.add_to_config_reload_watch_list(wallust_scheme)
  end
end
```

ここで `palette.tab_bar = config.colors.tab_bar` が効いている。
`load_scheme` は `config.colors` を丸ごと差し替えるので、先に設定した `tab_bar.background = "none"` が消える。
それを退避して書き戻すことで、壁紙色を採り込みつつタブバーの透過だけ独自値のまま保っている。
同じ理屈で、壁紙由来にしたくない項目があれば `load_scheme` の後に上書きすればよい。

```lua
config.colors = palette
palette.tab_bar = config.colors.tab_bar
config.colors.cursor_bg = "#ffffff"  -- カーソルだけ壁紙非依存にする例
```

特定の色を壁紙から生成させたくないなら、wezterm 側で上書きするほかに wallust 側で止める手もある。
`wallust run <img> -I cursor` のように `-I/--ignore-sequence` を渡すと、その色のシーケンス送出をやめる。
恒久的に固定したい色があるなら、この経路とテンプレートのハードコードを併用する。

`window_background_opacity = 0.9` は wallust の色とは独立で、背景色の上に別途かかる透過である。
壁紙が明るくて背景が薄く見えるときは、パレットの `background` を暗くするのではなく opacity を下げるほうが素直に効く。
両者を混同すると調整が噛み合わなくなる。

## Nix での配線

wallust 関連ファイルはすべて `home-manager/desktop/wallust/` にコロケーションし、`default.nix` が `xdg.configFile` で `~/.config/wallust/` へリンクする。

```nix
xdg.configFile = {
  "wallust/wallust.toml".source = lnk ./wallust.toml;
  "wallust/templates/waybar.css".source = lnk ./templates/waybar.css;
  "wallust/templates/ghostty.conf".source = lnk ./templates/ghostty.conf;
  "wallust/templates/wezterm.toml".source = lnk ./templates/wezterm.toml;
  "wallust/templates/pywal-colors.json".source = lnk ./templates/pywal-colors.json;
};
```

テンプレートを一つ足すときは、`templates/` にファイルを置き、`xdg.configFile` に一行足し、`wallust.toml` の `[templates]` に `template` と `target` を書く、の 3 点を揃える。
wallust バイナリ本体は集約 `home-manager/desktop/packages.nix` で宣言済みなので、この設定ディレクトリにパッケージを書き足してはならない。

テンプレートは Jinja2 や CSS の構文で、Nix や nixfmt の整形対象にすると壊れる。
そのため `lib/treefmt/default.nix` が `*/wallust/templates/*` を除外している。
新しいテンプレートも同じ配下に置けば自動で除外に乗る。

初回ブートでは wallust がまだ走っておらず、waybar と wlogout が共有する `colors-waybar.css` が存在しない。
`fallbackWaybarColorsWallust` activation が、無ければ同梱のフォールバックを置いて `@import` の失敗を防ぐ。

```nix
home.activation.fallbackWaybarColorsWallust = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  t="$HOME/.config/waybar/colors-waybar.css"
  [ -e "$t" ] || $DRY_RUN_CMD install -Dm644 ${./fallback/colors-waybar.css} "$t"
'';
```

反映は他の home-manager 設定と同じく `nix run .#switch`（実機 NixOS）で、テンプレートやリンクの変更はこれで届く。
`wallust.toml` を変えた効果を見るには、その後で壁紙を切り替えて post.sh を走らせるか、手元で `wallust run <img>` を一度叩く。

## 調整レシピ

- **暗い壁紙で前景が読めない**：`check_contrast = true` を維持しつつ、それでも沈むなら `saturation` を上げるか、テンプレート内で `{{ foreground | lighten(0.2) }}` を使う。
- **色がくすむ**：`saturation` を 40 から 60 へ上げる。効きすぎたら colorspace を `lch` にして並べ替えの精度を上げる。
- **ターミナルの赤緑青の並びを安定させたい**：`colorspace = "lchansi"` にする。ANSI の色位置が固定される。
- **速度を上げたい**：`backend` を `wal` から `fastresize` か `thumb` へ。ImageMagick 依存も外れる。
- **特定色だけ壁紙非依存にする**：`wallust run <img> -I <color>` で送出を止め、wezterm やテンプレート側でその色をハードコードする。
- **今日は固定テーマにしたい**：`wallust theme <name>` を手元で叩けば、同じテンプレート群がテーマ色で再生成される。
