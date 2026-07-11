# NIKKE 実行環境を AGL から切り離しセルフ完結化する

## 目的

現状 NIKKE は anime-games-launcher（AGL）が用意した実体
（`umu-run` / `dwproton` / 32G の wine prefix）を、自作ラッパー `scripts/nikke.sh`
が動的解決して起動している。起動ロジック（Lottery + watchdog + ACE reg tweak）は
既に自作で完結しているが、**実体のセットアップだけが AGL の GUI 操作に依存**する。

別PCへ移行するたびに AGL を入れ、GUI で NIKKE をポチポチ導入する手間を無くしたい。
あわせて AGL そのものを flake の依存から外し、旧環境の AGL 残骸（32G の prefix +
config/cache）をきれいに撤去できるようにする。

## 現状の実体（このPCで確認済み）

AGL パッケージ `~/.local/share/anime-games-launcher/packages/persistent/ff748b3efc59b21a-lua_proton/`
の中に、`nikke.sh` が要する 3 つが同居している:

- `umu-run`（419k / proton ランナー）
- `versions/dwproton-11.0-5-x86_64/`（ランナー本体）
- `prefixes/goddess_of_victory_nikke/pfx`（**32G / NIKKE 導入済み・ACE 登録済み**）

dwproton の取得元は AGL の integration 定義より判明:
`https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-11.0-5/dwproton-11.0-5-x86_64.tar.xz`
（dawn.wine から直接落とせる tar.xz = nix で固定可能）。

つまり「AGL」は実質この 3 つを置く箱でしかなく、起動は既に `nikke.sh` が担っている。
**AGL 切り離し = この 3 つを AGL のハッシュパスから独立させ、新PCで再現する**、に尽きる。

## 方針の確定事項

- ランナーは **dwproton を維持**（コミュニティ標準の推奨。GE-Proton へ替えると ACE 相性を新規に負う）。
- prefix（32G）は新PCでは **bootstrap = 公式インストーラ/miniloader を umu で走らせ再取得**
  （リポジトリに巨大データを持ち込まない・宣言的）。rclone 同期はしない。
- dwproton は **nix derivation（`fetchurl` + tar.xz 展開、version+hash 固定）** で焼き込む。
  → proton/wine 整備が `nix run .#switch` だけで済み、実行時 DL 不要。

## 各要素の調達方針

| 要素            | 現状（AGL依存）    | 切り離し後の調達                           | 置き場                                    |
| --------------- | ------------------ | ------------------------------------------ | ----------------------------------------- |
| `umu-run`       | AGL 同梱           | nix `umu-launcher`（既に packages 済）     | nix store / PATH                          |
| `dwproton`      | AGL が管理         | 新規 nix derivation（dawn.wine の tar.xz） | nix store（read-only）                    |
| `prefix`（32G） | AGL のハッシュパス | bootstrap で再取得                         | `~/.local/share/nikke/prefix`（安定パス） |

## 対象ファイル

- `flake.nix` … input `anime-games-launcher` を削除（`aagl` は honkers 用なので**残す**）
- `home-manager/desktop/packages.nix` … AGL 行を削除、dwproton derivation を参照
- `packages/`（新規） … dwproton の nix derivation（小さな `.nix`）
- `scripts/nikke.sh` … サブコマンド化 + パス参照を `~/.local/share/nikke` へ張り替え

> 注: `anime-games-launcher` を参照するのは `flake.nix`（input 定義）と
> `packages.nix` の 2 箇所のみ（grep 済み）。`aagl` は別 input で honkers が使うため無関係。

## 仕様

### 1. パス基準（AGL の外へ）

```
NIKKE_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/nikke"
PREFIX="$NIKKE_HOME/prefix"          # wine prefix（旧: AGL の .../pfx）
```

- `PROTONPATH` は **nix store の dwproton**（derivation の out パス）を指す。
- `UMU` は nix `umu-launcher` の `umu-run`（`command -v umu-run`）。
- `LAUNCHER="$PREFIX/drive_c/NIKKE/Launcher/nikke_launcher.exe"`、`REG="$PREFIX/system.reg"`。

現行 `nikke.sh` は AGL のハッシュディレクトリを `find` で解決していた分岐を撤去し、
上記の固定パスに単純化する。

### 2. `nikke` を 3 サブコマンドに

