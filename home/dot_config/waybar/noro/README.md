# noro-style waybar (アーカイブ + 移植元)

[noro-dotfiles](`hyprland-config-sample/noro-dotfiles/`) の waybar をベースに、当環境用に改変した版。

このフォルダの内容を `~/.config/waybar/{config.jsonc, style.css, custom styles/}` にコピーすれば noro 構成が active になる。anom に戻す時は `../anom/` を参照。

## 構成

```
noro/
├── config.jsonc             # モジュール定義 (固定)
├── style.css                # @import 3 行 (matugen / wallust / custom style)
└── custom styles/           # 20 種の style プリセット
    ├── aurora-ribbon.css    (wallust 不要)
    ├── capsule.css          (wallust 軽め)
    ├── original.css         (デフォルト、wallust 軽め)
    ├── modern-glass.css     (wallust ヘビー)
    ├── cyber-duo.css        (wallust 不要)
    ├── floating-glass-pills.css (wallust 不要)
    ├── glass-modern.css     (wallust 不要)
    ├── neon-glow-islands.css (wallust 不要)
    ├── soft-gradient.css    (wallust 不要)
    └── (他 11 種)
```

詳細解析: [hyprland-config-sample/noro-dotfiles/WAYBAR_ANALYSIS.md](../../../../hyprland-config-sample/noro-dotfiles/WAYBAR_ANALYSIS.md)

## noro 元実装との差分

| | noro 公式 | この環境 |
|---|---|---|
| `custom/nix` | `󰣇` (NixOS ロゴ) | **削除** (CachyOS のため) |
| `battery` | あり | **削除** (デスクトップ) |
| `backlight` | あり | **削除** (デスクトップ) |
| `custom/temperature`, `custom/light` | 室内 IoT 制御 | **削除** (不要) |
| `network.interface` | `wlo1` ハードコード | **削除** (auto) |
| `hyprland/workspaces.persistent-workspaces` | 6 個 | **5 個** (前路線維持) |
| `clock.actions.on-scroll-up/down` | `tz_up`/`tz_down` (重複定義) | `shift_up`/`shift_down` のみ |
| `style.css` 構成 | `waybar-set` が動的書換 | 静的 `@import` 3 行 (切替は手で) |
| `~/.cache/wallust/colors-waybar.css` | wallust が cache に出力 | **`~/.config/waybar/colors-waybar.css`** に直接出力 |
| `waybar-set` / `waybar-menu` | スタイル切替スクリプト | **未移植** (style.css の最終 @import を手で書換える運用) |

## style 切替方法 (手動)

```bash
# style.css の最後の @import 行を変更
sed -i 's|custom styles/[^"]*\.css|custom styles/capsule.css|' ~/.config/waybar/style.css

# waybar 再読込 (reload_style_on_change により style.css 変更で自動的に効くはずだが、
# @import 先の存在確認が走らない場合があるため SIGUSR2 で確実に)
pkill -SIGUSR2 waybar
```

## 依存

| 何が | どこ |
|---|---|
| matugen `[templates.waybar-anom]` (本来 anom 用、出力 path が `~/.config/waybar/colors.css` で noro でも使える) | `~/.config/matugen/config.toml` |
| wallust 設定 + waybar template | `~/.config/wallust/{wallust.toml, templates/waybar.css}` |
| メインフォント | JetBrains Nerd Font (`/usr/share/fonts/TTF/JetBrainsMono*Nerd*`) |
| pavucontrol | `pulseaudio` モジュール click で起動 |
| swaync | `custom/swaync` モジュール click で toggle |
| cava | bar 上で音声ビジュアライザー描画 |

## TODO / 未完

- `bluetooth` モジュール: 実機で BT 使ってないなら削除可
- `hyprland/window` モジュール: タイトル長いと bar が圧迫される。max-length 設定するか、削除
- style 切替スクリプト (`waybar-set` 相当) の移植 (今は手動編集)
