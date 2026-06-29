# nixpkgs の Hypr 系パッケージ一覧

## コア

| パッケージ            | 説明                                                             |
| --------------------- | ---------------------------------------------------------------- |
| `hyprland`            | Dynamic tiling Wayland compositor（WM 本体）                     |
| `hyprland-protocols`  | Wayland protocol extensions for Hyprland                         |
| `hyprland-qt-support` | Qt6 QML provider for hypr\* apps                                 |
| `hyprland-qtutils`    | Hyprland QT/qml utility apps                                     |
| `hyprlang`            | Official implementation library for the hypr config language     |
| `hyprgraphics`        | Cpp graphics library for Hypr\* ecosystem                        |
| `hyprutils`           | Small C++ library for utilities used across the Hypr\* ecosystem |
| `hyprtoolkit`         | A modern C++ Wayland-native GUI toolkit                          |
| `hyprwayland-scanner` | Hyprland version of wayland-scanner in and for C++               |
| `hyprwire`            | A fast and consistent wire protocol for IPC                      |

## エコシステム（ユーティリティ）

| パッケージ        | 説明                                                                    |
| ----------------- | ----------------------------------------------------------------------- |
| `hypridle`        | Hyprland's idle daemon（自動スリープ）                                  |
| `hyprlock`        | Hyprland's GPU-accelerated screen locking utility                       |
| `hyprpolkitagent` | Polkit authentication agent written in QT/QML                           |
| `hyprshot`        | Utility to easily take screenshots in Hyprland using your mouse         |
| `hyprshutdown`    | A graceful shutdown utility for Hyprland                                |
| `hyprpaper`       | Blazing fast wayland wallpaper utility                                  |
| `hyprpicker`      | Wlroots-compatible Wayland color picker that does not suck              |
| `hyprcursor`      | Hyprland cursor format, library and utilities                           |
| `hyprshade`       | Hyprland shade configuration tool（シェーダー/ブルーライトカット）      |
| `hyprsunset`      | Application to enable a blue-light filter on Hyprland                   |
| `hyprproxlock`    | Bluetooth デバイスの近接距離で hyprlock を自動制御                      |
| `hyprnotify`      | DBus Implementation of Freedesktop Notification spec for hyprctl notify |
| `hyprprop`        | Xprop replacement for Hyprland（ウィンドウ情報取得）                    |
| `hyprsysteminfo`  | Tiny qt6/qml app to display system information                          |
| `hyprviz`         | GUI for configuring Hyprland                                            |
| `hyprls`          | LSP server for Hyprland's configuration language                        |
| `hyprkeys`        | Simple, scriptable keybind retrieval utility                            |

## ワークスペース・レイアウト

| パッケージ                     | 説明                                                               |
| ------------------------------ | ------------------------------------------------------------------ |
| `hyprland-workspaces`          | Multi-monitor aware Hyprland workspace widget                      |
| `hyprland-workspaces-tui`      | TUI wrapper for hyprland-workspaces CLI                            |
| `hyprland-activewindow`        | Multi-monitor-aware Hyprland workspace widget helper               |
| `hyprland-autoname-workspaces` | Automatically rename workspaces with icons of started applications |
| `hyprnome`                     | GNOME-like workspace switching in Hyprland                         |
| `hyprsome`                     | Awesome-like workspaces for Hyprland                               |

## モニター・ディスプレイ管理

| パッケージ                  | 説明                                                            |
| --------------------------- | --------------------------------------------------------------- |
| `hyprdynamicmonitors`       | Dynamic monitor configuration for Hyprland                      |
| `hyprland-monitor-attached` | 自動でモニター接続時にスクリプト実行                            |
| `hyprmon`                   | TUI monitor configuration tool（drag-and-drop レイアウト）      |
| `hyprmoncfg`                | Terminal-first monitor configurator and auto-switching daemon   |
| `iio-hyprland`              | iio-sensor-proxy でディスプレイ向きを自動変更（タブレット向け） |
| `nwg-displays`              | Output management utility for Sway, Hyprland and Niri           |

## バー・パネル・ランチャー

