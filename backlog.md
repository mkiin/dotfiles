# Backlog

後回しにした検討事項。優先度順ではなく、発生順に追記。

## matugen パイプラインの script 化

**文脈**: `hypr-audit.md` Section 4.3 / Section 5 の ★★★ タスク。

**現状**:
- 色生成は `~/.config/awww/scripts/wallpaper-init.sh` (swww) 内に隠蔽
- 壁紙変更→色再生成の keybind 無し、起動時にしか走らない
- matugen の config.toml / templates は存在するが、post_hook や呼び出し経路が追跡しづらい

**やること**:
- `~/.config/hypr/scripts/gen-colors.sh` を作成（audit Section 4.3 Step 1 のスニペット参照）
- `matugen/config.toml` に `post_hook` 明記
- `keybinds.conf` に `bind = $mainMod, W, exec, gen-colors.sh <wallpaper>` を追加（Walker 経由の壁紙選択と連動）
- `autostart.conf` で明示的に初期色生成

**前提**: autostart.conf 改善と抱き合わせ。swww (旧awww) との役割分担を整理してから着手。

---

## packages/pacman.txt の baseline 差し引き運用の検証

**文脈**: `sync-packages.sh` は `pacman -Qqen` から `cachyos-baseline.txt` を差し引いて出力する設計。

**不安点**:
- 新規インストールした `zen-browser-bin` / `xdg-desktop-portal-gtk` 等が baseline に含まれていないことを暗黙前提にしている
- baseline は「CachyOS 初回インストール直後の `pacman.log` から抽出」と `sync-packages.sh` に記載あり → 初回時点で何が入っていたかに依存
- 新マシン構築時に `pacman -S --needed - < packages/pacman.txt` で復元する際、baseline に含まれるものが別途必要になる

**やること**:
- 新マシンセットアップ時に `cachyos-baseline.txt` を事前に入れる手順を SETUP.md に明記
- あるいは、baseline 差し引きを止めて raw dump 方式に切り替えるかを再検討
- `sync-packages.sh` の差し引きロジックが意図通り動いているか、実際に `comm -23` の出力を検証
