# upscayl-cli home-manager モジュール 設計

## 目的

Upscayl の推論バイナリ（Real-ESRGAN ncnn-vulkan）を、Electron UI 無しの
CLI ツール `upscayl-cli` として home-manager でユーザースコープに宣言的導入する。
主用途はアニメ壁紙のアップスケール。

## 背景 / 決定事項

- Upscayl の実処理は同梱バイナリ `upscayl-bin` が担い、Electron は UI 層に過ぎない。
  UI 不要のため Electron は導入しない（NixOS での共有ライブラリ対応も不要になる）。
- `upscayl-bin` は FHS 前提のプリビルド ELF。NixOS で動かすには不足ライブラリの供給が必要。
  実測で不足は **`libvulkan.so.1`（`vulkan-loader`）と `libgomp.so.1`（`stdenv.cc.cc.lib`）の2つのみ**。
  GPU ICD（NVIDIA/mesa）は実行時ホストパス `/run/opengl-driver/lib` を利用する。
- 動作検証済み: NVIDIA RTX 5070 Ti を認識し 128x128→512x512 のアップスケールに成功。

### 確定した設計判断

| 項目           | 決定                                                                             |
| -------------- | -------------------------------------------------------------------------------- |
| 配布方式       | dotfiles 内 home-manager モジュール（fork なし）。`goclipboard` と同型           |
| バイナリ入手元 | プリビルド `upscayl-bin` を `autoPatchelfHook` で Nix 化                         |
| 取得方法       | `fetchurl` で必要ファイルのみ個別取得（`fetchFromGitHub` の全ツリー233MBを回避） |
| 同梱モデル     | `digital-art-4x` のみ（アニメ壁紙用途）                                          |
| バージョン pin | タグ `v2.15.1`                                                                   |
| ラッパー既定   | モデルディレクトリと既定モデル名を焼き込み、`-i`/`-o` だけで実行可能に           |

## アーキテクチャ

新規ファイル1枚 + import 1行追加で完結する。

```
home-manager/desktop/upscayl/default.nix   （新規）
home-manager/desktop/default.nix           （imports に ./upscayl を追加）
```

### 派生（derivation）の構成

`pkgs.stdenv.mkDerivation` で以下を組む。

- **ソース取得（fetchurl × 3、v2.15.1 固定）**
  - `resources/linux/bin/upscayl-bin`（約12MB）
  - `resources/models/digital-art-4x.bin`（約8.9MB）
  - `resources/models/digital-art-4x.param`（約30KB）
  - URL 形式: `https://raw.githubusercontent.com/upscayl/upscayl/v2.15.1/<path>`
  - 各 `hash` は実装時に `nix-prefetch-url` で取得して固定。
- **`nativeBuildInputs`**: `autoPatchelfHook`, `makeWrapper`
- **`buildInputs`**: `vulkan-loader`, `stdenv.cc.cc.lib`
  （`libvulkan.so.1` / `libgomp.so.1` を rpath に注入。autoPatchelf が自動解決）
- **installPhase**
  - `upscayl-bin` → `$out/libexec/upscayl-bin`（autoPatchelf 対象）
  - モデル2ファイル → `$out/share/upscayl/models/`
  - `makeWrapper $out/libexec/upscayl-bin $out/bin/upscayl-cli` に以下を付与:
    - `--prefix LD_LIBRARY_PATH : /run/opengl-driver/lib`
      （Vulkan ICD=GPU ドライバは実行時ホストパス。NixOS の標準的な扱い）
    - `--add-flags "-m $out/share/upscayl/models"`（モデルディレクトリ既定化）
    - `--add-flags "-n digital-art-4x"`（既定モデル。`upscayl-bin` の既定名は存在しないため必須）

### home.packages への登録

`goclipboard` と同じく、モジュール内で派生を定義し `home.packages` に追加する。

## データフロー / 利用体験

```
upscayl-cli -i input.png -o output.png            # 既定 digital-art-4x, 4x
upscayl-cli -i input.png -o output.png -s 2        # 倍率変更
upscayl-cli -i indir/ -o outdir/                   # ディレクトリ一括
```

`-m` / `-n` はラッパーが既定を渡すため通常は不要。明示指定すれば上書きも可能。

## エラーハンドリング / 留意点

- **GPU ICD への依存**: `/run/opengl-driver/lib` はビルド成果物に含めず実行時に解決する
  （純粋性を保ちつつ NixOS のドライバを使う定石）。GPU が無い環境では
  `upscayl-bin` が CPU（llvmpipe）にフォールバックする。
- **autoPatchelf の検証**: ビルド時に未解決ライブラリがあれば autoPatchelfHook が
  ビルドを失敗させる。`libvulkan`/`libgomp` 以外の不足が出た場合はここで検知できる。
- **バージョン更新**: `rev`（タグ）と 3 つの `hash` を差し替えるだけ。
  それ以外の日常運用（`home-manager switch`）では再取得・再ビルドは発生しない。

## コスト見積り

- 初回のみ: 約20MB のダウンロード + autoPatchelf 数秒（コンパイル無し）。
- 以降: nix ストアに FOD キャッシュされ、バージョンを上げるまでコストゼロ。

## スコープ外

- Electron GUI の NixOS 対応（今回は UI 不要のため扱わない）。
- digital-art 以外のモデル同梱（将来必要になれば `fetchurl` を追加するだけ）。
- upscayl リポジトリの fork や flake input 化。
