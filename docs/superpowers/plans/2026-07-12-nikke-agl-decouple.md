# NIKKE を AGL から切り離しセルフ完結化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** NIKKE の実行環境から anime-games-launcher（AGL）依存を剥がし、`nikke` コマンド 1 本（install / run / clean）と nix 宣言だけで完結させる。

**Architecture:** AGL が供給していた 3 要素を宣言的に置き換える。umu-run は nixpkgs `umu-launcher`、dwproton は新規 nix derivation（dawn.wine の tar.xz を version+hash 固定）、prefix は安定パス `~/.local/share/nikke/prefix` に持ち、新PCでは公式インストーラ再取得（bootstrap）、現行機では既存 AGL prefix を移設して再DLを回避する。起動ロジック（Lottery + watchdog + ACE reg tweak）は現行 `scripts/nikke.sh` をそのまま温存し、入口だけサブコマンド化する。

**Tech Stack:** Nix（stdenv.mkDerivation / fetchurl / writeShellScriptBin）、bash、umu-launcher、dwproton、steam-run。

## Global Constraints

- パッケージ宣言は集約 `home-manager/desktop/packages.nix` にのみ書く。機能ディレクトリの `default.nix` に `home.packages` 直書き禁止（derivation _定義_ ファイルの配置は可、_宣言_=callPackage は集約側）。
- `../` で親へ遡る相対パス参照は禁止。Nix は同階層 `./` コロケーション、シェルは絶対パス。
- コメントは「なぜ」を 1〜2 行。逐条コメント禁止。
- 各タスクの完了条件に `nix run .#fmt -- --fail-on-change` と `nix run .#build`（実機 nixos 構成のビルド）を必ず含める。deadnix / treefmt を通すこと。
- dwproton は `11.0-5` に固定（現行 prefix が同版で作られているため、移設した prefix と整合させる必要がある）。
- `aagl` input は honkers（`nixos/desktop/games/honkers`）が使うため**削除しない**。削除対象は `anime-games-launcher` input のみ。

---

## File Structure

- `home-manager/desktop/nikke/dwproton.nix` — **新規**。dwproton を fetchurl で取得・展開する derivation（定義のみ）。
- `home-manager/desktop/packages.nix` — **変更**。AGL 行を削除、dwproton を callPackage して宣言、`nikke` ラッパーに `NIKKE_PROTON` を注入。
- `flake.nix` — **変更**。input `anime-games-launcher` ブロックを削除。
- `scripts/nikke.sh` — **変更**。パス解決を安定パス + `$NIKKE_PROTON` へ張り替え、`main` をサブコマンド dispatcher（install / run / clean）に再構成。

---

## Task 1: dwproton の nix derivation を追加

**Files:**

- Create: `home-manager/desktop/nikke/dwproton.nix`
- Modify: `home-manager/desktop/packages.nix`

**Interfaces:**

- Produces: `pkgs.callPackage ./nikke/dwproton.nix { }` が dwproton を展開した store パス（`$out/proton` が実行ファイル）を返す。`packages.nix` 内の `dwproton` 束縛として後続タスクが参照する。

- [ ] **Step 1: dwproton tarball の SRI ハッシュを取得**

Run:

```bash
nix store prefetch-file --hash-type sha256 \
  https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-11.0-5/dwproton-11.0-5-x86_64.tar.xz
```

Expected: 末尾に `hash: sha256-XXXX...=` の形で SRI ハッシュが出る。この値を次の Step で `hash =` に貼る（数百MB DL のため時間がかかる）。

- [ ] **Step 2: derivation を作成**

`home-manager/desktop/nikke/dwproton.nix`:

```nix
{
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "dwproton";
  version = "11.0-5";

  src = fetchurl {
    url = "https://dawn.wine/dawn-winery/dwproton/releases/download/dwproton-${version}/dwproton-${version}-x86_64.tar.xz";
    hash = "sha256-REPLACE_WITH_STEP1_OUTPUT";
  };

  # umu-run を steam-run(FHS)でくるんで実行する運用なので、proton バイナリは無改変で保持する。
  # autoPatchelf/strip を掛けると AGL の既知良好構成と挙動が変わるため一切いじらない。
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -a . $out/
    runHook postInstall
  '';

  meta.platforms = [ "x86_64-linux" ];
}
```