| パッケージ             | 説明                                                        |
| ---------------------- | ----------------------------------------------------------- |
| `hyprpanel`            | Bar/Panel for Hyprland with extensive customizability       |
| `hyprshell`            | Modern GTK4-based window switcher and application launcher  |
| `hyprlauncher`         | A multipurpose and versatile launcher / picker for Hyprland |
| `ashell`               | Ready to go Wayland status bar for Hyprland                 |
| `nwg-dock-hyprland`    | GTK3-based dock for Hyprland                                |
| `yambar-hyprland-wses` | Enable Yambar to show Hyprland workspaces                   |

## ウィンドウ効果・プラグイン

| パッケージ      | 説明                                                  |
| --------------- | ----------------------------------------------------- |
| `hyprdim`       | Automatically dim windows when switching between them |
| `hyprfreeze`    | ゲームプロセスを一時停止（Wayland 対応）              |
| `hyprmagnifier` | Wlroots-compatible Wayland magnifier                  |
| `hyprpwcenter`  | A GUI Pipewire control center                         |
| `hyprwhspr-rs`  | Native speech-to-text voice dictation for Hyprland    |
| `hyprlax`       | Dynamic parallax wallpaper engine                     |

## プラグイン（`hyprlandPlugins.*`）

| パッケージ             | 説明                                                |
| ---------------------- | --------------------------------------------------- |
| `borders-plus-plus`    | Hyprland multiple borders plugin                    |
| `csgo-vulkan-fix`      | CS:GO/CS2 Vulkan fix plugin                         |
| `hy3`                  | i3/sway-like manual tiling layout plugin            |
| `hypr-darkwindow`      | 特定ウィンドウの色を反転するプラグイン              |
| `hypr-dynamic-cursors` | よりリアルなカーソル動作プラグイン                  |
| `hyprbars`             | ウィンドウタイトルバー追加プラグイン                |
| `hyprfocus`            | flashfocus プラグイン（ウィンドウ切り替え時に光る） |
| `hyprgrass`            | タッチジェスチャープラグイン                        |
| `hyprspace`            | Workspace overview plugin                           |
| `hyprsplit`            | awesome/dwm-like workspaces プラグイン              |
| `imgborders`           | タイリングに画像ボーダーを追加                      |

## テーマ・カーソル

| パッケージ             | 説明                           |
| ---------------------- | ------------------------------ |
| `catppuccin-hyprland`  | Catppuccin テーマ for Hyprland |
| `rose-pine-hyprcursor` | Rose Pine theme for Hyprcursor |

## 周辺ツール（Hyprland 対応）

| パッケージ                    | 説明                                                      |
| ----------------------------- | --------------------------------------------------------- |
| `grimblast`                   | Helper for screenshots within Hyprland（grimshot ベース） |
| `hdrop`                       | tdrop エミュレート（特定アプリを keybind で表示/非表示）  |
| `chameleos`                   | Screen annotation tool for niri and Hyprland              |
| `hyprnome`                    | GNOME-like workspace switching                            |
| `hyprland-per-window-layout`  | ウィンドウごとのキーボードレイアウト切り替え              |
| `sway-audio-idle-inhibit`     | 音声再生中は hypridle によるスリープを防ぐ                |
| `sunsetr`                     | Automatic blue light filter for Hyprland/Niri/Wayland     |
| `syspower`                    | Simple power menu/shutdown screen for Hyprland            |
| `xdg-desktop-portal-hyprland` | xdg-desktop-portal backend for Hyprland                   |
| `nwg-displays`                | Output management utility for Sway/Hyprland/Niri          |

## 開発・LSP

| パッケージ             | 説明                                             |
| ---------------------- | ------------------------------------------------ |
| `tree-sitter-hyprlang` | Tree-sitter grammar for hyprlang                 |
| `hyprls`               | LSP server for Hyprland's configuration language |

## 無関係（名前が被っているだけ）

| パッケージ  | 説明                                                             |
| ----------- | ---------------------------------------------------------------- |
| `hypr`      | Tiling X11 window manager（Hyprland の前身、別物）               |
| `hypre`     | Parallel solvers for sparse linear systems（数値計算ライブラリ） |
| `hyprspace` | Lightweight VPN Built on top of Libp2p（Hyprland と無関係）      |
| `hypraw`    | Typst package for headless code blocks（Typst 用、無関係）       |
