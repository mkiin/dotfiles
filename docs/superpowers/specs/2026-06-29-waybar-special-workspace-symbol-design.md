# waybar 特殊ワークスペースのシンボル表示 設計

- 日付: 2026-06-29
- 対象: `home-manager/desktop/waybar/`
- 作業ブランチ: `worktree-waybar-special-ws`(git worktree で隔離)

## 背景

waybar のリファクタ依頼として当初2つの課題があった。

1. ワークスペース 1〜4 のボタンをクリックしても該当ワークスペースにジャンプしない(クリックアクションが死んでいる)
2. super+s で開く特殊ワークスペース(`special:magic`)を、ws モジュール上で数字ではなく別のシンボルで表示したい

調査の結果、課題1は config だけでは直せないこと、課題2は CSS 単体では実現できないことが判明した。協議の結果、**今回のスコープは課題2のみ**とし、課題1は upstream 修正のリリース待ちとする。

## 環境

- waybar `v0.15.0`(GTK4 ビルド)
- Hyprland: `configType = "lua"`(= Lua ディスパッチャ。`home-manager/desktop/hyprland/default.nix`)
- 特殊ワークスペース名: `special:magic`(`super+s` でトグル、`super+shift+s` でウィンドウ移動。`hyprland/lua/keybinds.lua`)
- waybar 設定の供給方法: `programs.waybar.settings = [ importJSON ./config.json + nix 調整 ]`(`waybar/default.nix`)。`style.css` / `styles/` は `lnk` シンボリックリンク(`reload_style_on_change` でホットリロード)。

## 課題1(クリック不動)の調査結果 — 今回は対応せず保留

根本原因を実機で確定済み:

- `hyprctl dispatch workspace 2` → **失敗**(`')' expected near '2'`。Lua ディスパッチャが旧形式テキストを Lua 式として解釈し構文エラー)
- `hyprctl dispatch 'hl.dsp.exec_raw("workspace 2")'` → **OK**

waybar v0.15.0 の `Workspace::handleClicked`(`src/modules/hyprland/workspace.cpp`)は `dispatch workspace <id>` 等の旧形式を**ハードコード**で送出する。`config.json` の `"on-click": "activate"` は**この経路では参照されず無視される**ため、config だけでは修正不能。同一原因でスクロール切替も壊れている。

- 問題報告(Issue): [Alexays/Waybar#5008](https://github.com/Alexays/Waybar/issues/5008)
- 修正(PR、masterへ 2026-05-04 マージ済み・v0.15.0 には未取込): [Alexays/Waybar#5013](https://github.com/Alexays/Waybar/pull/5013)
  - `IPC::dispatch` が Hyprland ≥0.54 の Lua プロトコルを自動検出し、click / scroll / special toggle を一括で修正する。

**現時点で修正を含むリリースは未公開**(最新タグは 0.15.0、nixpkgs unstable も 0.15.0)。

→ **対応方針: 何もしない。** 次の waybar リリース(PR#5013 取込)が nixpkgs に入った時点でバージョンが上がれば自動的に解消する。それまでクリック切替は不可のまま許容する。`config.json` の `"on-click": "activate"` は無害なので現状維持。

## 課題2(特殊ワークスペースのシンボル表示)— 今回の実装対象

### CSS 単体では不可という結論

waybar は GTK の CSS を使用しており、Web CSS の `::before { content: "★" }` のような**グリフ(文字)注入機能を GTK は持たない**。ウィジェットの表示文字は必ず waybar モジュール設定(`format` / `format-icons`)が決める。CSS が担えるのは色・背景・角丸・サイズ・余白などの**装飾のみ**。

| やりたいこと                                   | CSS単体                 |
| ---------------------------------------------- | ----------------------- |
| 特殊ワークスペースにシンボル文字を出す         | ❌(`format-icons` 必須) |
| 特殊ワークスペースのボタンを色・形で目立たせる | ⭕                      |

→ 実現方法は **「`format-icons` でシンボルを供給 + CSS で装飾」の併用**。

### 設計

waybar の再ビルドは不要。`config.json` と CSS の変更のみで完結する。

**1. `home-manager/desktop/waybar/config.json` の `hyprland/workspaces`**

- `"show-special": true` を追加 — 特殊ワークスペースを ws モジュールに表示する
- `"special-visible-only": true` を追加 — 特殊ワークスペースが**可視(アクティブ)な時のみ**ボタンを表示。`super+s` でトグル中だけシンボルが現れ、閉じれば消える
- `"format"` を `"{id}"` → `"{icon}"` に変更
- `"format-icons"` を再構成し、ワークスペース 1〜5 はそのまま数字、特殊ワークスペースのみ別シンボルにマッピングする

設計上の注意(実装時に実機で確定する箇所):

- 特殊ワークスペースが「アクティブ表示時にどの `format-icons` キーで一致するか」(`special` / 名前 `special:magic` / 状態 `active`)は waybar バージョン依存。`super+s` でトグルしながら実際に一致するキーを確定する。
- `format` を `{icon}` にした際、数字 1〜5 の表示・アクティブ強調(`.active` の CSS)が壊れないことを実機で確認する。`format-icons` には `1`〜`5` を明示的に列挙し(persistent-workspaces が固定 `[1,2,3,4,5]` のため全数字を網羅できる)、アクティブ時も数字が出るよう調整する。

**2. `home-manager/desktop/waybar/styles/capsule-nobg.css`**

- `#workspaces button.special` ルールを追加。数字ボタンと色・背景を差別化し(`@tertiary` 等のアクセント色を想定)、特殊ワークスペースであることが一目で分かるようにする。グリフ自体は `format-icons` が出し、CSS は装飾担当。

**3. シンボルのグリフ**

- 星/魔法系の Nerd Font アイコンを仮置きし、実機でレンダリングを確認して見栄えのよいものに確定する。後から1行変更するだけで差し替え可能。

### 反映方法

- `config.json` は Nix 管理(`programs.waybar.settings`)のため、`home-manager switch` + waybar 再起動が必要
- CSS(`styles/`)は `lnk` シンボリックリンクのため `reload_style_on_change` でホットリロード

## スコープ

- **対象**: 特殊ワークスペースのシンボル表示(`config.json` + `capsule-nobg.css`)
- **対象外**: クリック/スクロール切替の修正(upstream リリース待ち)、その他の waybar モジュール

## 成功条件

- `super+s` で特殊ワークスペースを開くと、ws モジュールに数字とは異なるシンボルのボタンが現れる
- 特殊ワークスペースを閉じるとそのボタンは消える
- 既存の数字ワークスペース 1〜5 の表示・アクティブ強調が従来通り保たれる
- 特殊ワークスペースのボタンが色・背景で数字ボタンと区別できる