（`sha256-REPLACE_WITH_STEP1_OUTPUT` を Step 1 の実値に置換する。）

- [ ] **Step 3: packages.nix で dwproton を宣言し `nikke` ラッパーに注入**

`home-manager/desktop/packages.nix` を次の形に変更する。`let` で dwproton を束ね、AGL 行はこの時点では残したまま（並存でビルド緑を保つ）、ラッパーに `NIKKE_PROTON` を渡す:

```nix
{ inputs, pkgs, ... }:
let
  dwproton = pkgs.callPackage ./nikke/dwproton.nix { };
in
{
  home.packages = with pkgs; [
    # ... 既存パッケージ列はそのまま ...
    # anime-games-launcher（Task 5 で削除する。今は並存）
    inputs.anime-games-launcher.packages.${pkgs.system}.default
    umu-launcher
    # NIKKE 起動ラッパー。nix store の dwproton を NIKKE_PROTON で渡す。
    (pkgs.writeShellScriptBin "nikke" ''
      export NIKKE_PROTON=${dwproton}
      ${builtins.readFile "${inputs.self}/scripts/nikke.sh"}
    '')
  ];
}
```

注: `''` リテラル内で Nix が解釈するのは `${dwproton}` と `${builtins.readFile ...}` の 2 つだけ。readFile が返す文字列は再スキャンされないため、`nikke.sh` 内の bash の `${...}` 展開は影響を受けない。

- [ ] **Step 4: fmt とビルドを通す**

Run:

```bash
nix run .#fmt -- --fail-on-change
nix run .#build
```

Expected: どちらも成功（緑）。dwproton が数百MB DL される。deadnix 警告なし。

- [ ] **Step 5: dwproton の中身を検証**

Run:

```bash
ls "$(nix eval --raw .#nixosConfigurations.nixos.config.home-manager.users.mkiin.home.path 2>/dev/null)" 2>/dev/null || \
nix build --no-link --print-out-paths --expr 'let f = import ./home-manager/desktop/nikke/dwproton.nix; p = (import <nixpkgs> {}); in p.callPackage f {}'
```

より簡便には:

```bash
DWP=$(nix build --no-link --print-out-paths --impure --expr '(import <nixpkgs> {}).callPackage ./home-manager/desktop/nikke/dwproton.nix {}')
ls "$DWP/proton"
```

Expected: `$DWP/proton`（proton 実行ファイル）が存在する。

- [ ] **Step 6: コミット**

```bash
git add home-manager/desktop/nikke/dwproton.nix home-manager/desktop/packages.nix
git commit -m "feat(nikke): dwproton を nix derivation 化しラッパーへ注入"
```

---

## Task 2: nikke.sh をサブコマンド化し run を安定パスへ移す

**Files:**

- Modify: `scripts/nikke.sh`

**Interfaces:**

- Consumes: 環境変数 `NIKKE_PROTON`（Task 1 の dwproton store パス）。
- Produces: `nikke`（=`nikke run`）が `~/.local/share/nikke/prefix` の prefix と `$NIKKE_PROTON` で起動する。`cmd_run` / `usage` / `main` dispatcher と、共有変数 `NIKKE_HOME` / `PREFIX` / `PROTON` / `LAUNCHER` / `REG` / `UMU` / `STEAMRUN` を後続タスク（install / clean）が参照する。

- [ ] **Step 1: パス解決ブロックを AGL 非依存へ差し替え**

`scripts/nikke.sh` の `# --- パス解決(AGL 更新で...) ---` から始まるブロック（`AGL=...` 〜 `[ -x "$UMU" ] || die "umu-run が見つからない"` まで）を丸ごと次に置換する。**インストーラ未導入でも通るよう、`LAUNCHER`/`PROTON` の存在アサートはここから外し、`cmd_run` 側へ移す**:

```bash
# --- パス解決(AGL 非依存。安定パス + nix store の dwproton) ---
# 実体は AGL のハッシュパスではなく XDG 配下の固定パスに置く。dwproton は nix が
# NIKKE_PROTON で渡す(= ラッパー経由起動が前提)。umu は nixpkgs umu-launcher を使う。
NIKKE_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/nikke"
PREFIX="$NIKKE_HOME/prefix"
PROTON="${NIKKE_PROTON:-}"
LAUNCHER="$PREFIX/drive_c/NIKKE/Launcher/nikke_launcher.exe"
REG="$PREFIX/system.reg"
UMU="$(command -v umu-run || true)"
STEAMRUN="$(command -v steam-run || true)"
[ -x "$UMU" ] || die "umu-run が見つからない(nixpkgs umu-launcher を導入してください)"
```

