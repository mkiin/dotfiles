# herdr の Nix 管理・skill 連携・vim 化・マニュアル 設計

- 状態: 承認済み（設計フェーズ）
- 対象リポジトリ: `mkiin/dotfiles`（NixOS & home-manager）
- 日付: 2026-07-05

## 背景と目的

[herdr](https://github.com/ogulcancelik/herdr) は tmux を AI コーディングエージェント向けに作り直した Rust 製のターミナルマルチプレクサである。ワークスペース / タブ / ペインを持ち、各ペインを実ターミナルとして扱いつつ、サイドバーで各エージェントの状態（🔴 blocked / 🟡 working / 🔵 done / 🟢 idle）を集約表示する。detach してもエージェントは生き続け、別ターミナルや ssh 越しに再接続できる。

本設計の目的は次の4つ。

1. herdr を dotfiles の Nix 管理下に置く（宣言的インストール）。
2. herdr の agent skill を、既存の `programs.agent-skills`（agent-skills-nix）経由で claude / codex に配布する。
3. vim ライクなキーバインドを config で設定する。
4. 日本語のチュートリアル的マニュアルを用意する。

## 方針と配置

herdr は「ユーザーがターミナルで叩く CLI（マルチプレクサ）」なので `home-manager/cli/` 配下に置き、NixOS・WSL 両方で共有する。プロジェクト規約「1 機能 = 1 ディレクトリ = 1 default.nix」「パッケージ本体は集約 `packages.nix` でのみ宣言し、機能ディレクトリは設定専用」を厳守する。

```
flake.nix                          # inputs に herdr を追加
home-manager/cli/
  packages.nix                     # herdr パッケージ本体を「宣言」（集約点）
  herdr/
    default.nix                    # 設定のみ: xdg.configFile で config.toml 生成
    MANUAL.md                      # 日本語チュートリアルマニュアル（コロケーション）
home-manager/ai/agent-skills/
  default.nix                      # herdr skill ソースを1件追加・enable
```

- パッケージ本体は `home-manager/cli/packages.nix` に置く。機能ディレクトリ `cli/herdr/default.nix` には `home.packages` を書かない。
- 設定は `cli/herdr/default.nix` の `xdg.configFile."herdr/config.toml"` で管理する（herdr 用の home-manager モジュールは存在しないため）。
- `cli/herdr` を親（`home-manager/cli` の集約 `default.nix`）から import する配線を追加する。

## flake input

herdr リポジトリは自前 flake（`packages.default` / `overlays.default` / `apps.default`）を持つ。flake input を1本追加し、「パッケージ」と「skill ソース」の両方で使い回す。

```nix
herdr.url = "github:ogulcancelik/herdr";
herdr.inputs.nixpkgs.follows = "nixpkgs";
```

lock 更新は既存の Bot 運用（release-age 3日 + CI ビルド緑）に自動で乗る。

パッケージは `inputs.herdr.packages.${system}.default` を `cli/packages.nix` の `home.packages` に加える。

代替案として nixpkgs に herdr が入っていれば `pkgs.herdr` 直参照も可能だが、新しめのツールで収録の確実性に欠けるため flake input を採用する。

## skill の配線

herdr の `SKILL.md` はリポジトリ直下にあり、agent-skills-nix が期待する `skills/<名前>/SKILL.md` 構造ではない。そこで小さな derivation で `herdr/SKILL.md` 構造に包んでからソース登録する。手動コピーせず flake input に追従させることで陳腐化を防ぐ。

```nix
# home-manager/ai/agent-skills/default.nix 内（pkgs を module 引数に追加）
herdr-skill = pkgs.runCommand "herdr-skill" { } ''
  mkdir -p $out/herdr
  cp ${inputs.herdr}/SKILL.md $out/herdr/SKILL.md
'';
```

`programs.agent-skills.sources` に次を追加する。

```nix
herdr = {
  path = herdr-skill;
  subdir = ".";
  filter.maxDepth = 1;
};
```

`skills.enable` に `"herdr"` を追加する。既存の `targets.claude` / `targets.codex` 両方に配布される。この skill は `HERDR_ENV=1`（herdr 管理ペイン内）のときだけ herdr を CLI 操作するもので、外側からの誤操作を防ぐガードを内蔵している。

## キーバインド（config.toml）

方針: `ctrl+b` プレフィックスは残しつつ、prefix 無しの `ctrl+alt+hjkl` 等の直接 chord を併設する。これは herdr 公式が主要ターミナル / デスクトップ環境のショートカットを調査したうえで「衝突しにくい」と推奨する prefix-free 設定である。コピーモードは herdr 既定で既に vim 的（`hjkl` / `w`・`b`・`e` / `v` / `y`）なのでそのまま活かす。

config は `pkgs.formats.toml` を使い、Nix の attrset から型安全に生成する（手書き文字列を避ける）。生成結果の要点は次のとおり。

```toml
onboarding = false

[keys]
focus_pane_left  = ["prefix+h", "ctrl+alt+h"]
focus_pane_down  = ["prefix+j", "ctrl+alt+j"]
focus_pane_up    = ["prefix+k", "ctrl+alt+k"]
focus_pane_right = ["prefix+l", "ctrl+alt+l"]
navigate_pane_left  = "h"
navigate_pane_down  = "j"
navigate_pane_up    = "k"
navigate_pane_right = "l"
new_tab          = ["prefix+c", "ctrl+alt+c"]
previous_tab     = ["prefix+p", "ctrl+alt+["]
next_tab         = ["prefix+n", "ctrl+alt+]"]
split_vertical   = ["prefix+v", "ctrl+alt+d"]
split_horizontal = ["prefix+minus", "ctrl+alt+shift+d"]
zoom             = ["prefix+z", "ctrl+alt+z"]
```

制約メモ:

- `navigate_pane_*` は navigate モード専用フィールドで、素のキー（`h`/`j`/`k`/`l`）のみ許され、`prefix+` は不可。
- 直接 chord は `ctrl+alt+arrows` / `ctrl+alt+t` などデスクトップ環境が占有するものを避ける。`ctrl+alt+l` は KDE ではロック画面に取られるが、本環境は Hyprland で当該 bind が無いため `focus_pane_right` に採用する（Hyprland のキーバインドは `SUPER+CTRL+*` 系で衝突しない）。上記は herdr 公式の推奨セットに沿っている。
- プレフィックス自体を変えたい場合は `prefix = "ctrl+a"` を足すだけで差し替え可能（本設計の既定は `ctrl+b` 据え置き）。

## マニュアル（`home-manager/cli/herdr/MANUAL.md`）

日本語のチュートリアル。`write-sentence` スキルに従って執筆する。構成は次のとおり。

1. herdr とは（tmux をエージェント向けに作り直したもの、という一言と要点）
2. 起動と最初の一歩（`herdr` → ペインでエージェント起動、サイドバーの状態表示）
3. プレフィックスの考え方（`ctrl+b` → キー）と、この設定での vim chord 早見表
4. 最初に覚える5つ（新タブ / 分割 / ペイン移動 / ワークスペース / detach）
5. コピーモード（vim 操作）
6. worktree・ワークスペース運用
7. skill 連携（`HERDR_ENV=1` でエージェントが herdr を操作できる話）
8. detach / reattach とトラブル時（`herdr server reload-config` など）

## 検証と反映

- NixOS: `nix run .#build` で検証してから `nix run .#switch`
- WSL: `nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl`
- 整形確認: `nix run .#fmt -- --fail-on-change`

build と fmt を必ず通してから push する（ローカル検証先行の運用）。

## スコープ外（YAGNI）

- lazygit 等のカスタムコマンドキーバインド（`[[keys.command]]`）は今回入れない。必要になったら追加。
- テーマ / 通知 / リモート attach の詳細設定は既定のまま。
- herdr integration（`herdr integration install`）のネイティブ復元連携は今回スコープ外。
