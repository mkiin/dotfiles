# upscayl-cli home-manager モジュール Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upscayl の推論バイナリを Electron 抜きの CLI ツール `upscayl-cli` として home-manager（ユーザースコープ）に宣言的導入する。

**Architecture:** プリビルドの `upscayl-bin` と `digital-art-4x` モデルを `fetchurl` で個別取得し、`autoPatchelfHook` で NixOS 向けに rpath 修正、`makeWrapper` で GPU ドライバパスと既定モデルを焼き込んだ `upscayl-cli` を生成する。派生を `pkg.nix`（callPackage 形式）に分離し、`default.nix`（home-manager モジュール）が `home.packages` に登録する。

**Tech Stack:** Nix (stdenv.mkDerivation, fetchurl, autoPatchelfHook, makeWrapper), home-manager, NixOS flake (`nixosConfigurations.nixos`)。

## Global Constraints

- バージョン pin: `v2.15.1`（`raw.githubusercontent.com/upscayl/upscayl/v2.15.1/...`）。
- 対応プラットフォーム: `x86_64-linux` のみ。
- 同梱モデルは `digital-art-4x` のみ。
- fetchurl の hash は以下を verbatim で使用:
  - `resources/linux/bin/upscayl-bin` → `sha256-p6rR2DHREwdiEBvjy6jO/izrLR0BDM5Nh2z8AiIm2rQ=`
  - `resources/models/digital-art-4x.bin` → `sha256-/gHCac/RDN744BirZuvnUM95x69NH5wWxzfhKVIpusw=`
  - `resources/models/digital-art-4x.param` → `sha256-K4+24K5NLYVwTKCMEZovXqQK3U8uzVEut/TNRLYSftQ=`
- 不足ライブラリは `vulkan-loader`（`libvulkan.so.1`）と `stdenv.cc.cc.lib`（`libgomp.so.1`）の2つ。
- GPU ICD は実行時ホストパス `/run/opengl-driver/lib` を wrapper の `LD_LIBRARY_PATH` で供給（ビルド成果物には含めない）。
- 登録先は `home.packages`（ユーザースコープ）。既存の `home-manager/desktop/*` 流儀に従う。

---

## File Structure

- `home-manager/desktop/upscayl/pkg.nix`（新規）— `upscayl-cli` 派生の定義（callPackage 形式）。単体でビルド・検証可能。
- `home-manager/desktop/upscayl/default.nix`（新規）— home-manager モジュール。`pkg.nix` を `callPackage` して `home.packages` に追加。
- `home-manager/desktop/default.nix`（変更）— `imports` に `./upscayl` を追加。

---

## Task 1: upscayl-cli 派生（pkg.nix）

**Files:**

- Create: `home-manager/desktop/upscayl/pkg.nix`
- Test: 単体ビルド（flake の nixpkgs を使った `nix build --expr`）+ 生成バイナリの実行

**Interfaces:**

- Produces: `pkg.nix` は callPackage 形式の関数。引数 `{ stdenv, fetchurl, autoPatchelfHook, makeWrapper, vulkan-loader }` を取り、`$out/bin/upscayl-cli` を持つ派生を返す。Task 2 が `pkgs.callPackage ./pkg.nix { }` で消費する。

- [ ] **Step 1: pkg.nix を作成**

`home-manager/desktop/upscayl/pkg.nix`:

```nix
{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  vulkan-loader,
}:
let
  version = "2.15.1";
  base = "https://raw.githubusercontent.com/upscayl/upscayl/v${version}";

  upscaylBin = fetchurl {
    url = "${base}/resources/linux/bin/upscayl-bin";
    hash = "sha256-p6rR2DHREwdiEBvjy6jO/izrLR0BDM5Nh2z8AiIm2rQ=";
  };
  modelBin = fetchurl {
    url = "${base}/resources/models/digital-art-4x.bin";
    hash = "sha256-/gHCac/RDN744BirZuvnUM95x69NH5wWxzfhKVIpusw=";
  };
  modelParam = fetchurl {
    url = "${base}/resources/models/digital-art-4x.param";
    hash = "sha256-K4+24K5NLYVwTKCMEZovXqQK3U8uzVEut/TNRLYSftQ=";
  };
in
stdenv.mkDerivation {
  pname = "upscayl-cli";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  # libvulkan.so.1 と libgomp.so.1(=stdenv.cc.cc.lib) を rpath に注入
  buildInputs = [
    vulkan-loader
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${upscaylBin} $out/libexec/upscayl-bin
    install -Dm644 ${modelBin} $out/share/upscayl/models/digital-art-4x.bin
    install -Dm644 ${modelParam} $out/share/upscayl/models/digital-art-4x.param

    # GPU ICD(NVIDIA/mesa)は実行時ホストパスから、モデルと既定モデル名は焼き込み
    makeWrapper $out/libexec/upscayl-bin $out/bin/upscayl-cli \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib \
      --add-flags "-m $out/share/upscayl/models" \
      --add-flags "-n digital-art-4x"

    runHook postInstall
  '';

  meta = {
    description = "Upscayl inference CLI (Real-ESRGAN ncnn-vulkan) without the Electron UI";
    platforms = [ "x86_64-linux" ];
  };
}
```