- [ ] **Step 2: 現行 `main()` を `cmd_run()` にリネームし run ガードを追加**

`scripts/nikke.sh` 末尾の `main() {` を `cmd_run() {` に変え、関数冒頭（`log "prefix: $PREFIX"` の直前）に未導入ガードを挿入する:

```bash
cmd_run() {
  [ -n "$PROTON" ] || die "NIKKE_PROTON 未設定。端末直叩きでなく nix の nikke ラッパー経由で起動してください"
  [ -d "$PROTON" ] || die "dwproton が無い: $PROTON"
  [ -e "$LAUNCHER" ] || die "NIKKE 未インストール。先に 'nikke install' を実行してください"
  log "prefix: $PREFIX"
  log "proton: $(basename "$PROTON")"
  preflight_steam
  apply_reg_tweak
  local n
  for n in $(seq 1 "$MAX_RETRIES"); do
    log "起動試行 $n/$MAX_RETRIES"
    if launch_once; then
      watchdog || true
      exit 0
    fi
    cleanup_session
    warn "リトライします..."
    sleep 2
  done
  die "$MAX_RETRIES 回試みても ACE の初期化に失敗。時間を置くか、Steam 再起動後に再試行してください。"
}
```

（元の `main()` 本体と同一。冒頭 3 行のガードだけ追加。）

- [ ] **Step 3: `usage` と dispatcher `main` を末尾に追加**

`cmd_run` 定義の後、ファイル末尾の `main "$@"` を次に置き換える:

```bash
usage() {
  cat <<'EOF'
usage: nikke [run|install|clean]
  run     (既定) NIKKE を起動(Lottery + watchdog)
  install 初回セットアップ。既存 AGL prefix があれば移設、無ければ再DL
  clean   AGL の残骸(prefix/config/cache/desktop entry)を撤去
EOF
}

main() {
  case "${1:-run}" in
  run | "") cmd_run ;;
  install) cmd_install ;;
  clean) cmd_clean ;;
  -h | --help | help) usage ;;
  *)
    usage
    exit 1
    ;;
  esac
}

main "$@"
```

（`cmd_install` / `cmd_clean` は Task 3 / 4 で定義する。この時点で `nikke install`/`nikke clean` を呼ぶと未定義エラーになるが、Task 5 のビルド前に両方定義されるので問題ない。構文チェックは通る。）

- [ ] **Step 4: bash 構文チェック**

Run:

```bash
bash -n scripts/nikke.sh && echo OK
```

Expected: `OK`（構文エラーなし）。

- [ ] **Step 5: run ガードのスモークテスト（未導入時に install を促す）**

Run:

```bash
tmp=$(mktemp -d)
XDG_DATA_HOME="$tmp" NIKKE_PROTON="$tmp/fakeproton" bash scripts/nikke.sh run; echo "exit=$?"
mkdir -p "$tmp/fakeproton"
XDG_DATA_HOME="$tmp" NIKKE_PROTON="$tmp/fakeproton" bash scripts/nikke.sh run; echo "exit=$?"
rm -rf "$tmp"
```

Expected: 1 回目は「dwproton が無い」で非0終了、2 回目は「NIKKE 未インストール。先に 'nikke install'」で非0終了（launch には進まない）。

- [ ] **Step 6: fmt を通す（shell も treefmt 対象）**

Run:

```bash
nix run .#fmt -- --fail-on-change
```

Expected: 成功。shfmt 整形差分なし。

- [ ] **Step 7: コミット**

```bash
git add scripts/nikke.sh
git commit -m "refactor(nikke): 安定パス化しサブコマンド dispatcher を導入"
```

---

## Task 3: `nikke install`（既存 prefix 移設 / bootstrap 再DL）

**Files:**

- Modify: `scripts/nikke.sh`

**Interfaces:**

- Consumes: `NIKKE_HOME` / `PREFIX` / `LAUNCHER` / `PROTON` / `UMU` / `STEAMRUN`（Task 2）、`preflight_steam` / `log` / `warn` / `die`（既存）。
- Produces: `cmd_install`（`main` dispatcher が呼ぶ）。実行後 `$LAUNCHER` が存在する状態にする。

