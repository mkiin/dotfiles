# Waybar Tray Style Refresh Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 壁紙由来の前景色が変わったとき、Fcitx の symbolic トレイアイコンをバーの再起動なしで再描画する。

**Architecture:** Item の style-updated 通知から idle 更新を予約する。前景色の比較で画像更新の循環を防ぎ、Home Manager の package override からパッチを適用する。

**Tech Stack:** Waybar 0.15.0、GTK 3、gtkmm、GLib、C++、Nix、Home Manager。

**Spec:** `docs/superpowers/specs/2026-09-05-waybar-tray-style-refresh-design.md`

## Global Constraints

- 対象は現在固定されている Waybar 0.15.0。
- バーの再起動や surface の再生成を行わず、現在のタイル配置を維持する。
- 今回の検知対象は `@color6` が変える前景色である。
- 通常のカラー画像を単色に変換する処理も追加しない。
- CSS、JSONC、壁紙変更スクリプトの変更は不要である。
- 作業中のユーザーの変更を維持する。設計作成時点で複数の未コミット変更がある。

## Task 1: トレイ画像の更新経路と Nix パッケージ

**Files:**

- Create: `home-manager/desktop/waybar/patches/refresh-tray-on-style-change.patch`
- Modify: `home-manager/desktop/waybar/default.nix`
- Patch targets: `include/modules/sni/item.hpp`, `src/modules/sni/item.cpp`

**Interfaces:**

- Consumes: 既存の `Item::updateImage()` と `event_box` の StyleContext。
- Produces: `void Item::onStyleUpdated()`、`bool Item::refreshStyleImage()`。
- State: `bool icon_ready_ = false`、`std::optional<Gdk::RGBA> last_style_color_`、`sigc::connection style_refresh_connection_`。

- [ ] パッチなしの Waybar で、検証用 CSS の `#tray { color: #ff0000; }` を `#00ff00` に変更する。アイコンが変わらないことを記録する。検証には一時ディレクトリにコピーした設定を使い、稼働中の設定ファイルを変更しない。
- [ ] 固定ソースを取得し、一時作業ディレクトリへコピーする。

```sh
nix build --no-link .#nixosConfigurations.nixos.config.home-manager.users.mkiin.programs.waybar.package.src
nix eval --raw .#nixosConfigurations.nixos.config.home-manager.users.mkiin.programs.waybar.package.src.outPath
```

- [ ] ヘッダーに上記の宣言と `<optional>`、必要な RGBA ヘッダーを追加する。コンストラクターでは `event_box.signal_style_updated().connect(sigc::mem_fun(*this, &Item::onStyleUpdated))` を接続する。
- [ ] `proxyReady()` の必須プロパティ検証後、既存の `updateImage()` の直前で `icon_ready_ = true` にする。デストラクターの先頭で `style_refresh_connection_.disconnect()` を実行する。
- [ ] 以下の処理案を実装し、固定ソースのインクルードと型に合わせてコンパイル確認する。

```cpp
void Item::onStyleUpdated() {
  if (!icon_ready_ || style_refresh_connection_.connected()) return;
  style_refresh_connection_ = Glib::signal_idle().connect(
      sigc::mem_fun(*this, &Item::refreshStyleImage));
}

bool Item::refreshStyleImage() {
  if (!icon_ready_) return false;
  try {
    const auto style = event_box.get_style_context();
    const auto color = style->get_color(style->get_state());
    if (last_style_color_ && *last_style_color_ == color) return false;
    last_style_color_ = color;
    updateImage();
  } catch (const Glib::Error& error) {
    spdlog::warn("Tray style refresh failed for {}: {}", id,
                 std::string(error.what()));
  } catch (const std::exception& error) {
    spdlog::warn("Tray style refresh failed for {}: {}", id, error.what());
  }
  return false;
}
```

- [ ] `updateImage()` の `getIconPixbuf()` 直後に `if (!pixbuf) return;` を追加する。
- [ ] 固定ソースとの差分を `a/` と `b/` のプレフィックス付きパッチに保存する。変更対象が上記2つの C++ ファイルだけであることを確認する。
- [ ] `default.nix` の引数に `pkgs` を追加し、`programs.waybar` に以下を追加する。

```nix
package = pkgs.waybar.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [
    ./patches/refresh-tray-on-style-change.patch
  ];
});
```

- [ ] パッチ適用とビルドを検証する。新規パッチも評価対象にするため、Git の追跡状態に依存しない `path:.` を使用する。

```sh
nix build --no-link 'path:.#nixosConfigurations.nixos.config.home-manager.users.mkiin.programs.waybar.package'
git diff --check
```

期待結果はパッチ適用と C++ コンパイルの成功である。
実装中に一時的な trace ログを入れる場合は最終パッチから削除する。

## Task 2: 実画面の比較とライフサイクル検証

**Files:** 製品コードの追加変更なし。検証用設定は一時ディレクトリに置く。

**Interfaces:** Task 1 のパッチ付き Waybar バイナリと既存の CSS 再読み込み経路を使う。

- [ ] 同じ検証用設定でパッチ付きバイナリを起動し、赤から緑への変更がポインター移動や入力方式変更なしで反映されることを比較する。実行中の Waybar と競合しない検証セッションで行う。
- [ ] 同色で CSS を10回更新する。一時 trace またはデバッガで同色の再描画が継続しないことを確認する。
- [ ] 起動直後の CSS 更新と、更新予約直後のトレイ項目削除を繰り返し、クラッシュや例外ログが発生しないことを確認する。
- [ ] Fcitx の入力方式変更、左クリック、右クリックメニュー、複数モニターでの色追従を確認する。
- [ ] パッチ付き Waybar に切り替えた後、実際の壁紙変更の前後で以下を保存して比較する。ウィンドウを操作せず、PID、レイヤーのアドレスと寸法、タイルの位置と寸法が変わらないことを確認する。

```sh
pgrep -x waybar
hyprctl -j layers
hyprctl -j clients | jq '[.[] | {address, at, size, workspace: .workspace.id}] | sort_by(.address)'
```

- [ ] ビルド結果と実画面検証を分けて報告する。実画面検証が未実施の場合は修正完了と断定しない。

初回のバイナリ切り替えで発生する再起動と、壁紙変更ごとの動作を区別して評価する。
システムへの適用は実装後の作業として扱い、この設計作成では実行しない。
