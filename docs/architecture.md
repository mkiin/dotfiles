# Architecture

CachyOS + Hyprland (Wayland) を前提とした個人 dotfiles のアーキテクチャ概観。

## 全体像

```
              ┌──────────────────────────────────────────┐
              │              uwsm (systemd)              │
              │   graphical-session.target を提供する     │
              └────────────────────┬─────────────────────┘
                                   │
              ┌────────────────────▼─────────────────────┐
              │               Hyprland                   │
              │   compositor (Wayland, NVIDIA-open)      │
              │   ─ env.conf, monitors.conf, keybinds…   │
              └─┬──────────────┬────────────┬───────────┬┘
                │              │            │           │
        ┌───────▼──────┐  ┌────▼────┐  ┌────▼────┐ ┌────▼─────┐
        │   Walker     │  │  Waybar │  │  awww   │ │ Hyprlock │
        │  (launcher / │  │ (status │  │ (壁紙   │ │  (lock)  │
        │   menus via  │  │   bar)  │  │ daemon) │ │          │
        │   Elephant)  │  └─────────┘  └─────────┘ └──────────┘
        └──────┬───────┘
               │ provider plugin
        ┌──────▼───────┐
        │  Elephant    │
        │  (DBus, lua  │
        │   menus)     │
        └──────────────┘
```

すべての常駐デーモン (Waybar / awww / Walker / Hypridle / fcitx5 / Swaync) は **`uwsm app -- ...`** でラップされ systemd user scope に取り込まれる。`graphical-session.target` と寿命が揃うので、ログアウトで漏れなく停止する。

## コンポーネント役割

| 役割 | コンポーネント | 補足 |
|---|---|---|
| Compositor | **Hyprland** | dynamic tiling, Wayland。NVIDIA-open + explicit sync |
| Session manager | **uwsm** | Hyprland を systemd-managed にする。autostart は `exec-once = uwsm app -- <cmd>` |
| Launcher / Menu | **Walker** + **Elephant** | walker = GUI、elephant = backend (DBus + lua provider)。rofi の置き換え |
| 壁紙 | **awww-daemon** | swww のフォーク (CLI 互換)。per-monitor キャッシュあり |
| 色生成 | **matugen** | 壁紙 → Material You パレット → 各 consumer のテンプレを fill |
| Status bar | **Waybar** | `reload_style_on_change` で CSS だけ live reload |
| 通知 | **swaync** (SwayNotificationCenter) | 通知センター + コントロールパネル |
| Idle | **hypridle** | DPMS / suspend / lock のトリガ管理 |
| Lock | **hyprlock** | 公式 Wayland ロックスクリーン |
| IME | **fcitx5** | 日本語入力 |
| Shutdown 系 | **wlogout + hyprshutdown** | 電源メニュー |
| Terminal | **Ghostty** | デフォルトターミナル |

## 設計の柱(今日までの対話で確立したもの)

### 1. Source of Truth = config ファイル

各 `~/.config/<app>/` のファイル(monitors.conf, keybinds.conf, …)が**唯一の真**。
**runtime の変更は `hyprctl keyword` 等で「config ファイルを書き換えずに動的に重ねる」** スタイルに統一。再起動 / 再ログインで必ず config の真の状態に戻る。

### 2. 自動 reload は OFF

`misc:disable_autoreload = true` を hyprland.conf に明示。matugen が color テンプレを生成して config ファイルに書き出しても、Hyprland が勝手に全 reload しない。reload は **明示呼び出し**(`hyprctl reload` / `hyprctl keyword source <file>`)に限定される。

これにより「runtime に動的に重ねた状態 (例: bed-mode のモニター構成)」が壁紙変更等のファイル書き出しで吹き飛ばない。

### 3. ベッド / デスクモードの 2 状態

- **desk-mode**: 3 枚 (DP-1/DP-2/DP-3)。monitors.conf 上の真の状態。
- **bed-mode**: 1 枚 (HDMI-A-1)。動的に重ねる一時状態。
- 切替: `Super+Shift+D` / `Super+Shift+B`
- ws ナビゲーション: `Super+I/O` (e-1/e+1) は両モード共通

### 4. テーマパイプライン: 壁紙が真

壁紙画像 1 枚から matugen が全 consumer (Hyprland 枠色 / Waybar / Walker / Wlogout) の色を生成。色設定は手書きせず、matugen テンプレ経由で生成物として扱う。

詳細は [theming-pipeline.md](./theming-pipeline.md) 参照。

## モード遷移と壁紙の独立性

```
              起動時 = desk-mode (monitors.conf の真)
                  │
       Super+Shift+B │  Super+Shift+D
                  ▼  ▲
             bed-mode (動的重ね)
```

```
壁紙変更 (Super+W)
  └─▶ wallset-backend.sh
        ├─ awww img <new>      (見た目を更新)
        ├─ matugen image <new> (色テンプレを生成)
        └─ hyprctl keyword source colors.conf  (Hyprland 色だけ外科的反映)
```

**重要**: 壁紙パイプラインは monitor 構成に一切触らない。bed-mode 中に壁紙を変えても bed-mode が維持される(`disable_autoreload` の効果)。

## 関連ドキュメント

- [File Structure](./file-structure.md) — ディレクトリレイアウト
- [Theming Pipeline](./theming-pipeline.md) — 壁紙 → 色 の流れ
- [Scripts Reference](./scripts.md) — 各スクリプトの責務
