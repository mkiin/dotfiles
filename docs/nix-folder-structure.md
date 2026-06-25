# Nix フォルダ構成

このリポジトリでは、Home Manager の共通設定、OS 系統の差分、実環境ごとの entry point を分けて管理する。

`homeConfigurations` の名前は、OS 種別ではなく適用対象の構成名として扱う。
そのため `cachyos` と `wsl` は続投する。
`linux` は flake output 名ではなく、Linux デスクトップ向けの共有 module 名として使う。

```text
nix/
  home/
    default.nix
    packages.nix
    programs/
      zsh.nix
      git.nix
      mise.nix
      neovim.nix
      yazi.nix

  linux/
    default.nix
    programs/
      wezterm.nix
      ghostty.nix

  darwin/
    default.nix

  hosts/
    cachyos/
      default.nix
    wsl/
      default.nix
```

## 各ディレクトリの責務

**`nix/home/`**：全環境で共有する Home Manager 設定を置く。
zsh、Git、mise、Neovim、Yazi など、CachyOS と WSL の両方に入れたいものをここで管理する。

**`nix/linux/`**：Linux デスクトップ固有の設定を置く。
Wayland やターミナルエミュレータなど、WSL には不要なものをここに寄せる。
GPU や Wayland への依存が強い GUI アプリ本体は CachyOS native package manager に寄せ、Home Manager は設定ファイル配布を担当する。
WezTerm はこの方針に従い、本体は Nix で入れず、`wezterm.lua` だけを配る。

**`nix/darwin/`**：将来 macOS を追加するときの受け皿として置く。
現時点では空に近い module に留める。

**`nix/hosts/`**：実際に `home-manager switch --flake` で指定する構成の入口を置く。
host は必要な共有層を import し、host 固有の差分だけを持つ。

## host の組み立て方

`cachyos` は共通設定と Linux デスクトップ設定を import する。

```nix
{ nixRoot, ... }:

{
  imports = [
    (nixRoot + /home)
    (nixRoot + /linux)
  ];
}
```

`wsl` は共通設定だけを import し、Windows 連携のような WSL 固有差分を host 側に書く。

```nix
{ nixRoot, ... }:

{
  imports = [
    (nixRoot + /home)
  ];

  programs.zsh.shellAliases.open = "explorer.exe .";
}
```

## 相対パスの扱い

host 側では `../../home` のような遡る相対パスを書かない。
`flake.nix` から `nixRoot = ./nix` を `extraSpecialArgs` で渡し、host 側では `(nixRoot + /home)` の形で import する。

これにより、host の階層が変わっても import 先の意味が崩れにくくなる。

## `modules/` を今は作らない理由

現時点の `git.nix`、`zsh.nix`、`mise.nix` は再利用可能な汎用 module ではなく、この dotfiles の Home Manager 設定である。
そのため `nix/modules/home/` ではなく `nix/home/` に置く。

将来、独自 option を持つ再利用可能な Home Manager module を作る段階になったら、`nix/modules/` を追加する。
