# プロジェクトメモ（mkiin/dotfiles）

NixOS & home-manager の個人 dotfiles。

## 構成

- `nixosConfigurations.nixos` … 実機 NixOS（host: `nixos` / user: `mkiin`）
- `homeConfigurations."mkiin@wsl"` … WSL 上の home-manager

## ディレクトリ構成と分離ルール

レイヤーで最上位を分ける:

- `nixos/` … システム(NixOS module)。`core/`(boot/nix/users/locale/… 基盤) + `hardware/` + `desktop/`
- `home-manager/` … ユーザー。`cli/` + `editor/` + `ai/` + `desktop/`
- `hosts/` … ホスト単位のエントリ。imports 組み立て・`hardware-configuration.nix`・`home-manager.users` 配線・`stateVersion` のみ。実体設定は書かない
- `lib/` … flake ヘルパー(`makeNixosConfig` 等)と `treefmt/`
- `packages/` `scripts/` `hooks/` `images/` … 補助

守るルール:

1. **1 機能 = 1 ディレクトリ = 1 `default.nix`**。関連する設定ファイル(lua/conf/テンプレート)は同じディレクトリに同居(コロケーション)。ゲーム等の並列物は `desktop/games/<name>/` のように 1 つ下の階層で分ける。
2. **集約 `default.nix` は原則カテゴリ第一階層**(`nixos/core`・`home-manager/{cli,desktop}` 等)に置き、`imports` 集約に徹する(ロジックは書かない)。`terminal/`・`games/` のように「同種の実装が並ぶだけで共通設定を持たない緩い括り」は中間集約を省き、親から `./games/<name>` を直接 import してよい(既存の `terminal/*` に倣う)。
3. **`packages.nix`** … 独立ディレクトリを作るほどでない、依存の薄いパッケージ束の置き場(`home-manager/{cli,desktop}/packages.nix`, `nixos/core/packages`)。
4. **system か user か**を先に決める。全体に効くもの(steam/ランチャー/フォント)は `nixos/`、ユーザー設定は `home-manager/`。本体=system・設定=user に割るものもある(例: vesktop)。
5. **ホスト差分は `hosts/` で吸収**。WSL は desktop を import しない等。共通は `nixos/`・`home-manager/` 側へ。

## 仕様として確定している挙動（指摘不要）

- waybar の `custom/idle_inhibitor` の on-click は Control Center を開くだけで、トグルではない。**これは意図した仕様**。トグルは Control Center 内の Caffeine ボタンで行う。「トグルになっていない」と指摘・修正提案しないこと。

## 【IMPORTANT・禁止】パッケージ宣言の置き場

**設計原則: パッケージは集約 `packages.nix` で「宣言（インストール）」し、機能ディレクトリの `default.nix` では「設定」だけを持つ。**

集約点（＝パッケージ宣言を書いてよい唯一の場所）:

- `home-manager/desktop/packages.nix`
- `home-manager/cli/packages.nix`
- `nixos/core/packages`

**禁止事項（IMPORTANT）:**

- **機能／設定ディレクトリの `default.nix` に `home.packages` / `environment.systemPackages` でパッケージを直書きしてはならない。** そこは `programs.*` / `services.*` の enable・`xdg.configFile`・systemd unit 等の**設定専用**。パッケージ本体は必ず集約 `packages.nix` 側へ置く。
- あるパッケージの「本体」を集約 `packages.nix`、その「設定」を同名サブフォルダ、という分離を崩さない。設定ディレクトリに本体パッケージを同居させるのは汚染とみなす。

**禁止でないもの（誤解防止）:**

- `programs.<foo>.enable = true;` / `services.<foo>.enable = true;` によるパッケージ導入は**正しい設定機構**。これは直書きではない。
- `programs.<foo>.package = ...;` によるパッケージ差し替えも設定の一部。
- systemd unit やスクリプト内の `${pkgs.X}/bin/...` 絶対パス参照は「宣言」ではない（PATH に載せていない）ので許容。ただし keybind/端末から叩くために PATH が要るなら、その本体は集約 `packages.nix` に入れる。

**是正事例（同じ過ちを繰り返さないこと）:** `pkgs.btop`（pyprland scratchpad 用）・`pkgs.pyprland`・`pkgs.mise` はいずれも設定ディレクトリの `default.nix` に直書きされていたのを集約 `packages.nix` へ移した。新規パッケージ追加時は必ず集約側へ書き、ディレクトリ側には設定のみ書くこと。

## コーディング規約

<importtants>
  - **コメントで語るなコードで語れ**
  - **コメントをだらだら書くな**。何をしているかはコードで分かる。コメントは「なぜそうしたか(非自明な理由・ハマりどころ・外部制約)」だけを 1〜2 行で。
  - `enable = true; # 有効化` のような逐条コメントや、設定項目を日本語で言い換えるだけのコメントは禁止。冗長なら消す。
  - Nix の未使用 let 束縛は treefmt の deadnix が検出する。`nix run .#fmt -- --fail-on-change` を build と併せて必ず通す。