- [ ] **Step 1: `cmd_install` と `bootstrap_install` を追加**

`scripts/nikke.sh` の `usage()` 定義の直前に追加する:

```bash
# 公式ミニローダ(コミュニティ報告では Linux での DL/更新が最新版より安定)。
# ローカルの exe を使いたい場合は NIKKE_INSTALLER_URL に file:// か別URLを指定。
INSTALLER_URL="${NIKKE_INSTALLER_URL:-https://nikke-en.com/NikkeMiniloader0.0.6.143.exe}"

# 空 prefix にインストーラを流して C:\NIKKE へ導入する(新PC用)。
bootstrap_install() {
  command -v curl >/dev/null 2>&1 || die "curl が無い。手動で prefix を用意するか curl を導入してください"
  mkdir -p "$NIKKE_HOME"
  local installer="$NIKKE_HOME/nikke_installer.exe"
  if [ ! -e "$installer" ]; then
    log "インストーラ取得: $INSTALLER_URL"
    curl -fL "$INSTALLER_URL" -o "$installer" || die "インストーラ取得に失敗: $INSTALLER_URL"
  fi
  preflight_steam
  log "インストーラ起動。ウィザードで導入先を C:\\NIKKE にしてください(完了まで数十GB DL)。"
  GAMEID=umu-nikke PROTON_USE_WOW64=1 PROTONPATH="$PROTON" WINEPREFIX="$PREFIX" \
    ${STEAMRUN:+"$STEAMRUN"} "$UMU" "$installer"
  [ -e "$LAUNCHER" ] || warn "導入後に $LAUNCHER が見つかりません。導入先が C:\\NIKKE か確認してください。"
}

cmd_install() {
  [ -n "$PROTON" ] && [ -d "$PROTON" ] || die "dwproton が無い。nikke ラッパー経由で実行してください"
  if [ -e "$LAUNCHER" ]; then
    log "既にインストール済み: $LAUNCHER"
    return 0
  fi
  # 現行機では AGL が作った 32G prefix を再DLせず安定パスへ移設する。
  local agl_pfx
  agl_pfx=$(find "$HOME/.local/share/anime-games-launcher/packages/persistent" \
    -maxdepth 4 -type d -path '*goddess_of_victory_nikke/pfx' 2>/dev/null | head -1)
  if [ -n "$agl_pfx" ] && [ -e "$agl_pfx/drive_c/NIKKE/Launcher/nikke_launcher.exe" ]; then
    log "既存 AGL prefix を検出 → 安定パスへ移設(再DL不要)"
    mkdir -p "$NIKKE_HOME"
    mv "$agl_pfx" "$PREFIX"
    log "移設完了: $PREFIX。AGL 残骸は 'nikke clean' で撤去できます。"
    return 0
  fi
  bootstrap_install
}
```

- [ ] **Step 2: bash 構文チェック**

Run:

```bash
bash -n scripts/nikke.sh && echo OK
```

Expected: `OK`。

- [ ] **Step 3: 冪等性のスモークテスト（導入済み検知）**

Run:

```bash
tmp=$(mktemp -d)
mkdir -p "$tmp/prefix/drive_c/NIKKE/Launcher" "$tmp/fakeproton"
: > "$tmp/prefix/drive_c/NIKKE/Launcher/nikke_launcher.exe"
XDG_DATA_HOME="$tmp" NIKKE_PROTON="$tmp/fakeproton" bash scripts/nikke.sh install; echo "exit=$?"
rm -rf "$tmp"
```

Expected: 「既にインストール済み」を表示して `exit=0`（curl も umu も呼ばない）。

- [ ] **Step 4: fmt を通す**

Run:

```bash
nix run .#fmt -- --fail-on-change
```

Expected: 成功。

- [ ] **Step 5: コミット**

```bash
git add scripts/nikke.sh
git commit -m "feat(nikke): install サブコマンド(既存prefix移設/bootstrap再DL)"
```

---

## Task 4: `nikke clean`（AGL 残骸の安全な撤去）

**Files:**

- Modify: `scripts/nikke.sh`

**Interfaces:**

- Consumes: `LAUNCHER`（Task 2）、`log` / `warn`（既存）。
- Produces: `cmd_clean`（`main` dispatcher が呼ぶ）。

- [ ] **Step 1: `cmd_clean` を追加**

