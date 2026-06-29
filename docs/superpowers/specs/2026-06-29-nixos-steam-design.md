# NixOS Steam 宣言的追加 設計

## 目的

NVIDIA GPU 搭載デスクトップ（`hosts/nixos`）で Steam を宣言的に有効化する。

## アーキテクチャ

既存の機能別ディレクトリモジュールパターン（例: `nixos/desktop/vesktop`）に従う。

### 新規ファイル: `nixos/desktop/steam/default.nix`

```nix
{ ... }:
{
  programs.steam.enable = true;
}
```

### 変更ファイル: `nixos/desktop/default.nix`

`imports` に `./steam` を 1 行追加する。

## 設計判断

`vesktop` のような単純な `environment.systemPackages` への追加ではなく、NixOS の
`programs.steam` モジュールを使う。Steam はマルチアーキテクチャ（32bit）ライブラリと
FHS 互換ランタイム環境を必要とし、このモジュールがそれらの構成を自動で行うため。

## 前提（すべて充足済み・変更不要）

- `lib/default.nix`: `nixpkgs.config.allowUnfree = true`（Steam は unfree パッケージ）
- `nixos/hardware/default.nix`: `hardware.graphics.enable = true` および
  `hardware.graphics.enable32Bit = true`（Proton / 32bit グラフィックスライブラリに必須）
- `nixos/hardware/nvidia/default.nix`: NVIDIA ドライバ設定済み

## 検証

- `nixos-rebuild`（または既存のビルドフロー）でビルドが成功すること
- 再起動後に `steam` コマンドまたはアプリケーションメニューから起動できること

## スコープ外（YAGNI）

以下は今回含めない。必要になった時点で同モジュールへ追記可能。

- gamescope セッション（`programs.steam.gamescopeSession.enable`）
- gamemode（`programs.gamemode.enable`）
- Proton-GE（`programs.steam.extraCompatPackages`）
- Remote Play / ローカルネットワークゲーム転送のファイアウォール開放