</importtants>
### 【IMPORTANT・禁止】`../` で遡るパス参照

- **`../../../images/lock/lock.jpg` のように親ディレクトリへ遡る相対パス参照を書いてはならない。ユーザーが最も嫌うパス記述方法。** どこを指すか読めず、ファイル移動で黙って壊れる。
- 代替:
  - Nix でリポジトリ横断の参照: specialArgs の **`dotfilesDir` 定数**を起点に `lnk "${dotfilesDir}/images/lock/lock.jpg"`（`lnk` は Nix パス=同階層コロケーション / 絶対パス文字列の両対応）。store へ焼き込む場合は `"${inputs.self}/images/..."`。
  - Nix で同階層のコロケーション参照: `lnk ./file` は遡らないので可。
  - シェルスクリプト: `ROOT="$(git rev-parse --show-toplevel)"` を起点にした絶対パス。
- zsh の `cd ../..` 等の対話ナビゲーション用 abbr はパス「参照」ではないので対象外。

### 【IMPORTANT・禁止】waybar CSS の寸法・余白

- **waybar の CSS は `home-manager/desktop/waybar/style.nix` が単一情報源**。寸法（余白・角丸・幅）と質感の値はこのファイル先頭の `t`（セマンティックトークン）だけで定義する（GTK CSS に寸法用の変数機構が無いため Nix をプリプロセッサにしている）。`style.nix` の評価結果は home.activation が書き込み可能な実ファイル `style.css` として配布する（reload-css.sh の O_TRUNC 書き直しで reload_style_on_change を発火させるため symlink にしない）。反映は `nix run .#switch` のみ（手動生成スクリプトは無い）。色の `colors.css` は matugen が実行時に別途書き出す独立ファイル。
- **個別の CSS ルールにその場しのぎで px を足し引きして隙間を調整することを禁止する**。隙間の問題は「どのトークン（gapIsland / gapModule / padIslandX 等）の意味の話か」を特定してトークン側を変える。適切なトークンが無ければトークンを追加してから使う。

## ローカル用カスタムコマンド（flake apps）

リポジトリ直下で実行する。

| コマンド           | 内容                                                                                  |
| ------------------ | ------------------------------------------------------------------------------------- |
| `nix run .#update` | `nix flake update`（※ flake更新は基本 Renovate 任せ。これは緊急/特定input強制更新用） |
| `nix run .#build`  | nixos 構成をビルドだけする（反映しない）。`nom` でログ整形                            |
| `nix run .#switch` | `sudo nixos-rebuild switch --flake .#nixos` で反映する                                |
| `nix run .#fmt`    | treefmt で整形（`--fail-on-change` で確認も可）                                       |

定義は `flake.nix` の `apps.${system}`。`build` / `switch` は実機 NixOS（`.#nixos`）向け。
WSL を反映するときは `nix run nixpkgs#home-manager -- switch --flake .#mkiin@wsl`。

## 運用モデル: Renovate主導 / pull運用

flake の更新は **Renovate (Mend hosted) に任せる**。Renovate が `flake.lock` を
1 本の PR にまとめて更新し（`lockFileMaintenance`）、CI ビルドが緑になったものだけ
auto-merge されて main に入る。

- **flake 更新**: 自分で `nix flake update` しない。Renovate 任せ。`nix run .#update` は緊急時/特定input強制更新のみ。
- **ローカル反映**: `git pull && nix run .#switch` だけ。pull する lock は CI 検証済み。
- **設定変更（waybar 等）**: ローカルで `nix run .#build` で通してから push する。
  main 直 push は毎回 CI がフルビルドして遅いため、ローカル検証を先に。
- CI は後追いの保険。`concurrency: cancel-in-progress` で連続 push の古い実行は自動キャンセルされる。

## CI / 自動化

`.github/` の workflow・action と依存更新（Renovate）の詳細・ハマりどころは **`.github/ci-dependencies.md`** に記載。
要点だけ:

- flake input と GitHub Actions の更新は **Renovate (Mend hosted)** が担う。設定は `renovate.json`。`flake.lock` は `lockFileMaintenance` で 1 本 PR にまとめて更新、`uses:` のバージョンも同じ Renovate が追従する。
- auto-merge にはブランチ保護の必須チェック `lint` / `build (wsl-home)` / `build (nixos)` が全部緑である必要がある（release-age ゲートは廃止し、CI 緑を唯一のゲートにした）。
- auto-merge と branch protection は **public リポジトリだから Free で使える**（private + Free では両方使えないため public を維持）。
- hyprland は `cache.nixos.org` に無いため、`flake.nix` の `nixConfig` で `hyprland.cachix.org` を substituter に追加してある。外すと CI がソースビルドで 30 分タイムアウトする。