現行の起動ロジック（`preflight_steam` / `apply_reg_tweak` / `launch_once` /
`watchdog` / `cleanup_*`）は温存し、入口だけ分ける。

- **`nikke install`** … 新PC初回のみ。
  - `PREFIX` が未作成なら空 prefix を作る（umu が初回起動時に prefix を生成）。
  - 公式インストーラ（または旧 miniloader）を dwproton+umu で実行し、`C:\NIKKE` へ導入。
  - インストーラ実体の入手はスクリプト内で案内（URL: nikke-en.com の公式 installer /
    miniloader）。導入完了後は通常起動に引き継げる状態にする。
- **`nikke`（引数なし）** … 現行の起動 + Lottery + watchdog。
  - 冒頭で `LAUNCHER` の存在を確認し、無ければ「先に `nikke install` を実行」して終了。
- **`nikke clean`** … AGL 撤去用ワンショット。
  - `~/.local/share/anime-games-launcher`（32G）+ `~/.config/anime-games-launcher` +
    `~/.cache/anime-games-launcher` + desktop entry を削除。
  - 破壊的操作のため、対象一覧を表示し確認プロンプト（非対話時はスキップ）。

### 3. nix derivation（dwproton）

`packages/` 配下に dwproton を `fetchurl` で取得・展開する derivation を置き、集約
`packages.nix` から参照する（パッケージ宣言は集約点に置く規約に沿う）。

- `version = "11.0-5"`、`url = https://dawn.wine/.../dwproton-11.0-5-x86_64.tar.xz`、`sha256` 固定。
- tar.xz を展開し、`$out` 直下に `proton` 実行ファイルが来る配置にする（`PROTONPATH=$out`）。

### 4. flake / packages.nix

- `flake.nix`: `inputs.anime-games-launcher` ブロックを削除。
- `packages.nix`: `inputs.anime-games-launcher.packages...default` 行を削除、
  代わりに dwproton derivation を追加。`umu-launcher` と `nikke` ラッパーは維持。

## 移行後のフロー

- **新PC**: `git pull && nix run .#switch`（umu + dwproton + nikke が入る）
  → `nikke install`（数十GB DL・初回のみ）→ `nikke`。GUI 操作は一切なし。
- **旧PC撤去**: `nikke clean` で 32G ごと除去。

## 検証で潰すリスク（実装時に確認）

1. **umu を nixpkgs 版に替えて ACE が通るか**。現行は AGL 同梱 `umu-run` + `steam-run`。
   nixpkgs `umu-launcher`（-bwrap 版）で同等に起動できるか実機確認が要る
   （`nikke.sh` 内コメントの既知懸念: pkgs 版はランタイムコンテナの組み方が変わる）。
   NG なら `steam-run` ラップの要否含め起動コマンドを調整する。
2. **dwproton を nix store（read-only）から使えるか**。proton が自ディレクトリに
   書き込む場合は初回に writable パスへ複製してから `PROTONPATH` を向ける必要がある。
3. **install の入口**。公式インストーラと旧 miniloader（`NikkeMiniloader0.0.6.143.exe`）の
   どちらが Linux で安定か。コミュニティは「miniloader の方が DL/更新が安定」と報告。
   install サブコマンドはどちらを既定にするか実機で決める。
4. **ACE リジェクト率が上がった場合の Steam 文脈強化**。ACE 要件（Steam 常駐）は
   現行の `preflight_steam` で満たすが、リジェクトが増えるなら起動時に
   `STEAM_COMPAT_APP_ID`/`SteamAppId` を明示し「正規の Steam アプリ文脈」へ寄せて対処する。

## やらないこと（YAGNI）

- rclone による prefix 同期（bootstrap 方針のため不要）。
- GE-Proton への置換（dwproton 維持）。
- honkers 側（`aagl`）への変更（別系統・無関係）。
- **Steam 経由起動（非Steamゲーム登録 + `steam://rungameid`）への切り替え**。ACE が要るのは
  Steam 常駐（=residency、`preflight_steam` で充足）であり、Steam がプロセスを起こすこと
  ではない。umu は Steam の起動環境（SteamAppId / Steam Linux Runtime / proton）を再現する
  道具で、現行 umu 方式で実機起動できている。Lottery はどちらの方式でも残るため、
  `shortcuts.vdf` 注入で真の Steam 起動を得る上積みは不確実でコストに見合わず不採用。
