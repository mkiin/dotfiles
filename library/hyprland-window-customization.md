# Hyprland ウィンドウ見た目カスタマイズ網羅リスト

Hyprland のウィンドウ外観に関わる設定キーをブロックごとに整理した一覧。
出典は公式 wiki と `wiki/` 配下のサンプル dotfiles。
ユーザー現状値は `/home/mkiin/dotfiles/home/dot_config/hypr/appearance/*.conf` および `/home/mkiin/dotfiles/home/dot_config/hypr/rules.conf` から拾っている。

## 目次

- [general (枠線・ギャップ・レイアウト)](#general)
- [general:snap (フローティング・スナップ)](#generalsnap)
- [decoration (角丸・透明度・dim)](#decoration)
- [decoration:blur (背景ぼかし)](#decorationblur)
- [decoration:shadow (ドロップシャドウ)](#decorationshadow)
- [decoration:glow (内側グロー)](#decorationglow)
- [animations (アニメーション全般)](#animations)
- [animation tree (利用可能ターゲット)](#animation-tree)
- [bezier (カスタムカーブ)](#bezier)
- [group / group:groupbar (グループバー)](#group)
- [misc (壁紙・ロゴ・swallow 等)](#misc)
- [layout (シングルウィンドウ)](#layout)
- [dwindle (ダブル分割レイアウト)](#dwindle)
- [master (マスター/スレーブ)](#master)
- [xwayland (XWayland スケール)](#xwayland)
- [render (描画・直接スキャンアウト)](#render)
- [cursor (カーソル可視性)](#cursor-appearance)
- [windowrule props (マッチ条件)](#windowrule-props)
- [windowrule effects (見た目に効くもの)](#windowrule-effects)
- [layerrule (バー・通知・ロック画面)](#layerrule)
- [カテゴリ別まとめ表](#まとめ表)

凡例: 「現状」はユーザーの dotfiles 内に明示設定がある場合のみ。なければ `—` (=デフォルト)。
バージョン記載がある項目は wiki から拾った範囲で参考までに付記。

---

## general

ブロック: `general { ... }`
ウィンドウの外側に直接見える要素 (枠線・ギャップ・色) と、レイアウト/リサイズの土台を決める。

| key | type | default | 解説 | 現状 |
|---|---|---|---|---|
| `border_size` | int | 1 | ウィンドウ枠の太さ (px)。`0` で完全に消える。 | `2` |
| `gaps_in` | int (or 4 値) | 5 | ウィンドウ同士の隙間。CSS 風に `top,right,bottom,left` も可。 | `5` |
| `gaps_out` | int (or 4 値) | 20 | モニター端との隙間。 | `10` |
| `float_gaps` | int | 0 | フローティングウィンドウのモニター端隙間。`-1` で `gaps_out` を流用。 | — |
| `gaps_workspaces` | int | 0 | ワークスペース切替アニメ時の余白。`gaps_out` に加算。 | — |
| `col.active_border` | gradient | 0xffffffff | アクティブ枠色。`color color [angle]deg` でグラデーション可。 | `$primary $tertiary 45deg` |
| `col.inactive_border` | gradient | 0xff444444 | 非アクティブ枠色。 | `$outline_variant` |
| `col.nogroup_border` / `col.nogroup_border_active` | gradient | 0xffffaaff / 0xffff00ff | グループに入れないウィンドウ用の枠色。 | — |
| `layout` | str | dwindle | `dwindle` / `master` / `scrolling` / `monocle`。 | `dwindle` |
| `resize_on_border` | bool | false | 枠/ギャップをドラッグでリサイズ可能にする。 | `true` |
| `extend_border_grab_area` | int | 15 | 枠の掴める判定幅。`resize_on_border=true` 時のみ。 | — |
| `hover_icon_on_border` | bool | true | 枠ホバー時にカーソルを変える。 | — |
| `allow_tearing` | bool | false | テアリング許可 (ゲーム向け)。マスタースイッチ。 | `false` |
| `no_focus_fallback` | bool | false | フォーカス先がない方向に動かそうとしたとき、隣に逃がさない。 | — |
| `resize_corner` | int | 0 | フロート時に固定リサイズコーナー (1〜4 / 0 で無効)。 | — |
| `modal_parent_blocking` | bool | true | モーダル親をクリック可能にするか。 | — |

サンプル:
- 枠なし・ギャップなしトグル: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/toggles/window-no-gaps.conf` (`border_size=0`, `gaps_in=0`, `gaps_out=0`)
- グラデーション枠 + ギャップ広め: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf` (`col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg`)
- 単色フラット枠 (lumon テーマ): `/home/mkiin/dotfiles/wiki/omarchy/themes/lumon/hyprland.conf` (`gaps_in=8`, `gaps_out=16`)

備考: `smart_gaps` / `smart_borders` は Hyprland には存在しない (sway/i3 の用語)。Hyprland では「単一ウィンドウ時にギャップを消す」のは `layout:single_window_aspect_ratio` か、トグル設定を `source` 切り替えで実現する。

## general:snap

ブロック: `general { snap { ... } }`
フローティングウィンドウが端や他ウィンドウに吸着する挙動。

| key | type | default | 解説 |
|---|---|---|---|
| `enabled` | bool | false | フロートのスナップ機能 ON/OFF。 |
| `window_gap` | int | 10 | ウィンドウ同士スナップの最小マージン。 |
| `monitor_gap` | int | 10 | モニター端スナップの最小マージン。 |
| `border_overlap` | bool | false | 枠 1 本分だけ間を空ける。 |
| `respect_gaps` | bool | false | スナップ時に `gaps_in` を尊重する。 |

現状: `—` (未設定)。

## decoration

ブロック: `decoration { ... }`
角丸・全体透明度・dim を扱う。`shadow`/`blur`/`glow` は別サブブロック。

| key | type | default | 解説 | 現状 |
|---|---|---|---|---|
| `rounding` | int | 0 | 角丸半径 (px)。 | `16` |
| `rounding_power` | float | 2.0 | 角丸カーブ。1=三角、2=円、4=スクワークル、〜10。v0.45+。 | `2` |
| `active_opacity` | float (0-1) | 1.0 | アクティブウィンドウ全体の不透明度。 | — |
| `inactive_opacity` | float | 1.0 | 非アクティブの不透明度。 | — |
| `fullscreen_opacity` | float | 1.0 | フルスクリーンの不透明度。 | — |
| `dim_modal` | bool | true | モーダル親を dim する。 | — |
| `dim_inactive` | bool | false | 非アクティブを dim。 | — |
| `dim_strength` | float | 0.5 | dim_inactive の濃さ。 | — |
| `dim_special` | float | 0.2 | special workspace 表示時に裏側を dim する量。 | — |
| `dim_around` | float | 0.4 | `dim_around` window rule の濃さ。 | — |
| `screen_shader` | str | (empty) | 画面全体に当てる GLSL fragment shader のパス。 | — |
| `border_part_of_window` | bool | true | 枠をウィンドウの一部として扱う (false でレイアウトの外に出す)。 | — |

サンプル:
- ベース dim 例: `/home/mkiin/dotfiles/wiki/omarchy/config/hypr/looknfeel.conf` (コメント例 `dim_inactive=true`, `dim_strength=0.15`)

## decoration:blur

ブロック: `decoration { blur { ... } }`
透過ウィンドウの裏側にかかるカワセ式ブラー。

| key | type | default | 解説 | 現状 |
|---|---|---|---|---|
| `enabled` | bool | true | ブラー有効化。 | `true` |
| `size` | int (>=1) | 8 | ブラー半径。 | `1` |
| `passes` | int (>=1) | 1 | パス数。size を上げたら増やすと綺麗。負荷大。 | `1` |
| `ignore_opacity` | bool | true | ウィンドウ自体の opacity を無視してブラーする。 | — |
| `new_optimizations` | bool | true | 新最適化。基本 ON 推奨。 | — |
| `xray` | bool | false | フロート blur がタイル下を貫通して下のレイヤーをぼかす。 | — |
| `noise` | float (0-1) | 0.0117 | ノイズ量。 | — |
| `contrast` | float (0-2) | 0.8916 | コントラスト。 | — |
| `brightness` | float (0-2) | 0.8172 | 明度。 | — |
| `vibrancy` | float (0-1) | 0.1696 | 彩度ブースト。 | `0.2` |
| `vibrancy_darkness` | float (0-1) | 0.0 | 暗部での vibrancy 効きの強さ。 | — |
| `special` | bool | false | special workspace 背景もブラー (重い)。 | — |
| `popups` | bool | false | コンテキストメニュー等の popup もブラー。 | — |
| `popups_ignorealpha` | float | 0.2 | popup のうち、透過率がこの値以下のピクセルはブラーしない。 | — |
| `input_methods` | bool | false | fcitx5 等の IME 候補ウィンドウもブラー。 | — |
| `input_methods_ignorealpha` | float | 0.2 | 同上の閾値。 | — |

サンプル:
- 高品質ブラー: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf` (`size=2`, `passes=2`, `special=true`, `brightness=0.60`, `contrast=0.75`)

## decoration:shadow

ブロック: `decoration { shadow { ... } }`
ウィンドウ周囲のドロップシャドウ。旧 `drop_shadow` 等は v0.40+ でこのサブブロックに統合された。

| key | type | default | 解説 |
|---|---|---|---|
| `enabled` | bool | true | シャドウ ON/OFF。旧 `drop_shadow` の後継。 |
| `range` | int | 4 | シャドウ範囲 (px)。旧 `shadow_range`。 |
| `render_power` | int (1-4) | 3 | 減衰の強さ。大きいほど早く消える。 |
| `sharp` | bool | false | シャープシャドウ (実質 render_power 無限大)。 |
| `ignore_window` | bool | true | ウィンドウ背後にシャドウを描画しない。透明ウィンドウに有効。旧 `shadow_ignore_window`。 |
| `color` | color | 0xee1a1a1a | シャドウ色 + α。 |
| `color_inactive` | color | unset | 非アクティブ用色 (未設定なら `color` を継承)。 |
| `offset` | vec2 | [0,0] | x,y オフセット (px)。`shadow_offset`。 |
| `scale` | float (0-1) | 1.0 | シャドウのスケール。 |

現状: `enabled = false` (`appearance/decoration.conf`)

サンプル:
- 強めの色付きシャドウ: `/home/mkiin/dotfiles/wiki/omarchy/themes/lumon/hyprland.conf` (`range=16`, `render_power=4`, `color=$activeShadowColor`, `color_inactive=$inactiveShadowColor`)
- 控えめ既定: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf` (`range=2`, `render_power=3`, `color=rgba(1a1a1aee)`)

## decoration:glow

ブロック: `decoration { glow { ... } }` (v0.46+ あたりで追加)

| key | type | default | 解説 |
|---|---|---|---|
| `enabled` | bool | false | 内側グロー ON/OFF。 |
| `range` | int | 10 | グロー範囲。 |
| `render_power` | int (1-4) | 3 | 減衰。 |
| `color` | color | 0xee1a1a1a | アクティブグロー色。 |
| `color_inactive` | color | unset | 非アクティブ色。 |

現状: `—`。

## animations

ブロック: `animations { ... }`

| key | type | default | 解説 | 現状 |
|---|---|---|---|---|
| `enabled` | bool | true | アニメ全体 ON/OFF。 | `yes` |
| `workspace_wraparound` | bool | false | 端のワークスペース間を最近接として扱う方向アニメ。 | — |

`animation = NAME, ONOFF, SPEED, CURVE [,STYLE]` で個別ターゲットを上書き。
`SPEED` の単位は `ds` (1ds = 100ms)。

ユーザー現状 (`appearance/animations.conf`):
```
animation = global,        1, 10,   default
animation = border,        1, 5.39, easeOutQuint
animation = windows,       1, 4.5,  bounce
animation = windowsIn,     1, 4.5,  bounce, popin 80%
animation = windowsOut,    1, 1.5,  linear, popin 80%
animation = workspaces,    1, 3,    bounce, slidefadevert
... (fade, layers, fadeLayers* 他は割愛)
```

サンプル:
- omarchy デフォ: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf` (`workspaces, 0, 0, ease` でワークスペース切替を瞬間化、`specialWorkspace, 1, 4, easeOutQuint, slidevert`)

### animation tree

`animation = X` で指定できる X の階層 (上位から継承):

```
global
  windows ─ windowsIn / windowsOut / windowsMove   styles: slide / popin N% / gnomed
  layers  ─ layersIn / layersOut                    styles: slide / popin / fade
  fade    ─ fadeIn / fadeOut / fadeSwitch / fadeShadow / fadeDim
            fadeLayers ─ fadeLayersIn / fadeLayersOut
            fadePopups ─ fadePopupsIn / fadePopupsOut
            fadeDpms
  border
  borderangle                                       styles: once (default) / loop
  workspaces ─ workspacesIn / workspacesOut         styles: slide / slidevert / fade / slidefade / slidefadevert
              specialWorkspace ─ specialWorkspaceIn / specialWorkspaceOut
  zoomFactor
  monitorAdded
```

注意: `borderangle` を `loop` style にすると常時再描画され GPU/バッテリーを消費する。

### bezier

`bezier = NAME, X0, Y0, X1, Y1` で 3 次ベジェ定義。`animation = ..., MYNAME` で参照。

ユーザー現状: `easeOutQuint` `linear` `almostLinear` `quick` `bounce`。
追加例 (omarchy): `easeInOutCubic, 0.65, 0.05, 0.36, 1`。

`popin` style の `popin 80%` は最小サイズ比率、`slidefade` の `slidefade 20%` は移動距離比率。
`slide` style は `top|bottom|left|right` で方向強制可。

## group

ブロック: `group { ... }` および `group { groupbar { ... } }`
タブ的に複数ウィンドウをまとめる「グループ」表示の見た目。

| key | type | default | 解説 |
|---|---|---|---|
| `auto_group` | bool | true | フォーカス中の非ロックグループに自動で吸い込むか。 |
| `insert_after_current` | bool | true | 新ウィンドウをカレントの直後に入れる。 |
| `focus_removed_window` | bool | true | グループから出たウィンドウにフォーカス移行。 |
| `drag_into_group` | int | 1 | 0 無効 / 1 有効 / 2 groupbar ドロップ時のみ。 |
| `merge_groups_on_drag` / `merge_groups_on_groupbar` | bool | true | グループ同士マージ可否。 |
| `col.border_active` / `col.border_inactive` | gradient | 0x66ffff00 / 0x66777700 | グループ境界の枠色。 |
| `col.border_locked_active` / `col.border_locked_inactive` | gradient | 0x66ff5500 / 0x66775500 | ロック済グループの枠色。 |

groupbar (`group:groupbar:`) 主要キー:

| key | type | default | 解説 |
|---|---|---|---|
| `enabled` | bool | true | groupbar 描画。 |
| `font_family` / `font_size` / `font_weight_active` / `font_weight_inactive` | — | — | タイトル文字。 |
| `gradients` | bool | false | グラデーション背景。 |
| `height` | int | 14 | バー高さ (px)。 |
| `indicator_height` / `indicator_gap` | int | 3 / 0 | インジケーター棒の高さ・タイトルとの間隔。 |
| `stacked` | bool | false | 縦積み描画。 |
| `render_titles` | bool | true | タイトル描画。 |
| `text_color` / `text_color_inactive` / `text_color_locked_active` / `text_color_locked_inactive` | color | 0xffffffff / unset | タイトル文字色。 |
| `col.active` / `col.inactive` / `col.locked_active` / `col.locked_inactive` | gradient | 0x66... | バー背景色。 |
| `gaps_in` / `gaps_out` | int | 2 / 2 | グラデーション同士、グラデーションとウィンドウ間の隙間。 |
| `keep_upper_gap` | bool | true | 上側ギャップを残す。 |
| `rounding` / `gradient_rounding` | int | 1 / 2 | インジケータ・背景の角丸。 |
| `round_only_edges` / `gradient_round_only_edges` | bool | true | 端のみ角丸。 |
| `blur` | bool | false | groupbar 自体にブラー。 |

サンプル:
- 立体感ある groupbar: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf` (`indicator_height=0`, `height=22`, `gaps_in=5`, `gradients=true`, `font_weight_active=ultraheavy`)

現状: `—`。

## misc

ブロック: `misc { ... }`
直接ウィンドウ単体の見た目ではないが画面全体の表現に効くもの中心。

| key | type | default | 解説 | 現状 |
|---|---|---|---|---|
| `disable_hyprland_logo` | bool | false | デフォの背景アニメ画像を無効化。 | `true` |
| `disable_splash_rendering` | bool | false | スプラッシュテキストを消す。 | — |
| `force_default_wallpaper` | int | -1 | 0/1=anime 無効、2=ロゴ、-1=ランダム。 | `0` |
| `background_color` | color | 0x111111 | `disable_hyprland_logo=true` 時の単色背景。 | — |
| `col.splash` | color | 0xffffffff | スプラッシュ文字色。 | — |
| `font_family` / `splash_font_family` | str | Sans / empty | デバッグ・通知文字フォント。 | — |
| `vfr` | bool | true | 可変フレームレート (省電力)。 | — |
| `vrr` | int | 0 | 0 オフ / 1 全 ON / 2 fullscreen / 3 fullscreen+content type game。 | — |
| `mouse_move_enables_dpms` / `key_press_enables_dpms` | bool | false | DPMS スリープ復帰トリガ。 | — |
| `animate_manual_resizes` / `animate_mouse_windowdragging` | bool | false / false | 手動リサイズ/ドラッグ時のアニメ。 | — |
| `enable_swallow` | bool | false | 端末がアプリ起動時に隠れる swallow 機能。 | — |
| `swallow_regex` / `swallow_exception_regex` | str | empty | swallow 対象クラス / 例外タイトル。 | — |
| `focus_on_activate` | bool | false | アプリの focus 要求に従う。 | — |
| `mouse_move_focuses_monitor` | bool | true | モニタ跨ぎでマウスがフォーカスを動かす。 | — |
| `session_lock_xray` | bool | false | ロック中も裏のワークスペースを描画。 | — |
| `close_special_on_empty` | bool | true | special ws の最後のウィンドウを閉じたら自動で閉じる。 | — |
| `on_focus_under_fullscreen` | int | 2 | フルスクリーン裏のフォーカス要求の扱い。0 無視 / 1 上書き / 2 解除。 | — |
| `exit_window_retains_fullscreen` | bool | false | 閉じたあと次のウィンドウがフルスクリーンを継承。 | — |
| `initial_workspace_tracking` | int | 1 | 起動コマンドのワークスペースに開く。0/1/2。 | — |
| `middle_click_paste` | bool | true | プライマリ選択ペースト。 | — |
| `render_unfocused_fps` | int | 15 | `render_unfocused` ルール対象の最大 fps。 | — |
| `enable_anr_dialog` / `anr_missed_pings` | bool / int | true / 5 | フリーズ警告ダイアログ。 | — |
| `size_limits_tiled` | bool | false | min_size/max_size をタイル窓にも適用。 | — |

サンプル: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf` (`disable_splash_rendering=true`, `focus_on_activate=true`, `on_focus_under_fullscreen=1`)

## layout

ブロック: `layout { ... }`

| key | type | default | 解説 |
|---|---|---|---|
| `single_window_aspect_ratio` | vec2 | `0 0` | ワークスペースに 1 つだけウィンドウがあるとき指定アスペクトに揃える padding を入れる。例 `1 1` で正方形。 |
| `single_window_aspect_ratio_tolerance` | float (0-1) | 0.1 | 上記の許容誤差。 |

現状: `—`。

## dwindle

ブロック: `dwindle { ... }`
BSPWM 風の二分木分割レイアウト。

| key | type | default | 解説 | 現状 |
|---|---|---|---|---|
| `pseudotile` | bool | false | pseudotile (擬似タイル) 有効。フロート時のサイズを保つ。 | `true` |
| `force_split` | int | 0 | 0 マウス位置依存 / 1 常に左 (上) / 2 常に右 (下)。 | — |
| `preserve_split` | bool | false | リサイズで分割方向が変わらない。 | `true` |
| `smart_split` | bool | false | カーソル位置 (4 三角) で分割方向を選ぶ。`preserve_split` も自動 ON。 | — |
| `smart_resizing` | bool | true | リサイズ方向をマウス近接コーナーで決める。 | — |
| `permanent_direction_override` | bool | false | preselect 方向を解除まで持続。 | — |
| `special_scale_factor` | float (0-1) | 1 | special workspace ウィンドウの縮小率。 | — |
| `split_width_multiplier` | float | 1.0 | 自動分割の幅乗数。ワイドモニター向け。 | — |
| `use_active_for_splits` | bool | true | 分割の基準を active ウィンドウにする。 | — |
| `default_split_ratio` | float (0.1-1.9) | 1.0 | 開いた直後の分割比 (1=均等)。 | — |
| `split_bias` | int | 0 | 0 上/左有利 / 1 カレント有利。 | — |
| `precise_mouse_move` | bool | false | bindm でマウス位置に正確にドロップ。 | — |

サンプル: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf` (`force_split=2`)

## master

ブロック: `master { ... }`

| key | type | default | 解説 |
|---|---|---|---|
| `allow_small_split` | bool | false | master 列を水平分割で増やせる。 |
| `special_scale_factor` | float | 1 | special ws 縮小率。 |
| `mfact` | float (0-1) | 0.55 | master 領域の幅割合。 |
| `new_status` | str | slave | `master` / `slave` / `inherit`。新ウィンドウの位置。 |
| `new_on_top` | bool | false | スタックの上に追加。 |
| `new_on_active` | str | none | `before` / `after` / `none`。 |
| `orientation` | str | left | `left` / `right` / `top` / `bottom` / `center`。 |
| `slave_count_for_center_master` | int | 2 | center 配置を発動する slave 数。 |
| `center_master_fallback` | str | left | center 不発動時の方向。 |
| `smart_resizing` | bool | true | dwindle と同様。 |
| `drop_at_cursor` | bool | true | ドロップ位置にウィンドウを置く。 |
| `always_keep_position` | bool | false | slave 0 のとき master を所定位置に固定。 |

サンプル: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf` (`new_status = master`)

現状: `—` (dwindle 使用中)。

## xwayland

ブロック: `xwayland { ... }`
XWayland (X11 互換層) 経由のウィンドウのスケーリング・解像度に効く。

| key | type | default | 解説 |
|---|---|---|---|
| `enabled` | bool | true | XWayland 全体 ON/OFF。 |
| `use_nearest_neighbor` | bool | true | スケール時に nearest neighbor。`true` でカクカク、`false` でぼやけにくい補間。 |
| `force_zero_scaling` | bool | false | スケール済みディスプレイで XWayland 窓のスケールを強制 1。文字がにじむのを防ぐ。 |
| `create_abstract_socket` | bool | false | abstract socket (Linux のみ)。 |

サンプル: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/envs.conf` (`force_zero_scaling = true`)

現状: `—`。

## render

ブロック: `render { ... }` (画面全体の描画品質と HDR/CM)

| key | type | default | 解説 |
|---|---|---|---|
| `direct_scanout` | int | 0 | フルスクリーンアプリのレイテンシ削減。0/1/2(auto with content type game)。 |
| `expand_undersized_textures` | bool | true | 小さいテクスチャを端伸ばしで拡大。 |
| `xp_mode` | bool | false | バックバッファ無効化。 |
| `ctm_animation` | int | 2 | 色温度切替アニメ (hyprsunset)。2=auto。 |
| `cm_fs_passthrough` | int | 2 | フルスクリーンの色設定パススルー。0/1/2(hdr only)。 |
| `cm_enabled` | bool | true | カラーマネジメントパイプ有効。 |
| `send_content_type` | bool | true | コンテンツタイプ通知 (HDR 自動切替)。 |
| `cm_auto_hdr` | int | 1 | フルスクリーン時 HDR 自動切替。0/1/2。 |
| `new_render_scheduling` | bool | false | 必要時にトリプルバッファリング。 |
| `non_shader_cm` | int | 3 | シェーダなし CM。0/1/2/3。 |
| `cm_sdr_eotf` | str | default | SDR の transfer function。`gamma22` / `gamma22force` / `srgb`。 |
| `commit_timing_enabled` | bool | true | commit timing protocol。 |

現状: `—`。

## cursor (appearance)

ブロック: `cursor { ... }`
ウィンドウ上の見た目に影響する範囲のみ抜粋 (入力挙動は除く)。

| key | type | default | 解説 |
|---|---|---|---|
| `invisible` | bool | false | カーソル描画オフ。 |
| `inactive_timeout` | float (秒) | 0 | 無操作 N 秒で自動非表示 (0=無効)。 |
| `hide_on_key_press` / `hide_on_touch` / `hide_on_tablet` | bool | false / true / true | 各種入力でカーソルを隠す。 |
| `enable_hyprcursor` | bool | true | hyprcursor (テーマ) 使用。 |
| `zoom_factor` | float (>=1) | 1.0 | 画面拡大率。 |
| `zoom_rigid` | bool | false | 拡大時カーソル中央追従。 |
| `zoom_disable_aa` | bool | false | 拡大時アンチエイリアスを切る (ピクセル感)。 |
| `no_warps` | bool | false | フォーカス移動でカーソルワープしない。 |

サンプル: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf` (`hide_on_key_press = true`, `warp_on_change_workspace = 1`)

現状: `/home/mkiin/dotfiles/home/dot_config/hypr/cursor.conf` (本リスト範囲外)。

## windowrule props

ブロック: `windowrule = ..., match:KEY VALUE` または名前付き `windowrule { match:KEY = VALUE; effect = ... }`
`match:` 全ての条件 AND マッチ。RegEx は Google RE2、`negative:` プレフィックスで否定。

| match: | 引数 | 解説 |
|---|---|---|
| `class` | RegEx | アプリクラス。 |
| `title` | RegEx | 現タイトル (動的)。 |
| `initial_class` / `initial_title` | RegEx | 起動時のクラス/タイトル (静的)。 |
| `tag` | name | `tag` ルール / `tagwindow` で付けたタグ。 |
| `xwayland` / `float` / `fullscreen` / `pin` / `focus` / `group` / `modal` | bool | 状態フラグ。 |
| `fullscreen_state_client` / `fullscreen_state_internal` | int 0-3 | フルスクリーン状態の細分。 |
| `workspace` | id/name/selector | 所属ワークスペース。 |
| `content` | int 0-3 | none/photo/video/game。 |
| `xdg_tag` | RegEx | xdg-shell タグ。 |

ユーザー現状例 (`rules.conf`): `match:class .*` (全窓), `match:class ^$` + `match:title ^$` + `match:xwayland true` + `match:float true` + `match:fullscreen false` + `match:pin false` (XWayland ドラッグ修正), `match:class hyprland-run`, `match:namespace logout_dialog` (layerrule)。

## windowrule effects

見た目に効くものだけ抜粋 (Static/Dynamic 区別あり)。

### Static (生成時のみ評価)

| effect | 引数 | 解説 |
|---|---|---|
| `float` / `tile` | on | フロート/タイル化。 |
| `fullscreen` / `maximize` | on | 最大化/フルスクリーン。 |
| `fullscreen_state` | internal client | 0/1/2/3 で詳細指定。 |
| `move` | expr expr | 座標式 (`monitor_w-window_w-40` 等)。 |
| `size` | expr expr | サイズ式。 |
| `center` | on | フロート時にセンタリング。 |
| `pseudo` | on | pseudotile。 |
| `monitor` / `workspace` | id | 出現先指定。 |
| `pin` | on | フロート専用、全 ws 表示。 |
| `no_initial_focus` | on | 初期フォーカス無効。 |
| `suppress_event` | types... | `fullscreen`/`maximize`/`activate`/`activatefocus`/`fullscreenoutput` イベント抑制。 |
| `content` | none/photo/video/game | コンテンツタイプ。 |
| `no_close_for` | ms | 一定時間 killactive を弾く。 |
| `scrolling_width` | float | scrolling layout 用列幅。 |
| `group` | options | `set`/`new`/`lock`/`barred`/`deny`/`invade`/`override`/`unset`。 |

### Dynamic (プロパティ変化で再評価)

見た目関連を中心に:

| effect | 引数 | 解説 |
|---|---|---|
| `opacity` | a / a a / a a a `[override]` | active / inactive / fullscreen の不透明度。デフォルトは積算、`override` で絶対値。 |
| `rounding` | int | 角丸を強制 (デフォルト無視)。 |
| `rounding_power` | float | 角丸カーブを上書き。 |
| `border_size` | int | 個別枠太さ。 |
| `border_color` | color [color] [angle] [inactive...] | 枠色グラデーション、active / inactive 個別指定可。 |
| `dim_around` | on | 背景を dim。フロート向け。 |
| `decorate` | on/off | 装飾全部の ON/OFF。 |
| `keep_aspect_ratio` | on | リサイズ時にアスペクト維持。 |
| `nearest_neighbor` | on | nearest neighbor フィルタ。 |
| `no_anim` | on | ウィンドウのアニメ無効。 |
| `no_blur` | on | ブラー無効。 |
| `no_dim` | on | dim 無効。 |
| `no_shadow` | on | シャドウ無効。 |
| `no_screen_share` | on | 画面共有から黒塗りで隠す。 |
| `xray` | on | ブラー xray モード。 |
| `opaque` | on | 完全不透明 (alpha 無視)。 |
| `force_rgbx` | on | サーフェス全体の alpha チャンネル除去。 |
| `animation` | style [opt] | 個別アニメスタイルを強制。 |
| `max_size` / `min_size` | w h | サイズ制限。 |
| `idle_inhibit` | none/always/focus/fullscreen | hypridle 抑制。 |
| `tag` | +name / -name / name | 動的タグ操作。 |
| `persistent_size` | on | フロート閉じ時のサイズを class+title で記憶。 |
| `stay_focused` | on | 表示中フォーカスを離さない。 |
| `allows_input` | on | XWayland の入力拒否を強制無効化。 |
| `no_focus` / `no_follow_mouse` | on | フォーカス系。 |
| `no_shortcuts_inhibit` | on | アプリのショートカット阻害を禁止。 |
| `no_vrr` | on | このウィンドウでは VRR 無効。 |
| `immediate` | on | テアリング許可 (個別)。 |
| `render_unfocused` | on | 非可視時にも描画継続。`render_unfocused_fps` と併用。 |
| `scroll_mouse` / `scroll_touchpad` | float | このウィンドウ専用 scroll factor。 |

サンプル:
- 端末だけ角丸 + 透過: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/apps/terminals.conf` (`opacity 0.97 0.9, match:tag terminal`)
- ブラウザ非アクティブだけ薄く: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/apps/browser.conf` (`opacity 1.0 0.97, match:tag chromium-based-browser`)
- メディア窓は完全不透明: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/apps/system.conf` (`opacity 1 1, match:class ^(zoom|vlc|mpv|...)$`)
- PiP は枠なし固定サイズ: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/apps/pip.conf` (`border_size 0`, `keep_aspect_ratio on`, `pin on`)
- フルスクリーン時だけ枠を赤に: 公式 wiki 例 `windowrule = border_color rgb(FF0000) rgb(880808), match:fullscreen 1` (`/home/mkiin/dotfiles/wiki/hyprland-wiki/content/Configuring/Window-Rules.md:253`)
- スクリーンセーバーに専用アニメ: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/apps/system.conf` (`animation slide, match:class org.omarchy.screensaver`)
- pop タグだけ rounding 8: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/apps/system.conf` (`rounding 8, match:tag pop`)

ユーザー現状: `match:class .* suppress_event maximize`、`hyprland-run` のフロート位置強制 (`/home/mkiin/dotfiles/home/dot_config/hypr/rules.conf`)。

## layerrule

レイヤー (waybar / 通知 / wallpaper / lockscreen の overlay 等) に対するルール。
`match:namespace REGEX` のみが prop。`hyprctl layers` で namespace を確認できる。

| effect | 引数 | 解説 |
|---|---|---|
| `no_anim` | on | layer のアニメ無効。 |
| `blur` | on | レイヤー背後にブラー。 |
| `blur_popups` | on | popup もブラー。 |
| `ignore_alpha` | float (0-1) | このアルファ以下のピクセルはブラーしない。 |
| `dim_around` | on | レイヤー裏を dim。 |
| `xray` | 0/1/unset | ブラー xray モード。 |
| `animation` | style | レイヤー個別アニメスタイル。 |
| `order` | int | 同種レイヤー内の重ね順 (大きいほど手前)。負も可。 |
| `above_lock` | 0/1/2 | ロック画面の上に描画 (2 で操作可)。 |
| `no_screen_share` | on | 画面共有で黒塗り。 |

サンプル:
- waybar をブラー: 公式例 `layerrule = blur on, match:namespace waybar` (`/home/mkiin/dotfiles/wiki/hyprland-wiki/content/Configuring/Window-Rules.md:357`)
- アプリランチャーのアニメ無効: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/apps/walker.conf` (`layerrule = no_anim on, match:namespace walker`)
- スクリーンショット選択枠のアニメ無効: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/apps/hyprshot.conf`

ユーザー現状: `layerrule = blur on, match:namespace logout_dialog`、`layerrule = dim_around on, match:namespace logout_dialog` (`/home/mkiin/dotfiles/home/dot_config/hypr/rules.conf:34-35`)。

---

## まとめ表

「これをいじると見た目がこう変わる」用の検索インデックス。

### 枠・サイズ・距離

| key | 値の例 | 目的 |
|---|---|---|
| `general:border_size` | 0 / 2 / 5 | 枠の太さ。0 で完全フラット |
| `general:gaps_in` | 0 / 5 / 8 | 窓間の隙間 |
| `general:gaps_out` | 0 / 10 / 16 | 画面端の隙間 |
| `general:gaps_workspaces` | 0 / 50 | ワークスペース切替時の追加余白 |
| `general:float_gaps` | -1 / 10 | フロート専用画面端余白 |
| `decoration:rounding` | 0 / 8 / 16 | 角丸半径 |
| `decoration:rounding_power` | 1 / 2 / 4 | 角の曲線形状 (三角〜スクワークル) |
| `general:resize_on_border` | true | 枠ドラッグでリサイズ可 |

### 色・透明・dim

| key | 値の例 | 目的 |
|---|---|---|
| `general:col.active_border` | `rgba(33ccffee) rgba(00ff99ee) 45deg` | アクティブ枠 (グラデも可) |
| `general:col.inactive_border` | `rgba(595959aa)` | 非アクティブ枠 |
| `decoration:active_opacity` | 1.0 / 0.95 | アクティブ全体の透明度 |
| `decoration:inactive_opacity` | 0.85 | 非アクティブ全体 |
| `decoration:fullscreen_opacity` | 1.0 | フルスクリーン |
| `decoration:dim_inactive` | true | 非アクティブを薄暗く |
| `decoration:dim_strength` | 0.15 / 0.5 | dim 濃度 |
| `decoration:dim_special` | 0.2 | special workspace 表示時の裏側 |
| `decoration:dim_around` | 0.4 | `dim_around` ルール対象の裏側 |

### ブラー

| key | 値の例 | 目的 |
|---|---|---|
| `decoration:blur:enabled` | true | 透過窓裏のブラー |
| `decoration:blur:size` | 1 / 2 / 8 | ブラー半径 |
| `decoration:blur:passes` | 1 / 2 / 3 | パス数 (品質と負荷) |
| `decoration:blur:vibrancy` | 0.2 | 彩度ブースト |
| `decoration:blur:contrast` | 0.75 / 0.89 | コントラスト |
| `decoration:blur:brightness` | 0.6 / 0.82 | 明るさ |
| `decoration:blur:noise` | 0.0117 | ノイズで lo-fi 感 |
| `decoration:blur:special` | true | special ws もぼかす |
| `decoration:blur:popups` | true | コンテキストメニューもぼかす |
| `decoration:blur:xray` | true | フロートぼかしがタイル下を貫通 |

### シャドウ・グロー

| key | 値の例 | 目的 |
|---|---|---|
| `decoration:shadow:enabled` | true | ドロップシャドウ |
| `decoration:shadow:range` | 2 / 16 | シャドウ範囲 (px) |
| `decoration:shadow:render_power` | 3 / 4 | 減衰スピード |
| `decoration:shadow:color` | `rgba(1a1a1aee)` | 色 + α |
| `decoration:shadow:color_inactive` | `rgba(30486077)` | 非アクティブ専用色 |
| `decoration:shadow:offset` | `0 4` | 影位置のずらし |
| `decoration:shadow:scale` | 1.0 | 影サイズ倍率 |
| `decoration:shadow:ignore_window` | true | 窓裏に影を出さず周囲だけ |
| `decoration:glow:enabled` | true | 内側グロー |

### アニメ

| key | 値の例 | 目的 |
|---|---|---|
| `animations:enabled` | yes / no | 全アニメスイッチ |
| `animation = windows` | `1, 4.5, bounce` | 窓出現/消滅速度・カーブ |
| `animation = windowsIn` | `1, 4.1, easeOutQuint, popin 87%` | 出現時の popin 比率指定 |
| `animation = workspaces` | `1, 3, bounce, slidefadevert` | ワークスペース切替の流れ方 |
| `animation = layers` | `1, 3.8, easeOutQuint` | バー/通知の出現 |
| `animation = border` | `1, 5.39, easeOutQuint` | 枠色変化のなめらかさ |
| `animation = borderangle` | `1, 30, linear, loop` | グラデ角度の回転 (loop は重い) |
| `animation = fadeDim` | `1, 5, ...` | dim フェードのなめらかさ |
| `bezier = NAME, ...` | `bounce, 0.05, 0.9, 0.1, 1.05` | カスタムカーブ定義 |

### ウィンドウルール (見た目上書き)

| key | 値の例 | 目的 |
|---|---|---|
| `windowrule = opacity` | `0.97 0.9` / `1 1 1 override` | アプリ別 透明度 |
| `windowrule = rounding` | `8` | アプリ別 角丸 |
| `windowrule = rounding_power` | `4.0` | アプリ別 角形状 |
| `windowrule = border_size` | `0` / `4` | アプリ別 枠太さ |
| `windowrule = border_color` | `rgb(FF0000) rgb(880808)` | アプリ別 枠色 (active/inactive) |
| `windowrule = no_blur on` | — | このアプリだけブラー無効 |
| `windowrule = no_shadow on` | — | このアプリだけ影無効 |
| `windowrule = no_dim on` | — | このアプリだけ dim 無効 |
| `windowrule = no_anim on` | — | このアプリだけアニメ無効 |
| `windowrule = dim_around on` | — | フロート背景 dim |
| `windowrule = opaque on` | — | alpha 無視 |
| `windowrule = decorate off` | — | 全装飾オフ |
| `windowrule = animation` | `slide` / `popin` | 個別アニメスタイル |
| `windowrule = nearest_neighbor on` | — | ピクセルアート向け補間 |

### レイヤールール

| key | 値の例 | 目的 |
|---|---|---|
| `layerrule = blur on` | `match:namespace waybar` | バー裏ブラー |
| `layerrule = blur_popups on` | — | popup ブラー |
| `layerrule = ignore_alpha` | `0.5` | 半透明以下はぼかさない |
| `layerrule = dim_around on` | `match:namespace logout_dialog` | レイヤー裏 dim |
| `layerrule = no_anim on` | `match:namespace walker` | アニメ無効 |
| `layerrule = animation` | `slide` / `fade` | レイヤー個別アニメ |
| `layerrule = order` | `5` / `-1` | 重なり順 |
| `layerrule = above_lock` | `2` | ロック画面より上 (操作可) |

### misc / xwayland (見た目周辺)

| key | 値の例 | 目的 |
|---|---|---|
| `misc:disable_hyprland_logo` | true | デフォ背景の anime 画像を消す |
| `misc:background_color` | `rgb(111111)` | 単色背景 |
| `misc:vfr` | true | 省電力 (静止時 fps を下げる) |
| `misc:vrr` | 0/1/2/3 | アダプティブシンク |
| `misc:animate_manual_resizes` | true | 手動リサイズもアニメ化 |
| `misc:animate_mouse_windowdragging` | true | ドラッグ中もアニメ |
| `misc:enable_swallow` | true | 端末からの起動で端末を隠す |
| `misc:focus_on_activate` | true | activate 要求でフォーカス |
| `misc:session_lock_xray` | true | ロック中も裏ws描画 |
| `misc:on_focus_under_fullscreen` | 0/1/2 | フルスクリーン裏のフォーカス処理 |
| `xwayland:use_nearest_neighbor` | false | XWayland 拡大をぼやけさせない/にじませない |
| `xwayland:force_zero_scaling` | true | スケール済モニタで XWayland を等倍に |
| `cursor:invisible` / `cursor:inactive_timeout` | true / 3 | カーソル隠し |
| `cursor:zoom_factor` | 1.5 | 画面拡大鏡 |

### dwindle / master (レイアウト見た目)

| key | 値の例 | 目的 |
|---|---|---|
| `dwindle:preserve_split` | true | 分割向き固定 |
| `dwindle:smart_split` | true | カーソル四分割で分割向き決定 |
| `dwindle:smart_resizing` | true | カーソル近接コーナーでリサイズ |
| `dwindle:force_split` | 0/1/2 | 新窓の出現位置 |
| `dwindle:default_split_ratio` | 1.0 | 開いた直後の分割比 |
| `dwindle:special_scale_factor` | 0.9 | special ws ウィンドウ縮小 |
| `master:mfact` | 0.55 / 0.7 | master 領域の幅割合 |
| `master:orientation` | left/right/top/bottom/center | master 配置 |
| `master:new_status` | master/slave/inherit | 新窓を master に置くか |
| `layout:single_window_aspect_ratio` | `4 3` / `1 1` | 単独窓のアスペクト固定 |

---

参考:
- 公式 Variables: `/home/mkiin/dotfiles/wiki/hyprland-wiki/content/Configuring/Variables.md`
- 公式 Animations: `/home/mkiin/dotfiles/wiki/hyprland-wiki/content/Configuring/Animations.md`
- 公式 Window-Rules: `/home/mkiin/dotfiles/wiki/hyprland-wiki/content/Configuring/Window-Rules.md`
- 公式 Dwindle / Master: `/home/mkiin/dotfiles/wiki/hyprland-wiki/content/Configuring/Dwindle-Layout.md` / `Master-Layout.md`
- 実用サンプル: `/home/mkiin/dotfiles/wiki/omarchy/default/hypr/looknfeel.conf`、`apps/*.conf`、`themes/*/hyprland.conf`
- 自分の設定: `/home/mkiin/dotfiles/home/dot_config/hypr/appearance/*.conf`、`/home/mkiin/dotfiles/home/dot_config/hypr/rules.conf`