`scripts/nikke.sh` の `cmd_install` 定義の直後に追加する:

```bash
cmd_clean() {
  local agl="$HOME/.local/share/anime-games-launcher"
  # 未移設の NIKKE データを巻き込み削除しないよう警告(先に install で移設させる)。
  if [ ! -e "$LAUNCHER" ] &&
    find "$agl" -maxdepth 8 -path '*goddess_of_victory_nikke/pfx/drive_c/NIKKE*' -print -quit 2>/dev/null | grep -q .; then
    warn "AGL 内に未移設の NIKKE データがあります。先に 'nikke install'(自動移設)を実行しないと再DLになります。"
  fi
  local targets=(
    "$agl"
    "$HOME/.config/anime-games-launcher"
    "$HOME/.cache/anime-games-launcher"
    "$HOME/.local/share/applications/anime-games-launcher.desktop"
  )
  local found=() t
  for t in "${targets[@]}"; do
    [ -e "$t" ] && {
      printf '  %s (%s)\n' "$t" "$(du -sh "$t" 2>/dev/null | cut -f1)"
      found+=("$t")
    }
  done
  if [ "${#found[@]}" -eq 0 ]; then
    log "AGL 残骸なし。何もしません。"
    return 0
  fi
  log "上記を削除します。"
  if [ -t 0 ]; then
    read -r -p "本当に削除しますか? [y/N] " ans
    case "$ans" in
    [yY]*) ;;
    *)
      log "中止"
      return 0
      ;;
    esac
  else
    warn "非対話のためスキップ(対話端末で実行してください)"
    return 0
  fi
  for t in "${found[@]}"; do
    rm -rf "$t" && log "削除: $t"
  done
}
```

- [ ] **Step 2: bash 構文チェック**

Run:

```bash
bash -n scripts/nikke.sh && echo OK
```

Expected: `OK`。

- [ ] **Step 3: 残骸なし時のスモークテスト**

Run:

```bash
tmp=$(mktemp -d)
HOME="$tmp" XDG_DATA_HOME="$tmp/.local/share" NIKKE_PROTON="$tmp/fakeproton" \
  bash scripts/nikke.sh clean </dev/null; echo "exit=$?"
rm -rf "$tmp"
```

Expected: 「AGL 残骸なし。何もしません。」で `exit=0`（削除対象を作っていないため何も消さない）。

- [ ] **Step 4: 非対話ガードのスモークテスト（残骸ありでも消さない）**

Run:

```bash
tmp=$(mktemp -d)
mkdir -p "$tmp/.local/share/anime-games-launcher/x"
: > "$tmp/.local/share/anime-games-launcher/x/dummy"
HOME="$tmp" XDG_DATA_HOME="$tmp/.local/share" NIKKE_PROTON="$tmp/fp" \
  bash scripts/nikke.sh clean </dev/null; echo "exit=$?"
ls -d "$tmp/.local/share/anime-games-launcher" && echo "STILL EXISTS(正しい)"
rm -rf "$tmp"
```

Expected: 対象を列挙するが `</dev/null`（非対話）なのでスキップし、ディレクトリは残る（`STILL EXISTS(正しい)`）。

- [ ] **Step 5: fmt を通す**

Run:

```bash
nix run .#fmt -- --fail-on-change
```

Expected: 成功。

- [ ] **Step 6: コミット**

```bash
git add scripts/nikke.sh
git commit -m "feat(nikke): clean サブコマンド(AGL残骸を安全に撤去)"
```

---

## Task 5: AGL 依存を flake / packages から削除

**Files:**

- Modify: `flake.nix`
- Modify: `home-manager/desktop/packages.nix`

**Interfaces:**

- Consumes: なし（削除のみ）。この時点で `nikke.sh` は AGL のパス/パッケージを一切参照しない（Task 2〜4 で除去済み）。

- [ ] **Step 1: flake.nix の input を削除**

`flake.nix` から次のブロックを削除する（`aagl` は残す）:

```nix
    anime-games-launcher = {
      url = "github:an-anime-team/anime-games-launcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

- [ ] **Step 2: packages.nix の AGL 行を削除**

`home-manager/desktop/packages.nix` から次の 2 行（コメント + パッケージ）を削除する。`umu-launcher` と dwproton ラッパーは残す:

```nix
    # anime-games-launcher（Task 5 で削除する。今は並存）
    inputs.anime-games-launcher.packages.${pkgs.system}.default