- [ ] **Step 2: 派生を単体ビルドして成功を確認**

リポジトリルート（`~/ghq/github.com/mkiin/dotfiles`）で実行:

```bash
nix build --no-link --print-out-paths --impure --expr \
  'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux; in pkgs.callPackage ./home-manager/desktop/upscayl/pkg.nix { }'
```

Expected: ビルド成功し、`/nix/store/...-upscayl-cli-2.15.1` の store path が1行出力される。
`autoPatchelfHook` が未解決ライブラリを検出した場合はここで FAIL する（`libvulkan`/`libgomp` 以外の不足があれば検知）。

- [ ] **Step 3: 生成された upscayl-cli を実画像で実行（E2E 検証）**

Step 2 が出力した store path を `$OUT` として、既知の PNG（upscayl 同梱アイコン）で実行:

```bash
OUT=$(nix build --no-link --print-out-paths --impure --expr \
  'let f = builtins.getFlake (toString ./.); pkgs = f.inputs.nixpkgs.legacyPackages.x86_64-linux; in pkgs.callPackage ./home-manager/desktop/upscayl/pkg.nix { }')
$OUT/bin/upscayl-cli \
  -i ~/ghq/github.com/upscayl/upscayl/resources/icons/128x128.png \
  -o /tmp/upscayl-e2e.png
ls -la /tmp/upscayl-e2e.png
```

Expected:

- 標準エラーに GPU 名（例 `[0 NVIDIA GeForce RTX 5070 Ti]`）と `🙌 Upscayled Successfully!` が出る。
- `/tmp/upscayl-e2e.png` が生成される（128x128 → 512x512、数百 KB）。
- `-m` / `-n` を指定していないのに成功する＝ wrapper の焼き込みが効いている。

- [ ] **Step 4: コミット**

```bash
cd ~/ghq/github.com/mkiin/dotfiles
git add home-manager/desktop/upscayl/pkg.nix
git commit -m "feat(upscayl): CLI 派生(fetchurl+autoPatchelf+makeWrapper)を追加"
```

Note: pre-commit の treefmt フックが nix を整形して初回 commit が FAIL する場合は、`git add` し直して同じ `git commit` を再実行する（整形反映のため）。

---

## Task 2: home-manager モジュール登録と設定反映

**Files:**

- Create: `home-manager/desktop/upscayl/default.nix`
- Modify: `home-manager/desktop/default.nix`（`imports` に `./upscayl` を1行追加）
- Test: `nix run .#build`（設定全体ビルド）+ `nix run .#switch`（適用）後の PATH 上での実行

**Interfaces:**

- Consumes: Task 1 の `./pkg.nix`（callPackage 形式）。

- [ ] **Step 1: home-manager モジュール default.nix を作成**

`home-manager/desktop/upscayl/default.nix`:

```nix
{ pkgs, ... }:
{
  home.packages = [
    (pkgs.callPackage ./pkg.nix { })
  ];
}
```

- [ ] **Step 2: desktop/default.nix の imports に ./upscayl を追加**

`home-manager/desktop/default.nix` の `imports` リストに `./upscayl` を追加する。
`./vesktop` の直後に1行加える:

```nix
    ./zen
    ./vesktop
    ./upscayl
  ];
```

- [ ] **Step 3: 設定全体をビルドして成功を確認**

リポジトリルートで実行:

```bash
nix run .#build
```

Expected: `Build successful! Run 'nix run .#switch' to apply.` が表示され、エラーなく完了する。
（`upscayl-cli` 派生は Task 1 で store にキャッシュ済みのため再取得・再ビルドは発生しない。）

- [ ] **Step 4: コミット**

```bash
cd ~/ghq/github.com/mkiin/dotfiles
git add home-manager/desktop/upscayl/default.nix home-manager/desktop/default.nix
git commit -m "feat(upscayl): home.packages に upscayl-cli を登録"
```

Note: treefmt フックで初回 commit が FAIL したら `git add` し直して同じ `git commit` を再実行。

- [ ] **Step 5: 設定を適用（switch）**

```bash
nix run .#switch
```

Expected: `Done!` が表示され、`nixos-rebuild switch` が成功する。

- [ ] **Step 6: PATH 上の upscayl-cli で最終確認**

新しいシェル、または `hash -r` 後に実行:

```bash
which upscayl-cli
upscayl-cli -i ~/ghq/github.com/upscayl/upscayl/resources/icons/128x128.png -o /tmp/upscayl-switch-test.png
ls -la /tmp/upscayl-switch-test.png
```

Expected: `upscayl-cli` が `~/.nix-profile/bin/upscayl-cli` 等に解決し、`🙌 Upscayled Successfully!` とともに出力画像が生成される。

---

## 完了条件

- `upscayl-cli -i <入力> -o <出力>` だけで（`-m`/`-n` 指定なしに）digital-art-4x での GPU アップスケールが動く。
- 変更が dotfiles にコミットされ、`nix run .#switch` で宣言的に再現できる。
- 日常運用（バージョン据え置き時）の再ビルド・再取得コストがゼロ。