```

- [ ] **Step 3: 参照が残っていないか確認**

Run:

```bash
grep -rn "anime-games-launcher" --include="*.nix" . || echo "参照なし(OK)"
```

Expected: `参照なし(OK)`。

- [ ] **Step 4: lock を更新して fmt / build を通す**

Run:

```bash
nix flake lock
nix run .#fmt -- --fail-on-change
nix run .#build
```

Expected: すべて成功。`flake.lock` から `anime-games-launcher` ノードが消える。deadnix 警告なし。

- [ ] **Step 5: コミット**

```bash
git add flake.nix home-manager/desktop/packages.nix flake.lock
git commit -m "feat(nikke): AGL(anime-games-launcher)依存を撤去"
```

---

## Task 6: 実機受け入れ（現行機での移行と起動確認）

> **手動タスク。実機 NixOS 上で行う。ゲーム本体データ（数十GB）と実際の起動を伴うため自動化しない。**

**Files:** なし（運用確認）。

- [ ] **Step 1: 反映**

Run:

```bash
nix run .#switch
```

Expected: 成功。`nikke` が PATH に載る（`command -v nikke`）。

- [ ] **Step 2: 既存 AGL prefix を移設**

Run:

```bash
nikke install
```

Expected: 「既存 AGL prefix を検出 → 安定パスへ移設」と表示され、`~/.local/share/nikke/prefix/drive_c/NIKKE/Launcher/nikke_launcher.exe` が存在する。再DLは走らない。

Run（確認）:

```bash
ls "$HOME/.local/share/nikke/prefix/drive_c/NIKKE/Launcher/nikke_launcher.exe"
```

Expected: パスが存在する。

- [ ] **Step 3: 起動確認（リスク #1: nixpkgs umu で ACE が通るか）**

Run:

```bash
nikke
```

Expected: Lottery が回り、NIKKE 本体ウィンドウが出て watchdog に入る。

失敗時の切り分け:

- ACE 初期化が通らない/リジェクトが多い → spec のリスク #4。`launch_once`（`scripts/nikke.sh`）の起動 env に `STEAM_COMPAT_APP_ID`/`SteamAppId` を追加して Steam アプリ文脈を明示する。
- proton が nix store（read-only）に書けず失敗 → リスク #2。`$PROTON` を書き込み可能パスへ複製してから `PROTONPATH` を向ける実装に変更（`cmd_run` 冒頭で writable コピーを用意）。
- 上記いずれも実機ログを見て `scripts/nikke.sh` を追修正し、再度 fmt/build/commit する。

- [ ] **Step 4: AGL 残骸を撤去**

Run:

```bash
nikke clean
```

Expected: `~/.local/share/anime-games-launcher`（移設後の残り）・config・cache・desktop entry が列挙され、`y` で削除される。移設済みのため NIKKE データ巻き込み警告は出ない。

- [ ] **Step 5: 撤去後の再起動確認**

Run:

```bash
nikke
```

Expected: AGL 削除後も安定パスの prefix で正常に起動する。

---

## Self-Review（記入済み）

- **Spec coverage:** umu=nixpkgs（Task 5 で AGL 削除・umu 残置）/ dwproton=nix derivation（Task 1）/ prefix=安定パス + bootstrap（Task 2,3）/ install・run・clean 3 サブコマンド（Task 2,3,4）/ flake・packages 変更（Task 1,5）/ 検証リスク #1,#2,#4（Task 6 Step 3）/ install 入口 miniloader 既定・リスク #3（Task 3 Step 1, `INSTALLER_URL`）。全項目にタスク対応あり。
- **Placeholder scan:** `sha256-REPLACE_WITH_STEP1_OUTPUT` のみ意図的な要記入箇所で、Step 1 に取得コマンドを明示済み（TODO ではなく手順化）。他に未定義参照なし。
- **Type/名前整合:** `cmd_run` / `cmd_install` / `cmd_clean` / `bootstrap_install` / `usage` / `main`、変数 `NIKKE_HOME` / `PREFIX` / `PROTON` / `LAUNCHER` / `REG` / `UMU` / `STEAMRUN` / `INSTALLER_URL` はタスク間で一貫。`NIKKE_PROTON`（env）→ `PROTON`（変数）の受け渡しも一致。
